# frozen_string_literal: true

module DiscourseStaffAlias
  class UserAlias < ActiveRecord::Base
    belongs_to :user
    belongs_to :alias_user, class_name: :User

    validates :user_id, presence: true
    validates :alias_user_id, presence: true
  end
end
