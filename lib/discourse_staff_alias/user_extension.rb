# frozen_string_literal: true

module DiscourseStaffAlias
  module UserExtension
    extend ActiveSupport::Concern

    prepended do
      attr_accessor :aliased_user

      has_many :users_posts_links, class_name: "DiscourseStaffAlias::UsersPostsLink"
      has_many :users_post_revisions_links,
               class_name: "DiscourseStaffAlias::UsersPostRevisionsLink"
    end

    def can_post_as_staff_alias
      @can_post_as_staff_alias ||=
        begin
          allowed_group_ids = SiteSetting.staff_alias_allowed_groups.split("|")
          GroupUser.exists?(user_id: self.id, group_id: allowed_group_ids)
        end
    end
  end
end
