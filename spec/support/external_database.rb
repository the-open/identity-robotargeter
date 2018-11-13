require 'active_record'
require_relative 'robotargeter_test_schema'

module ExternalDatabaseHelpers
  class << self
    def set_external_database_urls(database_url)
      ENV['IDENTITY_DATABASE_URL'] = database_url
      ENV['IDENTITY_READ_ONLY_DATABASE_URL'] = database_url
      ENV['ROBOTARGETER_DATABASE_URL'] = replace_db_name_in_db_url(database_url, 'identity_robotargeter_test_client_engine')
      ENV['ROBOTARGETER_READ_ONLY_DATABASE_URL'] = replace_db_name_in_db_url(database_url, 'identity_robotargeter_test_client_engine')
    end

    def replace_db_name_in_db_url(database_url, replacement_db_name)
      return database_url.split('/')[0..-2].join('/') + '/' + replacement_db_name
    end

    def setup
      ActiveRecord::Base.establish_connection ENV['ROBOTARGETER_DATABASE_URL']
      ActiveRecord::Base.connection
    rescue
      ExternalDatabaseHelpers.create_database
    ensure
      ActiveRecord::Base.establish_connection ENV['IDENTITY_DATABASE_URL']
    end

    def create_database
      puts 'Rebuilding test database for Robotargeter...'

      robotargeter_db = ENV['ROBOTARGETER_DATABASE_URL'].split('/').last
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{robotargeter_db};")
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{robotargeter_db};")
      ActiveRecord::Base.establish_connection ENV['ROBOTARGETER_DATABASE_URL']
      CreateRobotargeterTestDb.new.up
    end

    def clean
      PhoneNumber.all.destroy_all
      ListMember.all.destroy_all
      List.all.destroy_all
      Member.all.destroy_all
      MemberSubscription.all.destroy_all
      Subscription.all.destroy_all
      Contact.all.destroy_all
      ContactCampaign.all.destroy_all
      ContactResponseKey.all.destroy_all
      ContactResponse.all.destroy_all
      CustomField.all.destroy_all
      CustomFieldKey.all.destroy_all
      Search.all.destroy_all
      Action.all.destroy_all
      MemberAction.all.destroy_all
      MemberActionData.all.destroy_all
      IdentityRobotargeter::Call.all.destroy_all
      IdentityRobotargeter::Callee.all.destroy_all
      IdentityRobotargeter::Campaign.all.destroy_all
      IdentityRobotargeter::SurveyResult.all.destroy_all
      IdentityRobotargeter::Audience.all.destroy_all
      IdentityRobotargeter::Redirect.all.destroy_all
    end
  end
end
