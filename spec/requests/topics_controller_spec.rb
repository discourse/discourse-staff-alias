# frozen_string_literal: true

require "rails_helper"

describe PostsController do
  fab!(:group)

  fab!(:user) do
    user = Fabricate(:user, trust_level: TrustLevel.levels[:regular])
    group.add(user)
    user
  end

  fab!(:moderator) do
    user = Fabricate(:moderator)
    Group.find(Group::AUTO_GROUPS[:staff]).add(user)
    user
  end

  let(:post_1) do
    alias_user = DiscourseStaffAlias.alias_user
    post = Fabricate(:post, user: alias_user)

    DiscourseStaffAlias::UsersPostsLink.create!(user: moderator, post: post)

    post
  end

  let(:topic) { post_1.topic }

  before do
    SiteSetting.set(:staff_alias_username, "some_alias")
    SiteSetting.set(:staff_alias_enabled, true)
    SiteSetting.set(:editing_grace_period, 0)
    Group.refresh_automatic_groups!
  end

  describe "#update" do
    it "returns the right response when an invalid user is trying to post as alias user" do
      sign_in(user)

      put "/t/#{topic.slug}/#{topic.id}.json",
          params: {
            title: "brand new title",
            as_staff_alias: true,
          }

      expect(response.status).to eq(403)
    end

    it "does not create links for normal posts" do
      sign_in(moderator)

      put "/t/#{topic.slug}/#{topic.id}.json", params: { title: "brand new title" }

      expect(DiscourseStaffAlias::UsersPostRevisionsLink.count).to eq(0)
    end

    it "should revise topic title as staff alias user for a topic created by staff alias user" do
      sign_in(user)
      SiteSetting.set(:staff_alias_allowed_groups, "#{Group::AUTO_GROUPS[:staff]}|#{group.id}")

      expect do
        put "/t/#{topic.slug}/#{topic.id}.json",
            params: {
              title: "brand new title",
              as_staff_alias: true,
            }

        expect(response.status).to eq(200)
      end.to change { post_1.post_revisions.count }.by(1)

      expect(topic.reload.title).to eq("Brand new title")

      expect(
        DiscourseStaffAlias::UsersPostRevisionsLink.exists?(
          user: user,
          post_revision: post_1.post_revisions.last,
        ),
      ).to eq(true)
    end
  end
end
