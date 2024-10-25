# frozen_string_literal: true

class DiscourseStaffAlias::UsersPostRevisionsLink < ActiveRecord::Base
  belongs_to :post_revision
  belongs_to :user

  validates :user_id, presence: true, uniqueness: { scope: [:post_revision_id] }
  validates :post_revision_id, presence: true
end

# == Schema Information
#
# Table name: discourse_staff_alias_users_post_revisions_links
#
#  id               :bigint           not null, primary key
#  user_id          :bigint           not null
#  post_revision_id :bigint           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  idx_user_id_post_revision_id  (user_id,post_revision_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (post_revision_id => post_revisions.id)
#
