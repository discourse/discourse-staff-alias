# frozen_string_literal: true

module DiscourseStaffAlias
  module PostsControllerExtension
    extend ActiveSupport::Concern

    prepended do
      include WithCurrentUser

      around_action do |controller, action|
        if DiscourseStaffAlias::CONTROLLER_ACTIONS.include?(action_name = controller.action_name) &&
             (params = controller.params).dig(
               *DiscourseStaffAlias::CONTROLLER_PARAMS[action_name],
             ) == "true"
          existing_user = controller.current_user

          if !DiscourseStaffAlias.user_allowed?(existing_user) || params[:whisper].to_s == "true"
            raise Discourse::InvalidAccess
          end

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
