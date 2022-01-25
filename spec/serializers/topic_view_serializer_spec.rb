# frozen_string_literal: true

require 'rails_helper'

describe TopicViewSerializer do
  fab!(:user) { Fabricate(:user) }

  fab!(:admin) do
    Fabricate(:admin).tap do |user|
      Group.find(Group::AUTO_GROUPS[:staff]).add(user)
      Group.find(Group::AUTO_GROUPS[:admins]).add(user)
    end
  end

  let!(:post) { Fabricate(:post, user_id: SiteSetting.get(:staff_alias_user_id)) }

  fab!(:moderator) do
    user = Fabricate(:moderator)
    Group.find(Group::AUTO_GROUPS[:staff]).add(user)
    user
  end

  fab!(:category) { Fabricate(:category) }

  before do
    SiteSetting.set(:staff_alias_username, 'some_alias')
    SiteSetting.set(:staff_alias_enabled, true)
    SiteSetting.staff_alias_allowed_groups = "#{Group::AUTO_GROUPS[:staff]}"
  end

  describe '#details' do
    describe '#staff_alias_can_create_post' do
      it 'should be true when alias user is able to create a post in the topic' do
        topic_view = TopicView.new(post.topic_id, moderator)
        payload = TopicViewSerializer.new(topic_view, scope: Guardian.new(moderator), root: false).as_json

        expect(payload[:details][:staff_alias_can_create_post]).to eq(true)
      end

      it 'should be false when alias user is not able to create a post in the topic' do
        category.set_permissions(admins: :full)
        category.save!
        post.topic.update!(category: category)

        topic_view = TopicView.new(post.topic_id, admin)
        payload = TopicViewSerializer.new(topic_view, scope: Guardian.new(admin), root: false).as_json

        expect(payload[:details][:staff_alias_can_create_post]).to eq(false)
      end
    end
  end

  describe '#staff_alias_user' do
    it 'should not be included for anon user' do
      topic_view = TopicView.new(post.topic_id, user)
      payload = TopicViewSerializer.new(topic_view, scope: Guardian.new(user), root: false).as_json

      expect(payload[:staff_alias_user]).to eq(nil)
    end

    it 'should not be included when staff_alias_enabled is false' do
      SiteSetting.set(:staff_alias_enabled, false)

      topic_view = TopicView.new(post.topic_id, moderator)
      payload = TopicViewSerializer.new(topic_view, scope: Guardian.new(moderator), root: false).as_json

      expect(payload[:staff_alias_user]).to eq(nil)
    end

    it 'should be included for staff users' do
      topic_view = TopicView.new(post.topic_id, moderator)
      payload = TopicViewSerializer.new(topic_view, scope: Guardian.new(moderator), root: false).as_json

      staff_alias_user = payload[:staff_alias_user]

      expect(staff_alias_user[:id]).to eq(SiteSetting.staff_alias_user_id)
    end
  end
end
