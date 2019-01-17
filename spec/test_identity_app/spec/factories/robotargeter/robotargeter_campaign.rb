module IdentityRobotargeter
  FactoryBot.define do
    factory :robotargeter_campaign, class: Campaign do
      name { Faker::Book.title }
      sync_to_identity { true }
      intro { {} }
    end
  end
end
