# frozen_string_literal: true

require 'rails_helper'

describe PostRevisionSerializer do
  fab!(:moderator) { Fabricate(:moderator) }
  fab!(:admin) { Fabricate(:admin) }

  let(:post) do
    alias_user = DiscourseStaffAlias.alias_user

    post = Fabricate(:post, user: alias_user)

    DiscourseStaffAlias::UsersPostsLink.create!(
      user: moderator,
      post: post,
    )

    alias_user.aliased_staff_user = moderator

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

    alias_user.aliased_staff_user = moderator

    PostRevisor.new(post2).revise!(
      alias_user,
      { raw: 'this is a new piece of news' },
      force_new_version: true
    )

    post2
  end

  let(:post_revision) { post.post_revisions.last }

  before do
    SiteSetting.set(:discourse_staff_alias_username, 'some_alias')
    SiteSetting.set(:discourse_staff_alias_enabled, true)
  end

  describe '#aliased_staff_username' do
    it 'should not be included if discourse_staff_alias_enabled is false' do
      SiteSetting.set(:discourse_staff_alias_enabled, false)

      payload = PostRevisionSerializer.new(post_revision,
        scope: Guardian.new(moderator),
        root: false
      ).as_json

      expect(payload[:aliased_staff_username]).to eq(nil)
    end

    it 'should be included for a non-staff user' do
      payload = PostRevisionSerializer.new(post_revision,
        scope: Guardian.new,
        root: false
      ).as_json

      expect(payload[:aliased_staff_username]).to eq(nil)
    end

    it 'should be included if post is created by staff alias user' do
      payload = PostRevisionSerializer.new(post_revision,
        scope: Guardian.new(moderator),
        root: false
      ).as_json

      expect(payload[:aliased_staff_username]).to eq(moderator.username)
    end

    it 'should be included if post is created by a normal user' do
      payload = PostRevisionSerializer.new(post2.post_revisions.last,
        scope: Guardian.new(moderator),
        root: false
      ).as_json

      expect(payload[:aliased_staff_username]).to eq(moderator.username)
    end

    it 'should equal user delete message if aliased user has been deleted' do
      moderator.destroy!

      payload = PostRevisionSerializer.new(post2.post_revisions.last,
        scope: Guardian.new(admin),
        root: false
      ).as_json

      expect(payload[:aliased_staff_username]).to eq(I18n.t("aliased_user_deleted"))
    end
  end
end
