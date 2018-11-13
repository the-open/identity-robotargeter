module IdentityRobotargeter
  module ApplicationHelper
    def self.integer_or_nil(string)
      Integer(string || '')
    rescue ArgumentError
      nil
    end

    def self.campaigns_for_select
      IdentityRobotargeter::Campaign.all.order("id DESC").map { |x| ["#{x.id}: #{x.name}", x.id] }
    end
  end
end
