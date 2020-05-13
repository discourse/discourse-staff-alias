import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import Composer from "discourse/models/composer";

function initialize(api) {
  const currentUser = api.getCurrentUser();

  if (currentUser && currentUser.staff) {
    api.modifySelectKit("composer-actions").prependContent(component => {
      if (component.action === Composer.CREATE_TOPIC) {
        return [
          {
            name: I18n.t(
              "composer.composer_actions.as_staff_alias.create_topic.label"
            ),
            description: I18n.t(
              "composer.composer_actions.as_staff_alias.create_topic.desc"
            ),
            icon: "user-secret",
            id: "toggle_reply_as_staff_alias"
          }
        ];
      } else {
        [];
      }
    });

    api.modifySelectKit("composer-actions").appendContent(component => {
      if (component.action === Composer.REPLY) {
        return [
          {
            name: I18n.t(
              "composer.composer_actions.as_staff_alias.reply.label"
            ),
            description: I18n.t(
              "composer.composer_actions.as_staff_alias.reply.desc"
            ),
            icon: "user-secret",
            id: "toggle_reply_as_staff_alias"
          }
        ];
      } else {
        [];
      }
    });

    api.modifyClass("component:composer-actions", {
      toggleReplyAsStaffAliasSelected(options, model) {
        model.toggleProperty("replyAsStaffAlias");
        if (model.whisper) model.set("whisper", false);
      },

      toggleWhisperSelected(options, model) {
        this._super(...arguments);
        if (model.replyAsStaffAlias) model.set("replyAsStaffAlias", false);
      }
    });

    api.modifyClass("model:post", {
      beforeUpdate(props) {
        props.as_staff_alias = !!this.staff_alias_username;
        return this._super(props);
      }
    });

    api.modifyClass("model:composer", {
      replyAsStaffAlias: false,

      @observes("isReplyAsStaffAlias")
      _updateUser() {
        if (this.isReplyAsStaffAlias) {
          const props = {
            _presenceStaffOnly: true
          };

          if (this.topic) {
            props._originalUser = this.user;
            props.user = this.get("topic.staff_alias_user");
          }

          this.setProperties(props);
        } else {
          const props = {
            _presenceStaffOnly: false
          };

          if (this._originalUser) {
            props.user = this.get("_originalUser");
          }

          this.setProperties(props);
        }
      },

      @discourseComputed(
        "replyAsStaffAlias",
        "whisper",
        "editingPost",
        "post.staff_alias_username"
      )
      isReplyAsStaffAlias(
        replyAsStaffAlias,
        whisper,
        editingPost,
        staffAliasUsername
      ) {
        if (editingPost) {
          return staffAliasUsername;
        } else {
          return !whisper && replyAsStaffAlias;
        }
      }
    });

    api.includePostAttributes("staff_alias_username");

    api.addPosterIcon((cfs, attrs) => {
      if (attrs.staff_alias_username) {
        return {
          icon: "user-secret",
          text: attrs.staff_alias_username,
          title: I18n.t("discourse_staff_alias.poster_icon_title", {
            username: attrs.staff_alias_username
          }),
          url: `/u/${attrs.staff_alias_username}/summary`,
          className: "user-title"
        };
      }
    });

    Composer.serializeOnCreate("as_staff_alias", "isReplyAsStaffAlias");
  }
}

export default {
  name: "discourse-staff-alias",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");

    if (siteSettings.discourse_staff_alias_enabled) {
      withPluginApi("0.8.43", initialize);
    }
  }
};
