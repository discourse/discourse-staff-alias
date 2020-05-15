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

register_asset 'stylesheets/common/discourse-staff-alias.scss'

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

  reloadable_patch do
    User.class_eval do
      attr_accessor :aliased_staff_user

      has_many :users_posts_links, class_name: "DiscourseStaffAlias::UsersPostsLink", dependent: :delete_all
      has_many :users_post_revisions_links, class_name: "DiscourseStaffAlias::UsersPostRevisionsLink", dependent: :delete_all
    end

    Post.class_eval do
      has_many :users_posts_links, class_name: "DiscourseStaffAlias::UsersPostsLink", dependent: :delete_all
    end

    PostRevision.class_eval do
      has_many :users_post_revisions_links, class_name: "DiscourseStaffAlias::UsersPostRevisionsLink", dependent: :delete_all
    end

    PostsController.class_eval do
      around_action do |controller, action|
        if DiscourseStaffAlias::CONTROLLER_ACTIONS.include?(action_name = controller.action_name) &&
           (params = controller.params).dig(*DiscourseStaffAlias::CONTROLLER_PARAMS[action_name]) == "true"

          existing_user = controller.current_user
          raise Discourse::InvalidAccess if !existing_user.staff? || params[:whisper]

          alias_user = DiscourseStaffAlias.alias_user
          alias_user.aliased_staff_user = existing_user

          controller.with_current_user(alias_user) do
            action.call
          end
        else
          action.call
        end
      end

      def with_current_user(user)
        @current_user = user
        yield if block_given?
      ensure
        @current_user = nil
      end

      def current_user
        @current_user || current_user_provider.current_user
      end
    end
  end

  register_ignore_draft_sequence_callback do |user_id|
    user_id == SiteSetting.get(:discourse_staff_alias_user_id)
  end

  on(:post_created) do |post, opts, user|
    if user.aliased_staff_user
      DiscourseStaffAlias::UsersPostsLink.create!(
        user_id: user.aliased_staff_user.id,
        post_id: post.id
      )

      DraftSequence.next!(user.aliased_staff_user, opts[:draft_key] || post.topic.draft_key)
    end
  end

  add_model_callback(PostRevision, :validate) do
    if self.user_id == SiteSetting.get(:discourse_staff_alias_user_id)
      if self.post.post_type == Post.types[:whisper]
        self.errors.add(:base, I18n.t("post_revisions.errors.cannot_edit_whisper_as_staff_alias"))
      end
    elsif self.post.user_id == SiteSetting.get(:discourse_staff_alias_user_id)
      self.errors.add(:base, I18n.t("post_revisions.errors.cannot_edit_aliased_post_as_staff"))
    end
  end

  on(:post_edited) do |post, _topic_changed, revisor|
    if revisor.post_revision&.user_id == SiteSetting.get(:discourse_staff_alias_user_id) &&
       (editor = revisor.instance_variable_get(:@editor)) &&
       editor.aliased_staff_user

      DiscourseStaffAlias::UsersPostRevisionsLink.create!(
        user_id: editor.aliased_staff_user.id,
        post_revision_id: revisor.post_revision.id
      )

      DraftSequence.next!(editor.aliased_staff_user, post.topic.draft_key)
    end
  end

  add_to_class(:topic_view, :aliased_staff_posts_usernames) do
    @aliased_staff_posts_usernames ||= begin
      post_ids = []

      posts.each do |post|
        if post.user_id == SiteSetting.get(:discourse_staff_alias_user_id)
          post_ids << post.id
        end
      end

      return {} if post_ids.empty?

      scope = DiscourseStaffAlias::UsersPostsLink.includes(:user)
        .where(post_id: post_ids)

      scope.each_with_object({}) do |users_posts_link, object|
        object[users_posts_link.post_id] = users_posts_link.user.username
      end
    end
  end

  add_to_serializer(:post, :include_aliased_staff_username?, false) do
    SiteSetting.discourse_staff_alias_enabled &&
      scope.current_user&.staff? &&
      object.user_id == SiteSetting.get(:discourse_staff_alias_user_id)
  end

  add_to_serializer(:post, :aliased_staff_username, false) do
    if @topic_view.present?
      @topic_view.aliased_staff_posts_usernames[object.id]
    else
      User.joins("INNER JOIN discourse_staff_alias_users_posts_links ON discourse_staff_alias_users_posts_links.user_id = users.id")
        .where("discourse_staff_alias_users_posts_links.post_id = ?", object.id)
        .pluck_first(:username)
    end
  end

  add_to_serializer(:post_revision, :include_aliased_staff_username?, false) do
    SiteSetting.discourse_staff_alias_enabled &&
      scope.current_user&.staff? &&
      object.user_id == SiteSetting.get(:discourse_staff_alias_user_id)
  end

  add_to_serializer(:post_revision, :aliased_staff_username, false) do
    User.joins("INNER JOIN discourse_staff_alias_users_post_revisions_links ON discourse_staff_alias_users_post_revisions_links.user_id = users.id")
      .where("discourse_staff_alias_users_post_revisions_links.post_revision_id = ?", object.id)
      .pluck_first(:username)
  end

  class StaffAliasUserSerializer < BasicUserSerializer
    attributes :moderator
  end

  add_to_serializer(:topic_view, :include_staff_alias_user?, false) do
    SiteSetting.discourse_staff_alias_enabled && scope.current_user&.staff?
  end

  add_to_serializer(:topic_view, :staff_alias_user, false) do
    StaffAliasUserSerializer.new(DiscourseStaffAlias.alias_user, root: false).as_json
  end
end
