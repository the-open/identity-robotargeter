describe IdentityRobotargeter::RobotargeterMemberSyncPushSerializer do
  context 'serialize' do
    before(:each) do
      clean_external_database

      @sync_id = 1
      @robotargeter_campaign = FactoryBot.create(:robotargeter_campaign)
      @external_system_params = JSON.generate({'campaign_id' => @robotargeter_campaign.id, priority: 2, phone_type: 'mobile'})
      @member = FactoryBot.create(:member_with_mobile_and_custom_fields)
      list = FactoryBot.create(:list)
      FactoryBot.create(:list_member, list: list, member: @member)
      FactoryBot.create(:member_with_mobile)
      FactoryBot.create(:member)
      @batch_members = Member.all.with_phone_numbers.in_batches.first
      @audience = IdentityRobotargeter::Audience.create!(sync_id: @sync_id, campaign_id: @robotargeter_campaign.id)
    end

    it 'returns valid object' do
      rows = ActiveModel::Serializer::CollectionSerializer.new(
        @batch_members,
        serializer: IdentityRobotargeter::RobotargeterMemberSyncPushSerializer,
        audience_id: @audience.id,
        campaign_id: @robotargeter_campaign.id,
        phone_type: 'mobile'
      ).as_json
      expect(rows.count).to eq(2)
      expect(rows[0][:external_id]).to eq(ListMember.first.member_id)
      expect(rows[0][:mobile_number]).to eq(@member.mobile)
      expect(rows[0][:campaign_id]).to eq(@robotargeter_campaign.id)
      expect(rows[0][:audience_id]).to eq(@audience.id)
      expect(rows[0][:data]).to eq("{\"secret\":\"me_likes\"}")
    end

    it "only returns the most recently updated phone number" do
      @member.update_phone_number('61427700500', 'mobile')
      @member.update_phone_number('61427700600', 'mobile')
      @member.update_phone_number('61427700500', 'mobile')
      @batch_members = Member.all.with_phone_numbers.in_batches.first
      rows = ActiveModel::Serializer::CollectionSerializer.new(
        @batch_members,
        serializer: IdentityRobotargeter::RobotargeterMemberSyncPushSerializer,
        audience_id: @audience.id,
        campaign_id: @robotargeter_campaign.id,
        phone_type: 'mobile'
      ).as_json
      expect(rows.first[:mobile_number]).to eq('61427700500')
    end
  end
end
