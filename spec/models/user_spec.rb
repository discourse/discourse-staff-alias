# frozen_string_literal: true

require "rails_helper"

describe User do
  fab!(:user)
  fab!(:post)
  fab!(:group)

  fab!(:admin) do
    user = Fabricate(:admin)
    group = Group.find(Group::AUTO_GROUPS[:staff])
    group.add(user)
    user
  end

  fab!(:post_revision)

  it "does not clean up users_posts_links association on destroy" do
    link = ::DiscourseStaffAlias::UsersPostsLink.create!(user: user, post: post)

    expect(user.reload.users_posts_links).to contain_exactly(link)

    UserDestroyer.new(Discourse.system_user).destroy(user)

    expect(User.exists?(id: user.id)).to eq(false)
    expect(DiscourseStaffAlias::UsersPostsLink.exists?(user_id: user.id)).to eq(true)
  end

  it "does not clean up users_post_revisions_links association on destroy" do
    link =
      ::DiscourseStaffAlias::UsersPostRevisionsLink.create!(
        user: user,
        post_revision: post_revision,
      )

    expect(user.reload.users_post_revisions_links).to contain_exactly(link)

    UserDestroyer.new(Discourse.system_user).destroy(user)

    expect(User.exists?(id: user.id)).to eq(false)
    expect(DiscourseStaffAlias::UsersPostRevisionsLink.exists?(user_id: user.id)).to eq(true)
  end

  describe "#can_post_as_staff_alias" do
    it "should return false when user is not allowed" do
      expect(user.can_post_as_staff_alias).to eq(false)
    end

    it "should return true when user belongs to the staff group by default" do
      expect(admin.can_post_as_staff_alias).to eq(true)
    end

    it "should return true when user belongs to group that has been allowed" do
      group.add(user)
      SiteSetting.set(:staff_alias_allowed_groups, "#{Group::AUTO_GROUPS[:staff]}|#{group.id}")

      expect(user.can_post_as_staff_alias).to eq(true)
    end
  end
end
