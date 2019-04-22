# This patch allows accessing the settings hash with dot notation
class Hash
  def method_missing(method, *opts)
    m = method.to_s
    return self[m] if key?(m)
    super
  end
end

class Settings
  def self.robotargeter
    return {
      "database_url" => ENV['ROBOTARGETER_DATABASE_URL'],
      "read_only_database_url" => ENV['ROBOTARGETER_DATABASE_URL'],
      "push_batch_amount" => nil,
      "pull_batch_amount" => nil,
    }
  end

  def self.gdpr
    return {
      "disable_auto_subscribe" => false
    }
  end

  def self.options
    return {
      "default_phone_country_code" => '61',
      "ignore_name_change_for_donation" => true
    }
  end
end
