# frozen_string_literal: true

require "rails_helper"

describe PostSerializer do
  fab!(:moderator) do
    user = Fabricate(:moderator)
    Group.find(Group::AUTO_GROUPS[:staff]).add(user)
    user
  end

  let(:post) do
    post = Fabricate(:post, user: DiscourseStaffAlias.alias_user)

    DiscourseStaffAlias::UsersPostsLink.create!(user: moderator, post: post)

    post
  end

  fab!(:post2) { Fabricate(:post) }

  before do
    SiteSetting.set(:staff_alias_username, "some_alias")
    SiteSetting.set(:staff_alias_enabled, true)
  end

  describe "#is_staff_aliased" do
    it "should be true if post is created by staff alias user" do
      serializer = PostSerializer.new(post, scope: Guardian.new(moderator), root: false)

      payload = serializer.as_json

      expect(payload[:is_staff_aliased]).to eq(true)
    end
  end

  describe "#aliased_username" do
    it "should not be included if staff_alias_enabled is false" do
      SiteSetting.set(:staff_alias_enabled, false)

      payload = PostSerializer.new(post, scope: Guardian.new(moderator), root: false).as_json

      expect(payload[:aliased_username]).to eq(nil)
    end

    it "should not be included if post is not created by staff alias user" do
      payload = PostSerializer.new(post2, scope: Guardian.new(moderator), root: false).as_json

      expect(payload[:aliased_username]).to eq(nil)
    end

    it "should not be included for a non staff user" do
      serializer = PostSerializer.new(post, scope: Guardian.new, root: false)

      serializer.topic_view = TopicView.new(post.topic_id, moderator)
      payload = serializer.as_json

      expect(payload[:aliased_username]).to eq(nil)
    end

    it "should be included if post is created by staff alias user with topic view" do
      serializer = PostSerializer.new(post, scope: Guardian.new(moderator), root: false)

      serializer.topic_view = TopicView.new(post.topic_id, moderator)
      payload = serializer.as_json

      expect(payload[:aliased_username]).to eq(moderator.username)
    end

    it "should be included if post is created by staff alias user without topic view" do
      payload = PostSerializer.new(post, scope: Guardian.new(moderator), root: false).as_json

      expect(payload[:aliased_username]).to eq(moderator.username)
    end
  end
end
