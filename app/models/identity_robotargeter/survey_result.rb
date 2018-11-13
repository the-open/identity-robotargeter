module IdentityRobotargeter
  class SurveyResult < ApplicationRecord
    include ReadOnly
    self.table_name = "survey_results"
    belongs_to :call
  end
end