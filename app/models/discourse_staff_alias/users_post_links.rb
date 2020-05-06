class DiscourseStaffAlias::UsersPostLinks < ActiveRecord::Base
  belongs_to :post
  belongs_to :user

  ACTIONS = {
    "create" => 1,
    "update" => 2,
  }

  validates :user_id, presence: true, uniqueness: { scope: [:post_id, :action] }
  validates :post_id, presence: true
  validates :action, presence: true, inclusion: { in: ACTIONS.values }
end
