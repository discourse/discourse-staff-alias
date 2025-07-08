import { tracked } from "@glimmer/tracking";
import { withPluginApi } from "discourse/lib/plugin-api";
import { CREATE_TOPIC, EDIT, REPLY } from "discourse/models/composer";
import { i18n } from "discourse-i18n";

const PLUGIN_ID = "discourse-staff-alias";

function initialize(api) {
  const currentUser = api.getCurrentUser();

  if (currentUser?.can_act_as_staff_alias) {
    api.modifySelectKit("composer-actions").prependContent((component) => {
      if (component.action === CREATE_TOPIC) {
        return [
          {
            name: i18n(
              "composer.composer_actions.as_staff_alias.create_topic.label"
            ),
            description: i18n(
              "composer.composer_actions.as_staff_alias.create_topic.desc"
            ),
            icon: "user-secret",
            id: "toggle_reply_as_staff_alias",
          },
        ];
      }
    });

    api.modifySelectKit("composer-actions").appendContent((component) => {
      if (
        component.topic?.details?.staff_alias_can_create_post &&
        (component.action === REPLY ||
          (component.action === EDIT &&
            component.get("post.post_type") !==
              component.get("site.post_types.whisper") &&
            !component.get("post.is_staff_aliased")))
      ) {
        return [
          {
            name: i18n(
              `composer.composer_actions.as_staff_alias.${component.action}.label`
            ),
            description: i18n(
              `composer.composer_actions.as_staff_alias.${component.action}.desc`
            ),
            icon: "user-secret",
            id: "toggle_reply_as_staff_alias",
          },
        ];
      }
    });

    api.modifyClass(
      "component:composer-presence-display",
      (ComposerPresenceDisplayComponent) =>
        class extends ComposerPresenceDisplayComponent {
          get state() {
            const { isReplyAsStaffAlias } = this.args.model;

            if (isReplyAsStaffAlias) {
              return "whisper";
            }

            return super.state;
          }
        }
    );

    api.modifyClass("component:composer-actions", {
      pluginId: PLUGIN_ID,

      toggleReplyAsStaffAliasSelected(options, model) {
        model.toggleProperty("replyAsStaffAlias");
        if (model.whisper) {
          model.set("whisper", false);
        }
      },

      toggleWhisperSelected(options, model) {
        this._super(...arguments);
        if (model.replyAsStaffAlias) {
          model.set("replyAsStaffAlias", false);
        }
      },
    });

    api.modifyClass(
      "model:composer",
      (Superclass) =>
        class extends Superclass {
          @tracked replyAsStaffAlias = false;
          @tracked _originalUser;

          get user() {
            if (this.isReplyAsStaffAlias && this.topic) {
              return this.get("topic.staff_alias_user");
            } else {
              return this._originalUser;
            }
          }

          set user(value) {
            this._originalUser = value;
          }

          get isReplyAsStaffAlias() {
            if (this.get("editingPost") && this.get("post.is_staff_aliased")) {
              return true;
            } else {
              return !this.get("whisper") && this.get("replyAsStaffAlias");
            }
          }
        }
    );

    api.serializeOnCreate("as_staff_alias", "isReplyAsStaffAlias");
    api.serializeOnUpdate("as_staff_alias", "isReplyAsStaffAlias");
    api.serializeToTopic("as_staff_alias", "isReplyAsStaffAlias");

    api.addTrackedPostProperties("aliased_username", "is_staff_aliased");

    api.addPosterIcon((cfs, post) => {
      if (post.is_staff_aliased) {
        const props = {
          icon: "user-secret",
          className: "user-title",
        };

        if (post.aliased_username) {
          props.text = post.aliased_username;

          props.title = i18n("discourse_staff_alias.poster_icon_title", {
            username: post.aliased_username,
          });

          props.url = `/u/${post.aliased_username}`;
        } else {
          props.text = i18n("discourse_staff_alias.aliased_user_deleted");
        }

        return props;
      }
    });
  }
}

export default {
  name: "discourse-staff-alias",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

    if (siteSettings.staff_alias_enabled) {
      withPluginApi("0.10.0", initialize);
    }
  },
};
