# frozen_string_literal: true

require "rails_helper"

describe SiteSetting do
  describe "enabled site setting" do
    it "raises the right error when trying to enable without setting the alias username" do
      expect { SiteSetting.set(:staff_alias_enabled, true) }.to raise_error(
        Discourse::InvalidParameters,
        /#{I18n.t("site_settings.errors.staff_alias_username_not_set")}/,
      )
    end
  end

  describe "site setting changed discourse event" do
    it "should create the staff alias user if it has not been created" do
      expect do SiteSetting.set(:staff_alias_username, "new_username") end.to change {
        User.count
      }.by(1)

      user = User.find(SiteSetting.get(:staff_alias_user_id))

      expect(user.username).to eq("new_username")
      expect(user.moderator).to eq(true)
      expect(user.trust_level).to eq(TrustLevel.levels[:leader])
    end

    it "should update the username of the staff alias user" do
      expect do
        SiteSetting.set(:staff_alias_username, "new_username")
        SiteSetting.set(:staff_alias_username, "new_username2")
      end.to change { User.count }.by(1)

      user = User.find(SiteSetting.get(:staff_alias_user_id))

      expect(user.username).to eq("new_username2")
    end

    it "should not allow an invalid username" do
      SiteSetting.set(:min_username_length, 2)

      expect do SiteSetting.set(:staff_alias_username, "a") end.to raise_error(
        Discourse::InvalidParameters,
        /#{I18n.t("user.username.short", count: 2)}/,
      )
    end

    it "should not allow a username that has been taken" do
      expect do SiteSetting.set(:staff_alias_username, "system") end.to raise_error(
        Discourse::InvalidParameters,
        /#{I18n.t("login.not_available", suggestion: "system1")}/,
      )
    end
  end
end
