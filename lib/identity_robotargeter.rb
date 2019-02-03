require "identity_robotargeter/engine"

module IdentityRobotargeter
  SYSTEM_NAME = 'robotargeter'
  PULL_BATCH_AMOUNT = 1000
  PUSH_BATCH_AMOUNT = 1000
  SYNCING = 'campaign'
  CONTACT_TYPE = 'call'
  ACTIVE_STATUS = 'active'
  FINALISED_STATUS = 'finalised'
  FAILED_STATUS = 'failed'
  PULL_JOBS = [[:fetch_new_calls, 5.minutes], [:fetch_new_redirects, 15.minutes]]

  def self.push(sync_id, members, external_system_params)
    begin
      campaign_id = JSON.parse(external_system_params)['campaign_id'].to_i
      phone_type = JSON.parse(external_system_params)['phone_type'].to_s
      priority = ApplicationHelper.integer_or_nil(JSON.parse(external_system_params)['priority']) || 1
      campaign_name = Campaign.find(campaign_id).name
      audience = Audience.create!(sync_id: sync_id, campaign_id: campaign_id, priority: priority)
      yield members.with_phone_type(phone_type), campaign_name
    rescue => e
      audience.update_attributes!(status: FAILED_STATUS) if audience
      raise e
    end
  end

  def self.push_in_batches(sync_id, members, external_system_params)
    begin
      audience = Audience.find_by_sync_id(sync_id)
      audience.update_attributes!(status: ACTIVE_STATUS)
      campaign_id = JSON.parse(external_system_params)['campaign_id'].to_i
      phone_type = JSON.parse(external_system_params)['phone_type'].to_s
      members.in_batches(of: get_push_batch_amount).each_with_index do |batch_members, batch_index|
        rows = ActiveModel::Serializer::CollectionSerializer.new(
          batch_members,
          serializer: RobotargeterMemberSyncPushSerializer,
          audience_id: audience.id,
          campaign_id: campaign_id,
          phone_type: phone_type
        ).as_json
        write_result_count = Callee.add_members(rows)

        yield batch_index, write_result_count
      end
      audience.update_attributes!(status: FINALISED_STATUS)
    rescue => e
      audience.update_attributes!(status: FAILED_STATUS)
      raise e
    end
  end

  def self.description(external_system_params, contact_campaign_name)
    "#{SYSTEM_NAME.titleize} - #{SYNCING.titleize}: #{contact_campaign_name} ##{JSON.parse(external_system_params)['campaign_id']} (#{CONTACT_TYPE})"
  end

  def self.worker_currenly_running?(method_name)
    workers = Sidekiq::Workers.new
    workers.each do |_process_id, _thread_id, work|
      matched_process = work["payload"]["args"] = [SYSTEM_NAME, method_name]
      if matched_process
        puts ">>> #{SYSTEM_NAME.titleize} #{method_name} skipping as worker already running ..."
        return true
      end
    end
    puts ">>> #{SYSTEM_NAME.titleize} #{method_name} running ..."
    return false
  end

  def self.get_pull_batch_amount
    Settings.robotargeter.pull_batch_amount || PULL_BATCH_AMOUNT
  end

  def self.get_push_batch_amount
    Settings.robotargeter.push_batch_amount || PUSH_BATCH_AMOUNT
  end

  def self.get_pull_jobs
    defined?(PULL_JOBS) && PULL_JOBS.is_a?(Array) ? PULL_JOBS : []
  end

  def self.fetch_new_calls(force: false)
    ## Do not run method if another worker is currently processing this method
    if self.worker_currenly_running?(__method__.to_s)
      return
    end

    last_updated_at = Time.parse($redis.with { |r| r.get 'robotargeter:calls:last_updated_at' } || '1970-01-01 00:00:00')
    updated_calls = Call.updated_calls(force ? DateTime.new() : last_updated_at)

    iteration_method = force ? :find_each : :each

    updated_calls.send(iteration_method) do |call|
      self.delay(retry: false, queue: 'low').handle_new_call(call.id)
    end

    unless updated_calls.empty?
      $redis.with { |r| r.set 'robotargeter:calls:last_updated_at', updated_calls.last.updated_at }
    end

    updated_calls.size
  end

  def self.handle_new_call(call_id)
    call = Call.find(call_id)
    contact = Contact.find_or_initialize_by(external_id: call.id, system: SYSTEM_NAME)
    contactee = Member.upsert_member(
      {
        phones: [{ phone: call.callee.phone_number }],
        firstname: call.callee.first_name,
        lastname: call.callee.last_name
      },
      "#{SYSTEM_NAME}:#{__method__.to_s}"
    )

    unless contactee
      Notify.warning "Robotargeter: Contactee Insert Failed", "Contactee #{call.inspect} could not be inserted because the contactee could not be created"
      return
    end

    contact_campaign = ContactCampaign.find_or_create_by(external_id: call.callee.campaign.id, system: SYSTEM_NAME)
    contact_campaign.update_attributes!(name: call.callee.campaign.name, contact_type: CONTACT_TYPE)

    contact.update_attributes!(contactee: contactee,
                              contact_campaign: contact_campaign,
                              duration: call.duration,
                              contact_type: CONTACT_TYPE,
                              happened_at: call.created_at,
                              status: call.status)
    contact.reload

    if Settings.robotargeter.opt_out_subscription_id
      if call.callee.opted_out_at
        subscription = Subscription.find(Settings.robotargeter.opt_out_subscription_id)
        contactee.unsubscribe_from(subscription, 'robotargeter:disposition')
      end
    end

    if Campaign.connection.tables.include?('survey_results')
      call.survey_results.each do |sr|
        contact_response_key = ContactResponseKey.find_or_create_by(key: sr.question, contact_campaign: contact_campaign)
        ContactResponse.find_or_create_by(contact: contact, value: sr.answer, contact_response_key: contact_response_key)
      end
    end
  end

  def self.fetch_new_redirects
    ## Do not run method if another worker is currently processing this method
    return if self.worker_currenly_running?(__method__.to_s)

    last_created_at = Time.parse($redis.with { |r| r.get 'robotargeter:redirects:last_created_at' } || '1970-01-01 00:00:00')
    updated_redirects = Redirect.updated_redirects(last_created_at)

    updated_redirects.each do |redirect|
      self.delay(retry: false, queue: 'low').handle_new_redirect(redirect.id)
    end

    unless updated_redirects.empty?
      $redis.with { |r| r.set 'robotargeter:redirects:last_created_at', updated_redirects.last.created_at }
    end

    updated_redirects.size
  end

  def self.handle_new_redirect(redirect_id)
    redirect = Redirect.find(redirect_id)

    payload = {
      cons_hash: { phones: [{ phone: redirect.callee.phone_number }], firstname: redirect.callee.first_name, lastname: redirect.callee.last_name },
      action_name: redirect.campaign.name,
      action_type: CONTACT_TYPE,
      action_technical_type: 'robotargeter_redirect',
      external_id: redirect.campaign.id,
      create_dt: redirect.created_at
    }

    Member.record_action(payload, "#{SYSTEM_NAME}:#{__method__.to_s}")
  end
end
