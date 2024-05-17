# frozen_string_literal: true

require "rails_helper"

describe PostAlerter do
  fab!(:user)

  fab!(:moderator) do
    user = Fabricate(:moderator)
    Group.find(Group::AUTO_GROUPS[:staff]).add(user)
    user
  end

  let(:post) do
    alias_user = DiscourseStaffAlias.alias_user

    post = Fabricate(:post, user: alias_user)

    DiscourseStaffAlias::UsersPostsLink.create!(user: moderator, post: post)

    post
  end

  before do
    SiteSetting.set(:staff_alias_username, "some_alias")
    SiteSetting.set(:staff_alias_enabled, true)
    PostActionNotifier.enable
  end

  after { PostActionNotifier.disable }

  describe "staff alias user like notification" do
    it "should create a like notification for the aliased user" do
      attrs = {
        notification_type: Notification.types[:liked],
        topic_id: post.topic_id,
        post_number: post.post_number,
      }

      expect do PostActionCreator.like(user, post) end.to change {
        DiscourseStaffAlias.alias_user.notifications.where(attrs).count
      }.by(1).and change { moderator.notifications.where(attrs).count }.by(1)
    end
  end
end
