class Action < ApplicationRecord
  include ReadWriteIdentity
  belongs_to :campaign, optional: true
  has_many :member_actions
  has_many :members, through: :member_actions
  has_many :action_keys
end
