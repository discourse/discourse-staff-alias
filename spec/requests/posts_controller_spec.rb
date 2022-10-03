# frozen_string_literal: true

require 'rails_helper'

describe PostsController do
  fab!(:user) { Fabricate(:user) }

  fab!(:moderator) do
    user = Fabricate(:moderator)
    Group.find(Group::AUTO_GROUPS[:staff]).add(user)
    user
  end

  fab!(:post_1) { Fabricate(:post, user: moderator) }

  before do
    SiteSetting.set(:staff_alias_username, 'some_alias')
    SiteSetting.set(:staff_alias_enabled, true)
  end

  describe '#create' do
    it 'returns the right response when an invalid user is trying to post as alias user' do
      sign_in(user)

      post "/posts.json", params: {
        raw: 'this is a post',
        topic_id: post_1.topic_id,
        reply_to_post_number: 1,
        as_staff_alias: true
      }

      expect(response.status).to eq(403)
    end

    it 'does not allow a whisper to be posted as an alias user' do
      sign_in(moderator)
      alias_user = DiscourseStaffAlias.alias_user

      expect do
        post "/posts.json", params: {
          raw: 'this is a post',
          topic_id: post_1.topic_id,
          reply_to_post_number: 1,
          as_staff_alias: true,
          whisper: "true"
        }

        expect(response.status).to eq(403)
      end.to_not change { alias_user.posts.count }
    end

    it 'does not create links for normal posts' do
      sign_in(moderator)

      expect do
        post "/posts.json", params: {
          raw: 'this is a post',
          topic_id: post_1.topic_id,
          reply_to_post_number: 1,
        }

        expect(response.status).to eq(200)
      end.to change { moderator.posts.count }.by(1)

      expect(DiscourseStaffAlias::UsersPostsLink.count).to eq(0)

      post = moderator.posts.last

      expect(post.custom_fields).to eq({})
    end

    it 'advances the draft sequence for the staff user' do
      sign_in(moderator)
      Draft.set(moderator, post_1.topic.draft_key, 0, 'test')
      alias_user = DiscourseStaffAlias.alias_user

      expect do
        post "/posts.json", params: {
          raw: 'this is a post',
          topic_id: post_1.topic_id,
          reply_to_post_number: 1,
          draft_key: post_1.topic.draft_key,
          as_staff_alias: true
        }

        expect(response.status).to eq(200)
      end.to change { alias_user.posts.count }.by(1)
        .and change { Draft.where(user_id: moderator.id).count }.by(-1)
        .and change { DraftSequence.exists?(user_id: moderator.id, draft_key: post_1.topic.draft_key) }.from(false).to(true)
    end

    it 'allows a staff user to post as alias user' do
      sign_in(moderator)
      alias_user = DiscourseStaffAlias.alias_user

      expect do
        post "/posts.json", params: {
          raw: 'this is a post',
          topic_id: post_1.topic_id,
          reply_to_post_number: 1,
          as_staff_alias: true
        }

        expect(response.status).to eq(200)
        expect(response.parsed_body["aliased_username"]).to eq(moderator.username)
      end.to change { alias_user.posts.count }.by(1)

      post = alias_user.posts.last

      expect(post.raw).to eq('this is a post')
      expect(post.topic_id).to eq(post_1.topic_id)

      expect(DiscourseStaffAlias::UsersPostsLink.exists?(
        user_id: moderator.id,
        post_id: post.id,
      )).to eq(true)

      expect(TopicUser.get(post.topic, moderator).notification_level)
        .to eq(TopicUser.notification_levels[:watching])
    end
  end

  describe '#update' do
    it 'does not create links for normal edits' do
      sign_in(moderator)

      expect do
        put "/posts/#{post_1.id}.json", params: {
          post: {
            raw: 'new raw body',
            edit_reason: 'typo',
          },
        }
      end.to change { post_1.revisions.count }.by(1)

      expect(DiscourseStaffAlias::UsersPostRevisionsLink.count).to eq(0)
    end

    it 'does not allow a whisper to be edited as an alias user' do
      sign_in(moderator)
      alias_user = DiscourseStaffAlias.alias_user
      post_1.update!(post_type: Post.types[:whisper])

      expect do
        put "/posts/#{post_1.id}.json", params: {
          post: {
            raw: 'new raw body',
            edit_reason: 'typo',
            as_staff_alias: true
          },
        }

        expect(response.status).to eq(422)

        expect(response.parsed_body["errors"].first).to eq(
          I18n.t("post_revisions.errors.cannot_edit_whisper_as_staff_alias")
        )
      end.not_to change { post_1.post_revisions.count }
    end

    it 'does not allow a post by the alias user to be edited as staff user' do
      sign_in(moderator)

      post "/posts.json", params: {
        raw: 'this is a post',
        topic_id: post_1.topic_id,
        reply_to_post_number: 1,
        as_staff_alias: true
      }

      post_2 = Post.last

      expect do
        put "/posts/#{post_2.id}.json", params: {
          post: {
            raw: 'new raw body',
            edit_reason: 'typo'
          },
        }

        expect(response.status).to eq(422)

        expect(response.parsed_body["errors"].first).to eq(
          I18n.t("post_revisions.errors.cannot_edit_aliased_post_as_staff")
        )
      end.not_to change { post_1.post_revisions.count }
    end

    it 'advances the draft sequence for the staff user' do
      sign_in(moderator)

      post "/posts.json", params: {
        raw: 'this is a post',
        topic_id: post_1.topic_id,
        reply_to_post_number: 1,
        as_staff_alias: true
      }

      post_2 = Post.last
      Draft.set(moderator, post_1.topic.draft_key, 1, 'test')

      expect do
        put "/posts/#{post_2.id}.json", params: {
          post: {
            raw: 'new raw body',
            edit_reason: 'typo',
            as_staff_alias: true
          },
        }

        expect(response.status).to eq(200)
      end.to change { post_2.revisions.count }.by(1)
        .and change { Draft.where(user_id: moderator.id).count }.by(-1)
        .and change { DraftSequence.current(moderator, post_1.topic.draft_key) }.from(1).to(2)
    end

    it 'allows staff user to edit normal posts as alias user' do
      sign_in(moderator)

      expect do
        put "/posts/#{post_1.id}.json", params: {
          post: {
            raw: 'new raw body',
            edit_reason: 'typo',
            as_staff_alias: true
          }
        }

        expect(response.status).to eq(200)
      end.to change { post_1.revisions.count }.by(1)

      post_1.reload

      expect(post_1.raw).to eq('new raw body')

      revision = post_1.revisions.last

      expect(revision.user_id).to eq(DiscourseStaffAlias.alias_user.id)

      expect(DiscourseStaffAlias::UsersPostRevisionsLink.exists?(
        user_id: moderator.id,
        post_revision_id: revision.id,
      )).to eq(true)
    end

    it 'allows a staff user to edit alised posts as alias user' do
      sign_in(moderator)

      post "/posts.json", params: {
        raw: 'this is a post',
        topic_id: post_1.topic_id,
        reply_to_post_number: 1,
        as_staff_alias: true
      }

      post_2 = Post.last

      expect do
        put "/posts/#{post_2.id}.json", params: {
          post: {
            raw: 'new raw body',
            edit_reason: 'typo',
            as_staff_alias: true
          },
        }
      end.to change { post_2.revisions.count }.by(1)

      post_2.reload

      expect(post_2.raw).to eq('new raw body')

      revision = post_2.revisions.last

      expect(revision.user_id).to eq(DiscourseStaffAlias.alias_user.id)

      expect(DiscourseStaffAlias::UsersPostRevisionsLink.exists?(
        user_id: moderator.id,
        post_revision_id: revision.id,
      )).to eq(true)
    end
  end

  describe '#wiki' do
    it 'allows users in staff aliased allowed group to update wiki status of post made by staff alias user' do
      sign_in(moderator)

      post "/posts.json", params: {
        raw: 'this is a post',
        topic_id: post_1.topic_id,
        reply_to_post_number: 1,
        as_staff_alias: true
      }

      expect(response.status).to eq(200)

      new_post = Post.last

      expect(new_post.user).to eq(DiscourseStaffAlias.alias_user)

      SiteSetting.set(:editing_grace_period, 0)

      expect do
        put "/posts/#{new_post.id}/wiki.json", params: { wiki: "true" }

        expect(response.status).to eq(200)
      end.to change { PostRevision.count }.by(1)

      post_revision = PostRevision.last

      expect(post_revision.post_id).to eq(new_post.id)
      expect(post_revision.user_id).to eq(DiscourseStaffAlias.alias_user.id)
      expect(post_revision.modifications).to eq("wiki" => [false, true])
    end
  end

  describe '#post_type' do
    it 'allows users in staff aliased allowed group to update post_type of post made by staff alias user' do
      sign_in(moderator)

      post "/posts.json", params: {
        raw: 'this is a post',
        topic_id: post_1.topic_id,
        reply_to_post_number: 1,
        as_staff_alias: true
      }

      expect(response.status).to eq(200)

      new_post = Post.last

      expect(new_post.user).to eq(DiscourseStaffAlias.alias_user)

      SiteSetting.set(:editing_grace_period, 0)

      expect do
        put "/posts/#{new_post.id}/post_type.json", params: { post_type: Post.types[:moderator_action] }

        expect(response.status).to eq(200)
      end.to change { PostRevision.count }.by(1)

      post_revision = PostRevision.last

      expect(post_revision.post_id).to eq(new_post.id)
      expect(post_revision.user_id).to eq(DiscourseStaffAlias.alias_user.id)
      expect(post_revision.modifications).to eq("post_type" => [Post.types[:regular], Post.types[:moderator_action]])
    end
  end
end
