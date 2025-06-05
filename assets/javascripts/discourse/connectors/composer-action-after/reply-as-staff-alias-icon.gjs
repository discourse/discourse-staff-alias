import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import icon from "discourse/helpers/d-icon";

@tagName("")
@classNames("composer-action-after-outlet", "reply-as-staff-alias-icon")
export default class ReplyAsStaffAliasIcon extends Component {
  static shouldRender(_, context) {
    return context.siteSettings.staff_alias_enabled;
  }

  <template>
    {{#if this.model.isReplyAsStaffAlias}}
      <span class="reply-as-staff-alias-icon">{{icon "user-secret"}}</span>
    {{/if}}
  </template>
}
