# frozen_string_literal: true

require 'rails_helper'

describe PostRevisionSerializer do
  fab!(:user) { Fabricate(:moderator) }

  let(:post) do
    alias_user = DiscourseStaffAlias.alias_user

    post = Fabricate(:post, user: alias_user)

    DiscourseStaffAlias::UsersPostsLink.create!(
      user: user,
      post: post,
    )

    alias_user.aliased_staff_user = user

    PostRevisor.new(post).revise!(
      alias_user,
      { raw: 'this is a new piece of news' },
      force_new_version: true
    )

    post
  end

  let(:post2) do
    alias_user = DiscourseStaffAlias.alias_user

    post2 = Fabricate(:post)

    DiscourseStaffAlias::UsersPostsLink.create!(
      user: post2.user,
      post: post
    )

    alias_user.aliased_staff_user = post2.user

    PostRevisor.new(post2).revise!(
      alias_user,
      { raw: 'this is a new piece of news' },
      force_new_version: true
    )

    post2
  end

  let(:post_revision) { post.post_revisions.last }

  before do
    SiteSetting.set(:staff_alias_username, 'some_alias')
    SiteSetting.set(:staff_alias_enabled, true)
  end

  describe '#is_staff_aliased' do
    it 'should be true if post revision is created by staff alias user' do
      payload = PostRevisionSerializer.new(post_revision,
        scope: Guardian.new(user),
        root: false
      ).as_json

      expect(payload[:is_staff_aliased]).to eq(true)
    end
  end

  describe '#aliased_staff_username' do
    it 'should not be included if staff_alias_enabled is false' do
      SiteSetting.set(:staff_alias_enabled, false)

      payload = PostRevisionSerializer.new(post_revision,
        scope: Guardian.new(user),
        root: false
      ).as_json

      expect(payload[:aliased_staff_username]).to eq(nil)
    end

    it 'should not be included for a non-staff user' do
      payload = PostRevisionSerializer.new(post_revision,
        scope: Guardian.new,
        root: false
      ).as_json

      expect(payload[:aliased_staff_username]).to eq(nil)
    end

    it 'should be included if post is created by staff alias user' do
      payload = PostRevisionSerializer.new(post_revision,
        scope: Guardian.new(user),
        root: false
      ).as_json

      expect(payload[:aliased_staff_username]).to eq(user.username)
    end

    it 'should be included if post is created by a normal user' do
      payload = PostRevisionSerializer.new(post2.post_revisions.last,
        scope: Guardian.new(user),
        root: false
      ).as_json

      expect(payload[:aliased_staff_username]).to eq(post2.user.username)
    end
  end
end
