module IdentityRobotargeter
  class Caller < ApplicationRecord
    include ReadOnly
    self.table_name = "callers"
    has_many :calls
  end
end