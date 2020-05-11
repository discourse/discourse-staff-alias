class DiscourseStaffAlias::UsersPostRevisionsLink < ActiveRecord::Base
  belongs_to :post_revision
  belongs_to :user

  validates :user_id, presence: true, uniqueness: { scope: [:post_revision_id] }
  validates :post_revision_id, presence: true
end
