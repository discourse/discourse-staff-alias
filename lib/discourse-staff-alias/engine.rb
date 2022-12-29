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

  CONTROLLER_PARAMS = { "create" => [:as_staff_alias], "update" => %i[post as_staff_alias] }

  CONTROLLER_ACTIONS = %w[create update]

  def self.enabled?
    SiteSetting.staff_alias_enabled
  end

  def self.user_allowed?(user)
    return false if user.blank?
    user.can_post_as_staff_alias
  end

  def self.alias_user
    User.find_by(id: SiteSetting.staff_alias_user_id)
  end
end
