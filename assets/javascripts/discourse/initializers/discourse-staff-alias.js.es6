import { withPluginApi } from "discourse/lib/plugin-api";
import I18n from "I18n";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import { REPLY, EDIT, CREATE_TOPIC } from "discourse/models/composer";

function initialize(api) {
  const currentUser = api.getCurrentUser();

  if (currentUser && currentUser.can_act_as_staff_alias) {
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
          !component.get("post.is_staff_aliased"))
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
        "post.is_staff_aliased"
      )
      isReplyAsStaffAlias(
        replyAsStaffAlias,
        whisper,
        editingPost,
        isStaffAliased
      ) {
        if (editingPost && isStaffAliased) {
          return true;
        } else {
          return !whisper && replyAsStaffAlias;
        }
      }
    });

    api.serializeOnCreate("as_staff_alias", "isReplyAsStaffAlias");
    api.serializeOnUpdate("as_staff_alias", "isReplyAsStaffAlias");
    api.serializeToTopic("as_staff_alias", "isReplyAsStaffAlias");

    api.includePostAttributes("aliased_staff_username");
    api.includePostAttributes("is_staff_aliased");

    api.addPosterIcon((cfs, attrs) => {
      if (attrs.is_staff_aliased) {
        const props = {
          icon: "user-secret",
          className: "user-title"
        };

        if (attrs.aliased_staff_username) {
          props.text = attrs.aliased_staff_username;

          props.title = I18n.t("discourse_staff_alias.poster_icon_title", {
            username: attrs.aliased_staff_username
          });

          props.url = `/u/${attrs.aliased_staff_username}`;
        } else {
          props.text = I18n.t("discourse_staff_alias.aliased_user_deleted");
        }

        return props;
      }
    });
  }
}

export default {
  name: "discourse-staff-alias",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");

    if (siteSettings.staff_alias_enabled) {
      withPluginApi("0.10.0", initialize);
    }
  }
};
