# frozen_string_literal: true

# name: discourse-staff-alias
# about: Allow staff users to post under an alias
# version: 0.1
# authors: tgxworld
# url: https://github.com/discourse/discourse-staff-alias

enabled_site_setting :discourse_staff_alias_enabled

PLUGIN_NAME ||= 'DiscourseStaffAlias'

[
  'lib/discourse-staff-alias/engine.rb',
  'lib/discourse-staff-alias/validators/username_validator.rb',
  'lib/discourse-staff-alias/validators/enabled_validator.rb'
].each do |path|
  load File.expand_path(path, __dir__)
end

after_initialize do
  DiscourseEvent.on(:site_setting_changed) do |name, _old_value, new_value|
    if name.to_s == 'discourse_staff_alias_username' && new_value.present?
      DistributedMutex.synchronize("discourse_staff_alias") do
        if alias_user = DiscourseStaffAlias.alias_user
          UsernameChanger.change(
            alias_user,
            new_value,
            Discourse.system_user
          )
        else
          user = User.create!(
            email: SecureRandom.hex,
            password: SecureRandom.hex,
            skip_email_validation: true,
            username: new_value,
            active: true,
            trust_level: TrustLevel.levels[:leader],
            manual_locked_trust_level: TrustLevel.levels[:leader],
            moderator: true,
            approved: true
          )

          SiteSetting.set(:discourse_staff_alias_user_id, user.id)
        end
      end
    end
  end

  add_permitted_post_create_param(:as_staff_alias)
  add_permitted_post_create_param(:staff_user_id)

  NewPostManager.add_handler do |manager|
    next if !manager.args[:as_staff_alias]

    result = manager.perform_create_post

    if result.success?
      DiscourseStaffAlias::UsersPostLinks.create!(
        user_id: manager.args[:staff_user_id],
        post_id: result.post.id,
        action: DiscourseStaffAlias::UsersPostLinks::ACTIONS["create"]
      )
    end

    result
  end

  add_controller_callback(PostsController, :around_action) do |controller, action|
    supported_actions = DiscourseStaffAlias::UsersPostLinks::ACTIONS
    params = controller.params

    if params[:as_staff_alias] == "true" && supported_actions.keys.include?(controller.action_name)
      existing_user = controller.current_user
      raise Discourse::InvalidAccess if !existing_user.staff? || params[:whisper]

      controller.params[:staff_user_id] = existing_user.id

      controller.with_current_user(DiscourseStaffAlias.alias_user) do
        Post.transaction do
          action.call

          if controller.response.successful? && controller.action_name == 'update'
            DiscourseStaffAlias::UsersPostLinks.create!(
              user_id: existing_user.id,
              post_id: params["id"],
              action: supported_actions['update']
            )
          end
        end
      end
    else
      action.call
    end
  end
end
