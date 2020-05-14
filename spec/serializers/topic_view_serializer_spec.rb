# frozen_string_literal: true

require 'rails_helper'

describe TopicViewSerializer do
  fab!(:user) { Fabricate(:user) }

  let!(:post) { Fabricate(:post, user_id: SiteSetting.get(:discourse_staff_alias_user_id)) }

  fab!(:moderator) { Fabricate(:moderator) }

  before do
    SiteSetting.set(:discourse_staff_alias_username, 'some_alias')
    SiteSetting.set(:discourse_staff_alias_enabled, true)
  end

  describe '#staff_alias_user' do
    it 'should not be included for anon user' do
      topic_view = TopicView.new(post.topic_id, user)
      payload = TopicViewSerializer.new(topic_view, scope: Guardian.new(user), root: false).as_json

      expect(payload[:staff_alias_user]).to eq(nil)
    end

    it 'should not be included when discourse_staff_alias_enabled is false' do
      SiteSetting.set(:discourse_staff_alias_enabled, false)

      topic_view = TopicView.new(post.topic_id, moderator)
      payload = TopicViewSerializer.new(topic_view, scope: Guardian.new(moderator), root: false).as_json

      expect(payload[:staff_alias_user]).to eq(nil)
    end

    it 'should be included for staff users' do
      topic_view = TopicView.new(post.topic_id, moderator)
      payload = TopicViewSerializer.new(topic_view, scope: Guardian.new(moderator), root: false).as_json

      staff_alias_user = payload[:staff_alias_user]

      expect(staff_alias_user[:id]).to eq(SiteSetting.discourse_staff_alias_user_id)
    end
  end
end
