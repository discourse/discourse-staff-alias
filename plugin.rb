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

  register_post_custom_field_type(DiscourseStaffAlias::REPLIED_AS_ALIAS, :boolean)

  on(:before_create_post) do |post, opts|
    if opts["as_staff_alias"] == "true" && opts["staff_user_id"]
      post.custom_fields ||= {}
      post.custom_fields[DiscourseStaffAlias::REPLIED_AS_ALIAS] = true
    end
  end

  on(:post_created) do |post, opts, _user|
    if opts["as_staff_alias"] == "true" && opts["staff_user_id"]
      DiscourseStaffAlias::UsersPostLinks.create!(
        user_id: opts["staff_user_id"],
        post_id: post.id,
        action: DiscourseStaffAlias::UsersPostLinks::ACTIONS[
          DiscourseStaffAlias::UsersPostLinks::CREATE_POST_ACTION
        ]
      )
    end
  end

  topic_view_post_custom_fields_whitelister { [DiscourseStaffAlias::REPLIED_AS_ALIAS] }

  add_to_class(:topic_view, :aliased_staff_posts) do
    @aliased_staff_posts ||= begin
      @post_custom_fields.each_with_object({}) do |field, object|
        object[field[0]] = true if field[1][DiscourseStaffAlias::REPLIED_AS_ALIAS]
      end
    end
  end

  add_to_serializer(:post, :include_is_staff_alias?, false) do
    scope.current_user.staff? && @topic_view.present?
  end

  add_to_serializer(:post, :is_staff_alias, false) do
    @topic_view.aliased_staff_posts[object.id]
  end

  add_controller_callback(PostsController, :around_action) do |controller, action|
    supported_actions = DiscourseStaffAlias::UsersPostLinks::ACTIONS
    params = controller.params
    action_name = controller.action_name

    if params[:as_staff_alias] == "true" && supported_actions.keys.include?(action_name)
      existing_user = controller.current_user
      raise Discourse::InvalidAccess if !existing_user.staff? || params[:whisper]

      is_editing = action_name == DiscourseStaffAlias::UsersPostLinks::UPDATE_POST_ACTION

      if is_editing
        if !DiscourseStaffAlias::UsersPostLinks.exists?(
          post_id: params["id"],
          action: supported_actions[DiscourseStaffAlias::UsersPostLinks::CREATE_POST_ACTION]
        )
          raise Discourse::InvalidAccess
        end
      elsif action_name == DiscourseStaffAlias::UsersPostLinks::CREATE_POST_ACTION
        controller.params[:staff_user_id] = existing_user.id
      end

      controller.with_current_user(DiscourseStaffAlias.alias_user) do
        Post.transaction do
          action.call

          if controller.response.successful? && is_editing
            DiscourseStaffAlias::UsersPostLinks.create!(
              user_id: existing_user.id,
              post_id: params["id"],
              action: supported_actions[
                DiscourseStaffAlias::UsersPostLinks::UPDATE_POST_ACTION
              ]
            )
          end
        end
      end
    else
      action.call
    end
  end
end
