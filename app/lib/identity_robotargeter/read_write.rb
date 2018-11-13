module IdentityRobotargeter
  module ReadWrite
    def self.included(mod)
      mod.establish_connection Settings.robotargeter.database_url if Settings.robotargeter.database_url
    end
  end
end