# frozen_string_literal: true

require 'rails_helper'

describe PostSerializer do
  fab!(:user) { Fabricate(:user) }

  let(:post) do
    post = Fabricate(:post, user: DiscourseStaffAlias.alias_user)
    post.custom_fields[DiscourseStaffAlias::REPLIED_AS_ALIAS] = true
    post.save_custom_fields

    DiscourseStaffAlias::UsersPostsLink.create!(
      user: user,
      post: post,
    )

    post
  end

  fab!(:post2) { Fabricate(:post) }

  before do
    SiteSetting.set(:discourse_staff_alias_username, 'some_alias')
    SiteSetting.set(:discourse_staff_alias_enabled, true)
  end

  describe '#staff_alias_username' do
    it 'should not be included if discourse_staff_alias_enabled is false' do
      SiteSetting.set(:discourse_staff_alias_enabled, false)

      payload = PostSerializer.new(post,
        scope: Guardian.new(post.user),
        root: false
      ).as_json

      expect(payload[:staff_alias_username]).to eq(nil)
    end

    it 'should not be included if post is not created by staff alias user' do
      payload = PostSerializer.new(post2,
        scope: Guardian.new(user),
        root: false
      ).as_json

      expect(payload[:staff_alias_username]).to eq(nil)
    end

    it 'should be included if post is created by staff alias user with topic view' do
      serializer = PostSerializer.new(post,
        scope: Guardian.new(user),
        root: false
      )

      serializer.topic_view = TopicView.new(post.topic_id, user)
      payload = serializer.as_json

      expect(payload[:staff_alias_username]).to eq(user.username)
    end

    it 'should be included if post is created by staff alias user without topic view' do
      payload = PostSerializer.new(post,
        scope: Guardian.new(user),
        root: false
      ).as_json

      expect(payload[:staff_alias_username]).to eq(user.username)
    end
  end
end
