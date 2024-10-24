# frozen_string_literal: true

class DiscourseStaffAlias::UsersPostsLink < ActiveRecord::Base
  belongs_to :post
  belongs_to :user

  validates :user_id, presence: true, uniqueness: { scope: [:post_id] }
  validates :post_id, presence: true
end

# == Schema Information
#
# Table name: discourse_staff_alias_users_posts_links
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  post_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  idx_user_id_post_id  (user_id,post_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (post_id => posts.id)
#
