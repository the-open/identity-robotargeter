describe IdentityRobotargeter::Callee do
  context '#add_members' do
    before(:each) do
      clean_external_database

      @robotargeter_campaign = FactoryBot.create(:robotargeter_campaign)
      @member = FactoryBot.create(:member_with_mobile)
      @batch_members = Member.all
      @rows = ActiveModel::Serializer::CollectionSerializer.new(
        @batch_members,
        serializer: IdentityRobotargeter::RobotargeterMemberSyncPushSerializer,
        audience_id: 1,
        campaign_id: @robotargeter_campaign.id,
        phone_type: 'mobile'
      ).as_json
    end

    it 'has inserted the correct callees to Robotargeter' do
      IdentityRobotargeter::Callee.add_members(@rows)
      expect(@robotargeter_campaign.callees.count).to eq(1)
      expect(@robotargeter_campaign.callees.find_by_mobile_number(@member.mobile).first_name).to eq(@member.first_name) # Robotargeter allows external IDs to be text
    end

    it "doesn't insert duplicates into Robotargeter" do
      2.times do |index|
        IdentityRobotargeter::Callee.add_members(@rows)
      end
      expect(@robotargeter_campaign.callees.count).to eq(1)
      expect(@robotargeter_campaign.callees.select('distinct mobile_number').count).to eq(1)
    end
  end
end
