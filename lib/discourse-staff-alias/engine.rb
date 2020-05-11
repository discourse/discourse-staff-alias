# frozen_string_literal: true

module DiscourseStaffAlias
  class Engine < ::Rails::Engine
    engine_name "DiscourseStaffAlias".freeze
    isolate_namespace DiscourseStaffAlias

    config.after_initialize do
      Discourse::Application.routes.append do
        mount ::DiscourseStaffAlias::Engine, at: "/discourse-staff-alias"
      end
    end
  end

  REPLIED_AS_ALIAS = 'discourse_staff_alias_replied_as_alias'

  def self.enabled?
    SiteSetting.discourse_staff_alias_enabled
  end

  def self.alias_user
    @alias_user ||= User.find_by(id: SiteSetting.discourse_staff_alias_user_id)
  end
end
