describe IdentityRobotargeter::Campaign do
  context '#active' do
    before(:each) do
      clean_external_database
      2.times do
        FactoryBot.create(:robotargeter_campaign, status: 'active')
      end
      FactoryBot.create(:robotargeter_campaign, status: 'active', sync_to_identity: false)
      FactoryBot.create(:robotargeter_campaign, status: 'paused')
      FactoryBot.create(:robotargeter_campaign, status: 'inactive')
    end

    it 'returns the active campaigns' do
      expect(IdentityRobotargeter::Campaign.active.count).to eq(2)
      IdentityRobotargeter::Campaign.active.each do |campaign|
        expect(campaign).to have_attributes(status: 'active')
      end
    end
  end
end
