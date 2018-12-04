module IdentityRobotargeter
  class RobotargeterMemberSyncPushSerializer < ActiveModel::Serializer
    attributes :external_id, :first_name, :mobile_number, :campaign_id, :audience_id, :data, :callable

    def external_id
      @object.id
    end

    def first_name
      @object.first_name ? @object.first_name : ''
    end

    def mobile_number
      phone_scope = instance_options[:phone_type] == 'all' ? 'phone' : instance_options[:phone_type]
      @object.send(phone_scope)
    end

    def campaign_id
      instance_options[:campaign_id]
    end

    def audience_id
      instance_options[:audience_id]
    end

    def data
      @object.flattened_custom_fields.to_json
    end

    def callable
      true
    end
  end
end
