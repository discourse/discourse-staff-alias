import Component from "@ember/component";
import { LinkTo } from "@ember/routing";
import { classNames, tagName } from "@ember-decorators/component";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

@tagName("")
@classNames("revision-user-details-after-outlet", "aliased-staff-user-details")
export default class AliasedStaffUserDetails extends Component {
  static shouldRender(_, context) {
    return context.siteSettings.staff_alias_enabled;
  }

  <template>
    {{#if this.model.is_staff_aliased}}
      <div class="aliased-staff-user-details">
        {{#if this.model.aliased_username}}
          <LinkTo
            @route="user"
            @model={{this.model.aliased_username}}
            title={{i18n
              "discourse_staff_alias.post_revision_icon_title"
              username=this.model.aliased_username
            }}
          >
            <span>({{icon "user-secret"}}
              {{this.model.aliased_username}})</span>
          </LinkTo>
        {{else}}
          <span>
            ({{icon "user-secret"}}
            {{i18n "discourse_staff_alias.aliased_user_deleted"}})
          </span>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
