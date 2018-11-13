class MemberAction < ApplicationRecord
  include ReadWriteIdentity
  belongs_to :action
  belongs_to :member
end
