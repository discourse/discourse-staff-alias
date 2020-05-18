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

  CONTROLLER_PARAMS = {
    "create" => [:as_staff_alias],
    "update" => [:post, :as_staff_alias]
  }

  CONTROLLER_ACTIONS = ["create", "update"]

  def self.enabled?
    SiteSetting.staff_alias_enabled
  end

  def self.alias_user
    User.find_by(id: SiteSetting.staff_alias_user_id)
  end
end
