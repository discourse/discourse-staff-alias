# frozen_string_literal: true

module DiscourseStaffAlias
  module TopicsControllerExtension
    extend ActiveSupport::Concern

    prepended do
      include WithCurrentUser

      around_action do |controller, action|
        if (action_name = controller.action_name) == "update" &&
             (params = controller.params)["as_staff_alias"]
          existing_user = controller.current_user

          raise Discourse::InvalidAccess if !DiscourseStaffAlias.user_allowed?(existing_user)

          alias_user = DiscourseStaffAlias.alias_user
          alias_user.aliased_user = existing_user

          controller.with_current_user(alias_user) { action.call }
        else
          action.call
        end
      end
    end
  end
end
