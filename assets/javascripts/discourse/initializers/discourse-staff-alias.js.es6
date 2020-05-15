import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import Composer, { REPLY, EDIT, CREATE_TOPIC } from "discourse/models/composer";

function initialize(api) {
  const currentUser = api.getCurrentUser();

  if (currentUser && currentUser.staff) {
    api.modifySelectKit("composer-actions").prependContent(component => {
      if (component.action === CREATE_TOPIC) {
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
      if (
        component.action === REPLY ||
        (component.action === EDIT &&
          component.get("post.post_type") !==
            component.get("site.post_types.whisper") &&
          !component.get("post.aliased_staff_username"))
      ) {
        return [
          {
            name: I18n.t(
              `composer.composer_actions.as_staff_alias.${component.action}.label`
            ),
            description: I18n.t(
              `composer.composer_actions.as_staff_alias.${component.action}.desc`
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
        "post.aliased_staff_username"
      )
      isReplyAsStaffAlias(
        replyAsStaffAlias,
        whisper,
        editingPost,
        aliasedStaffUsername
      ) {
        if (editingPost && aliasedStaffUsername) {
          return true;
        } else {
          return !whisper && replyAsStaffAlias;
        }
      }
    });

    api.serializeOnCreate("as_staff_alias", "isReplyAsStaffAlias");
    api.serializeOnUpdate("as_staff_alias", "isReplyAsStaffAlias");

    api.includePostAttributes("aliased_staff_username");

    api.addPosterIcon((cfs, attrs) => {
      if (attrs.aliased_staff_username) {
        return {
          icon: "user-secret",
          text: attrs.aliased_staff_username,
          title: I18n.t("discourse_staff_alias.poster_icon_title", {
            username: attrs.aliased_staff_username
          }),
          url: `/u/${attrs.aliased_staff_username}`,
          className: "user-title"
        };
      }
    });
  }
}

export default {
  name: "discourse-staff-alias",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");

    if (siteSettings.discourse_staff_alias_enabled) {
      withPluginApi("0.9.0", initialize);
    }
  }
};
