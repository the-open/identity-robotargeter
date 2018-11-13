module IdentityRobotargeter
  FactoryBot.define do
    factory :robotargeter_campaign, class: Campaign do
      name { Faker::Book.title }
      intro { {} }
    end
  end
end
