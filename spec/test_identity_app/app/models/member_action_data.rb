class MemberActionData < ApplicationRecord
  self.table_name = 'member_actions_data'
  belongs_to :member_action
  belongs_to :action_key
end
