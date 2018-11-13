module IdentityRobotargeter
  class Audience < ApplicationRecord
    include ReadWrite
    self.table_name = "audiences"
    belongs_to :campaign
  end
end
