# frozen_string_literal: true

require 'rails_helper'

describe PostRevisionSerializer do
  fab!(:user) { Fabricate(:moderator) }

  let(:post) do
    alias_user = DiscourseStaffAlias.alias_user

    post = Fabricate(:post, user: alias_user)
    post.custom_fields[DiscourseStaffAlias::REPLIED_AS_ALIAS] = true
    post.save_custom_fields

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

  let(:post_revision) { post.post_revisions.last }

  before do
    SiteSetting.set(:discourse_staff_alias_username, 'some_alias')
    SiteSetting.set(:discourse_staff_alias_enabled, true)
  end

  describe '#aliased_staff_username' do
    it 'should not be included if discourse_staff_alias_enabled is false' do
      SiteSetting.set(:discourse_staff_alias_enabled, false)

      payload = PostRevisionSerializer.new(post_revision,
        scope: Guardian.new(user),
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
        scope: Guardian.new(user),
        root: false
      ).as_json

      expect(payload[:aliased_staff_username]).to eq(user.username)
    end
  end
end
