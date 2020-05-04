import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import Composer from "discourse/models/composer";

function initialize(api) {
  const currentUser = api.getCurrentUser();

  if (currentUser && currentUser.staff) {
    api.modifySelectKit("composer-actions").appendContent(component => {
      if (component.action === Composer.REPLY) {
        return [
          {
            name: I18n.t(
              "composer.composer_actions.toggle_reply_as_staff_alias.label"
            ),
            description: I18n.t(
              "composer.composer_actions.toggle_reply_as_staff_alias.desc"
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
        props.as_staff_alias = true;
        return this._super(props);
      }
    });

    api.modifyClass("model:composer", {
      replyAsStaffAlias: false,

      @observes("isReplyAsStaffAlias")
      _updateUser() {
        if (this.isReplyAsStaffAlias) {
          this._originalUser = this.user;
          this.user = this.topic.staff_alias_user;
        } else if (this._originalUser) {
          this.user = this._originalUser;
        }
      },

      @discourseComputed(
        "replyAsStaffAlias",
        "whisper",
        "editingPost",
        "post.is_staff_alias"
      )
      isReplyAsStaffAlias(
        replyAsStaffAlias,
        whisper,
        editingPost,
        isStaffAlias
      ) {
        if (editingPost) {
          return isStaffAlias;
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
