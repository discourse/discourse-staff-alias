# frozen_string_literal: true

# name: discourse-staff-alias
# about: Allow staff users to post under an alias
# version: 0.1
# authors: tgxworld
# url: https://github.com/discourse/discourse-staff-alias

register_asset 'stylesheets/common/discourse-staff-alias.scss'
register_asset 'stylesheets/desktop/discourse-staff-alias.scss', :desktop
register_asset 'stylesheets/mobile/discourse-staff-alias.scss', :mobile

enabled_site_setting :discourse_staff_alias_enabled

PLUGIN_NAME ||= 'DiscourseStaffAlias'

load File.expand_path('lib/discourse-staff-alias/engine.rb', __dir__)

after_initialize do
  User.class_eval do
    has_one :user_alias, class_name: "DiscourseStaffAlias::UserAlias", foreign_key: :user_id
    has_one :aliased_user_alias, class_name: "DiscourseStaffAlias::UserAlias", foreign_key: :alias_user_id
    has_one :alias, through: :user_alias, source: :alias_user
    has_one :aliased_as, through: :aliased_user_alias, source: :user
  end

  add_controller_callback(PostsController, :around_action) do |controller, action|
    if ["create", "update"].include?(controller.action_name)
      # some params check
      # guardian check

      # We don't want to do this in the controller so this will be moved in the future
      unless controller.current_user.alias
        User.transaction do
          alias_user = User.create!(
            email: SecureRandom.hex,
            password: SecureRandom.hex,
            username: SecureRandom.hex(10),
            skip_email_validation: true,
            moderator: true,
            approved: true,
            active: true,
            manual_locked_trust_level: TrustLevel.levels[:leader],
            trust_level: TrustLevel.levels[:leader]
          )

          DiscourseStaffAlias::UserAlias.create!(
            user_id: controller.current_user.id,
            alias_user_id: alias_user.id
          )

          controller.current_user.reload
        end
      end

      controller.with_current_user(controller.current_user.alias) { action.call }
    else
      action.call
    end
  end
end
