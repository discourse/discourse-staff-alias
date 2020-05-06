import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed from "discourse-common/utils/decorators";
import Composer from "discourse/models/composer";

function initialize(api) {
  api
    .modifySelectKit("composer-actions")
    .appendContent((selectKit, _content) => {
      if (
        selectKit.siteSettings.discourse_staff_alias_enabled &&
        selectKit.get("currentUser.staff") &&
        selectKit.action === Composer.REPLY
      ) {
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
    }
  });

  api.modifyClass("model:composer", {
    replyAsStaffAlias: false
  });

  Composer.serializeOnCreate("as_staff_alias", "replyAsStaffAlias");
}

export default {
  name: "discourse-staff-alias",

  initialize() {
    withPluginApi("0.8.42", initialize);
  }
};
