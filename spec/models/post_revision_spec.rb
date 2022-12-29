# frozen_string_literal: true

require "rails_helper"

describe PostRevision do
  fab!(:user) { Fabricate(:user) }
  fab!(:post_revision) { Fabricate(:post_revision) }

  fab!(:admin) do
    user = Fabricate(:admin)
    group = Group.find(Group::AUTO_GROUPS[:staff])
    group.add(user)
    user
  end

  before do
    SiteSetting.set(:staff_alias_allowed_groups, Group::AUTO_GROUPS[:staff].to_s)
    SiteSetting.set(:staff_alias_username, "staff_alias_user")
    SiteSetting.set(:staff_alias_enabled, true)
  end

  it "does not allow users that are not in staff alias allowed group to edit posts made by staff alias user" do
    SiteSetting.set(:staff_alias_allowed_groups, "somegroupname")

    post = Fabricate(:post, user: DiscourseStaffAlias.alias_user)
    post_revision = Fabricate.build(:post_revision, post: post, user: admin)

    expect(post_revision.valid?).to eq(false)
  end

  it "cleans up users_posts_links association on destroy" do
    link =
      ::DiscourseStaffAlias::UsersPostRevisionsLink.create!(
        user: user,
        post_revision: post_revision,
      )

    expect(post_revision.reload.users_post_revisions_links).to contain_exactly(link)

    post_revision.destroy!

    expect(
      DiscourseStaffAlias::UsersPostRevisionsLink.exists?(post_revision_id: post_revision.id),
    ).to eq(false)
  end

  it "allows non human users to edit posts made by the staff alias user" do
    post = Fabricate(:post, user: DiscourseStaffAlias.alias_user)
    post_revision = Fabricate.build(:post_revision, post: post, user: Discourse.system_user)

    expect(post_revision.valid?).to eq(true)
  end

  it "switches revision user to staff alias user when changing wiki status of post made as staff alias user" do
    post = Fabricate(:post, user: DiscourseStaffAlias.alias_user, wiki: false)

    post_revision =
      Fabricate.build(
        :post_revision,
        post: post,
        user: admin,
        modifications: {
          "wiki" => [false, true],
        },
      )

    expect(post_revision.valid?).to eq(true)
    expect(post_revision.user_id).to eq(SiteSetting.get(:staff_alias_user_id))
  end

  it "switches revision user to staff alias user when changing post_type of post made as staff alias user" do
    post = Fabricate(:post, user: DiscourseStaffAlias.alias_user, post_type: Post.types[:regular])

    post_revision =
      Fabricate.build(
        :post_revision,
        post: post,
        user: admin,
        modifications: {
          "post_type" => [Post.types[:regular], Post.types[:moderator_action]],
        },
      )

    expect(post_revision.valid?).to eq(true)
    expect(post_revision.user_id).to eq(SiteSetting.get(:staff_alias_user_id))
  end
end
