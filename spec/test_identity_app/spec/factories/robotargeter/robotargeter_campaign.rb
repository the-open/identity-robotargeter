module IdentityRobotargeter
  FactoryBot.define do
    factory :robotargeter_campaign, class: Campaign do
      name { Faker::Book.title }
      sync_to_identity { true }
      intro { {} }
      questions { {} }
      factory :robotargeter_campaign_with_redirect_questions do
        questions {
          {
            vote_preference: { answers: { "2" => { value: "greens", next: "action" } } },
            action: { answers: { "2" => { value: "yes", redirect: true } } }
          }
        }
      end
    end
  end
end
