module IdentityRobotargeter
  class Campaign < ApplicationRecord
    include ReadOnly
    self.table_name = "campaigns"
    has_many :callees
    has_many :audiences
    has_many :redirects
  end
end
