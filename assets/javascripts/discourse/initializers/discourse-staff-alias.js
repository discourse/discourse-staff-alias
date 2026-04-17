import { tracked } from "@glimmer/tracking";
import { withPluginApi } from "discourse/lib/plugin-api";
import { CREATE_TOPIC, EDIT, REPLY } from "discourse/models/composer";
import { i18n } from "discourse-i18n";

function initialize(api) {
  const currentUser = api.getCurrentUser();

  if (currentUser?.can_act_as_staff_alias) {
    api.registerValueTransformer("composer-actions-content", ({ value, context }) => {
      const { action, topic, post, composerModel } = context;

      if (action === CREATE_TOPIC) {
        value.unshift({
          name: i18n(
            "composer.composer_actions.as_staff_alias.create_topic.label"
          ),
          description: i18n(
            "composer.composer_actions.as_staff_alias.create_topic.desc"
          ),
          icon: "user-secret",
          id: "toggle_reply_as_staff_alias",
        });
      }

      const site = api.container.lookup("service:site");

      if (
        topic?.details?.staff_alias_can_create_post &&
        (action === REPLY ||
          (action === EDIT &&
            post?.post_type !== site?.post_types?.whisper &&
            !post?.is_staff_aliased))
      ) {
        value.push({
          name: i18n(
            `composer.composer_actions.as_staff_alias.${action}.label`
          ),
          description: i18n(
            `composer.composer_actions.as_staff_alias.${action}.desc`
          ),
          icon: "user-secret",
          id: "toggle_reply_as_staff_alias",
        });
      }

      return value;
    });

    api.registerBehaviorTransformer("composer-actions-on-select", ({ context, next }) => {
      const { actionId, model } = context;

      if (actionId === "toggle_reply_as_staff_alias") {
        model.toggleProperty("replyAsStaffAlias");
        if (model.whisper) {
          model.set("whisper", false);
        }
        return;
      }

      if (actionId === "toggle_whisper") {
        if (model.replyAsStaffAlias) {
          model.set("replyAsStaffAlias", false);
        }
      }

      next();
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
      withPluginApi(initialize);
    }
  },
};
