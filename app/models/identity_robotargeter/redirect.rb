module IdentityRobotargeter
  class Redirect < ApplicationRecord
    include ReadOnly
    self.table_name = "redirects"
    belongs_to :callee
    belongs_to :campaign

    BATCH_AMOUNT=200

    scope :updated_redirects, -> (last_updated_at) {
      includes(:callee, :campaign)
      .where('redirects.created_at >= ?', last_updated_at)
      .order('redirects.created_at')
      .limit(BATCH_AMOUNT)
    }
  end
end
