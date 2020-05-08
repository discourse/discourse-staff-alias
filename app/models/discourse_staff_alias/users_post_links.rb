class DiscourseStaffAlias::UsersPostLinks < ActiveRecord::Base
  belongs_to :post
  belongs_to :user

  CREATE_POST_ACTION = "create"
  UPDATE_POST_ACTION = "update"

  ACTIONS = {
    CREATE_POST_ACTION => 1,
    UPDATE_POST_ACTION => 2,
  }

  validates :user_id, presence: true, uniqueness: { scope: [:post_id, :action] }
  validates :post_id, presence: true
  validates :action, presence: true, inclusion: { in: ACTIONS.values }
end
