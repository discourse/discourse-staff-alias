# frozen_string_literal: true

require "rails_helper"

describe PostRevisor do
  fab!(:user) { Fabricate(:user) }
  fab!(:post) { Fabricate(:post, user: user) }

  context "when post_edited" do
    fab!(:moderator) { Fabricate(:moderator) }
    let(:post_revisor) { PostRevisor.new(post) }

    before do
      SiteSetting.set(:staff_alias_allowed_groups, Group::AUTO_GROUPS[:staff].to_s)
      SiteSetting.set(:staff_alias_username, "staff_alias_user")
      SiteSetting.set(:staff_alias_enabled, true)
    end

    context "when it is a user_id modification" do
      it "creates a users_posts_link record when the post's ownership changes to staff_alias_user" do
        post_revisor.revise!(
          moderator,
          {
            raw: post.raw,
            user_id: DiscourseStaffAlias.alias_user.id,
            edit_reason: "Ownership transferred",
          },
          force_new_version: true,
        )

        expect(DiscourseStaffAlias::UsersPostsLink.last).to have_attributes(
          user_id: user.id,
          post_id: post.id,
        )
      end

      it "does not create a users_posts_link record when the post's ownership changes to not the staff_alias_user" do
        expect {
          post_revisor.revise!(
            moderator,
            { raw: post.raw, user_id: moderator.id, edit_reason: "Ownership transferred" },
            force_new_version: true,
          )
        }.to not_change { DiscourseStaffAlias::UsersPostsLink.count }
      end
    end
  end
end
