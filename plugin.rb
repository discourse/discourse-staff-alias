# frozen_string_literal: true

# name: discourse-staff-alias
# about: Allows set groups to create topics and posts, as well as make edits, as an alias user.
# meta_topic_id: 156202
# version: 0.1
# authors: tgxworld
# url: https://github.com/discourse/discourse-staff-alias

enabled_site_setting :staff_alias_enabled

require_relative "lib/discourse_staff_alias/engine"
require_relative "lib/discourse_staff_alias/validators/username_validator"
require_relative "lib/discourse_staff_alias/validators/enabled_validator"
require_relative "lib/discourse_staff_alias/with_current_user"
require_relative "lib/discourse_staff_alias/user_extension"
require_relative "lib/discourse_staff_alias/post_extension"
require_relative "lib/discourse_staff_alias/post_revision_extension"
require_relative "lib/discourse_staff_alias/topics_controller_extension"
require_relative "lib/discourse_staff_alias/posts_controller_extension"

register_asset "stylesheets/common/discourse-staff-alias.scss"

after_initialize do
  # rubocop:disable Discourse/Plugins/UsePluginInstanceOn
  DiscourseEvent.on(:site_setting_changed) do |name, _old_value, new_value|
    if name.to_s == "staff_alias_username" && new_value.present?
      DistributedMutex.synchronize("discourse_staff_alias") do
        if alias_user = DiscourseStaffAlias.alias_user
          UsernameChanger.change(alias_user, new_value, Discourse.system_user)
        else
          user =
            User.create!(
              email: SecureRandom.hex,
              password: SecureRandom.hex,
              skip_email_validation: true,
              username: new_value,
              active: true,
              trust_level: TrustLevel.levels[:leader],
              manual_locked_trust_level: TrustLevel.levels[:leader],
              moderator: true,
              approved: true,
            )

          SiteSetting.set(:staff_alias_user_id, user.id)
        end
      end
    end
  end
  # rubocop:enable Discourse/Plugins/UsePluginInstanceOn

  reloadable_patch do
    User.prepend(DiscourseStaffAlias::UserExtension)
    Post.prepend(DiscourseStaffAlias::PostExtension)
    PostRevision.prepend(DiscourseStaffAlias::PostRevisionExtension)
    TopicsController.prepend(DiscourseStaffAlias::TopicsControllerExtension)
    PostsController.prepend(DiscourseStaffAlias::PostsControllerExtension)
  end

  on(:post_created) do |post, opts, user|
    if user.aliased_user
      DiscourseStaffAlias::UsersPostsLink.create!(user_id: user.aliased_user.id, post_id: post.id)

      DraftSequence.next!(user.aliased_user, opts[:draft_key] || post.topic.draft_key)

      if !TopicUser.exists?(
           user_id: user.aliased_user.id,
           topic_id: post.topic_id,
           notification_level: TopicUser.notification_levels[:watching],
         )
        TopicUser.change(
          user.aliased_user.id,
          post.topic_id,
          notification_level: TopicUser.notification_levels[:watching],
        )
      end
    end
  end

  on(:before_create_notification) do |user, type, post, opts|
    if type == Notification.types[:liked] && user.id == SiteSetting.get(:staff_alias_user_id)
      user =
        User
          .joins(
            "INNER JOIN discourse_staff_alias_users_posts_links ON discourse_staff_alias_users_posts_links.user_id = users.id",
          )
          .where("discourse_staff_alias_users_posts_links.post_id = ?", post.id)
          .first

      PostAlerter.new.create_notification(user, type, post, opts) if user
    end
  end

  add_model_callback(PostRevision, :validate) do
    if self.user_id == SiteSetting.get(:staff_alias_user_id)
      if self.post.post_type == Post.types[:whisper]
        self.errors.add(:base, I18n.t("post_revisions.errors.cannot_edit_whisper_as_staff_alias"))
      end
    elsif self.post.user_id == SiteSetting.get(:staff_alias_user_id) &&
          User.human_user_id?(self.user_id)
      if (self.modifications.keys & %w[wiki post_type user_id title tags]).present? &&
           DiscourseStaffAlias.user_allowed?(self.user)
        self.user_id = SiteSetting.get(:staff_alias_user_id)
      else
        self.errors.add(:base, I18n.t("post_revisions.errors.cannot_edit_aliased_post_as_staff"))
      end
    end
  end

  on(:post_edited) do |post, _topic_changed, revisor|
    post_revision = revisor.post_revision
    next if post_revision.nil?

    alias_user_id = SiteSetting.get(:staff_alias_user_id)

    if post_revision.user_id == SiteSetting.get(:staff_alias_user_id) &&
         (editor = revisor.instance_variable_get(:@editor)) && editor.aliased_user
      DiscourseStaffAlias::UsersPostRevisionsLink.create!(
        user_id: editor.aliased_user.id,
        post_revision_id: revisor.post_revision.id,
      )

      DraftSequence.next!(editor.aliased_user, post.topic.draft_key)
    end

    if post_revision.modifications.keys.include? "user_id"
      original_user_id, revised_user_id = post_revision.modifications["user_id"]

      if revised_user_id == alias_user_id
        DiscourseStaffAlias::UsersPostsLink.create!(user_id: original_user_id, post_id: post.id)
      end
    end
  end

  add_to_class(:topic_view, :aliased_posts_usernames) do
    @aliased_posts_usernames ||=
      begin
        post_ids = []

        posts.each do |post|
          post_ids << post.id if post.user_id == SiteSetting.get(:staff_alias_user_id)
        end

        return {} if post_ids.empty?

        scope = DiscourseStaffAlias::UsersPostsLink.includes(:user).where(post_id: post_ids)

        scope.each_with_object({}) do |users_posts_link, object|
          object[users_posts_link.post_id] = users_posts_link.user&.username
        end
      end
  end

  add_to_serializer(
    :post,
    :is_staff_aliased,
    include_condition: -> do
      DiscourseStaffAlias.user_allowed?(scope.current_user) &&
        object.user_id == SiteSetting.get(:staff_alias_user_id)
    end,
  ) { true }

  add_to_serializer(
    :post,
    :aliased_username,
    include_condition: -> { include_is_staff_aliased? },
  ) do
    if @topic_view.present?
      @topic_view.aliased_posts_usernames[object.id]
    else
      User
        .joins(
          "INNER JOIN discourse_staff_alias_users_posts_links ON discourse_staff_alias_users_posts_links.user_id = users.id",
        )
        .where("discourse_staff_alias_users_posts_links.post_id = ?", object.id)
        .pick(:username)
    end
  end

  add_to_serializer(
    :post_revision,
    :is_staff_aliased,
    include_condition: -> do
      DiscourseStaffAlias.user_allowed?(scope.current_user) &&
        object.user_id == SiteSetting.get(:staff_alias_user_id)
    end,
  ) { true }

  add_to_serializer(
    :post_revision,
    :aliased_username,
    include_condition: -> do
      DiscourseStaffAlias.user_allowed?(scope.current_user) &&
        object.user_id == SiteSetting.get(:staff_alias_user_id)
    end,
  ) do
    User
      .joins(
        "INNER JOIN discourse_staff_alias_users_post_revisions_links ON discourse_staff_alias_users_post_revisions_links.user_id = users.id",
      )
      .where("discourse_staff_alias_users_post_revisions_links.post_revision_id = ?", object.id)
      .pick(:username)
  end

  add_to_serializer(
    :current_user,
    :can_act_as_staff_alias,
    include_condition: -> { DiscourseStaffAlias.user_allowed?(scope.current_user) },
  ) { true }

  class StaffAliasUserSerializer < BasicUserSerializer
    attributes :moderator
  end

  add_to_serializer(
    :topic_view,
    :staff_alias_user,
    include_condition: -> { DiscourseStaffAlias.user_allowed?(scope.current_user) },
  ) { StaffAliasUserSerializer.new(DiscourseStaffAlias.alias_user, root: false).as_json }

  add_to_serializer("TopicViewDetails", :staff_alias_can_create_post) do
    Guardian.new(DiscourseStaffAlias.alias_user).can_create?(Post, object.topic)
  end
end
