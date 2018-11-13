module IdentityRobotargeter
  module ReadOnly
    def self.included(mod)
      mod.establish_connection Settings.robotargeter.read_only_database_url if Settings.robotargeter.read_only_database_url
    end
  end
end