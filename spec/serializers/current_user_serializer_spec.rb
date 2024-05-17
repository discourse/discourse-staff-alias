# frozen_string_literal: true

require "rails_helper"

describe CurrentUserSerializer do
  fab!(:group)

  fab!(:user) do
    user = Fabricate(:user, trust_level: TrustLevel.levels[:regular])
    group.add(user)
    user
  end

  before do
    SiteSetting.set(:staff_alias_username, "some_alias")
    SiteSetting.set(:staff_alias_enabled, true)
  end

  describe "#can_act_as_staff_alias" do
    it "should not be included when plugin is disabled" do
      SiteSetting.set(:staff_alias_enabled, false)
      SiteSetting.set(:staff_alias_allowed_groups, "#{group.id}")

      json = CurrentUserSerializer.new(user, scope: Guardian.new(user), root: false).as_json

      expect(json[:can_act_as_staff_alias]).to eq(nil)
    end

    it "should not be included when user can not act as staff alias" do
      json = CurrentUserSerializer.new(user, scope: Guardian.new(user), root: false).as_json

      expect(json[:can_act_as_staff_alias]).to eq(nil)
    end

    it "should be true when user can act as staff alias" do
      SiteSetting.set(:staff_alias_allowed_groups, "#{group.id}")

      json = CurrentUserSerializer.new(user, scope: Guardian.new(user), root: false).as_json

      expect(json[:can_act_as_staff_alias]).to eq(true)
    end
  end
end
