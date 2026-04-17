import { click, fillIn, visit } from "@ember/test-helpers";
import { skip, test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import User from "discourse/models/user";
import { _clearSnapshots } from "discourse/select-kit/components/composer-actions";
import topicFixtures from "discourse/tests/fixtures/topic";
import { presentUserIds } from "discourse/tests/helpers/presence-pretender";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const discoursePresenceInstalled = Object.keys(requirejs.entries).some((name) =>
  name.includes("/discourse-presence/")
);
const testIfPresenceInstalled = discoursePresenceInstalled ? test : skip;
let staffAliasCanCreatePost = true;

function composerActionsDropdown() {
  return {
    async expand() {
      await click(".composer-actions-trigger");
    },
    async selectRowByValue(value) {
      await click(`[data-action-id='${value}']`);
    },
    rowByValue(value) {
      const el = document.querySelector(
        `.composer-actions-dropdown [data-action-id='${value}']`
      );
      return {
        exists() {
          return !!el;
        },
      };
    },
    rows() {
      return document.querySelectorAll(
        ".composer-actions-dropdown [data-action-id]"
      );
    },
    rowByIndex(index) {
      const rows = document.querySelectorAll(
        ".composer-actions-dropdown [data-action-id]"
      );
      const row = rows[index];
      return {
        value() {
          return row ? row.dataset.actionId : null;
        },
      };
    },
  };
}

acceptance("Discourse Staff Alias", function (needs) {
  needs.user({ can_act_as_staff_alias: true });

  needs.settings({
    enable_whispers: true,
    staff_alias_enabled: true,
  });

  needs.hooks.beforeEach(() => {
    _clearSnapshots();
  });

  needs.hooks.afterEach(() => {
    staffAliasCanCreatePost = true;
  });

  needs.pretender((server, helper) => {
    const topicResponse = cloneJSON(topicFixtures["/t/280/1.json"]);

    topicResponse.staff_alias_user = {
      id: -1,
      username: "system",
      avatar_template: "/a/b/c.jpg",
      moderator: false,
    };

    server.get("/t/280.json", () => {
      topicResponse.details.staff_alias_can_create_post =
        staffAliasCanCreatePost;
      return helper.response(topicResponse);
    });
  });

  test("creating topic", async function (assert) {
    const composerActions = composerActionsDropdown();

    await visit("/");
    await click("button#create-topic");
    await composerActions.expand();

    assert.true(
      composerActions.rowByValue("toggle_reply_as_staff_alias").exists()
    );
  });

  test("creating post", async function (assert) {
    const composerActions = composerActionsDropdown();

    await visit("/t/internationalization-localization/280");
    await click("#topic-footer-buttons .create");
    await composerActions.expand();

    assert.true(
      composerActions.rowByValue("toggle_reply_as_staff_alias").exists()
    );
  });

  test("creating post when staff alias user can not create post in given topic", async function (assert) {
    staffAliasCanCreatePost = false;

    await visit("/t/internationalization-localization/280");
    await click("#topic-footer-buttons .create");
    const composerActions = composerActionsDropdown();
    await composerActions.expand();

    assert.false(
      composerActions.rowByValue("toggle_reply_as_staff_alias").exists()
    );
  });

  testIfPresenceInstalled(
    "uses whisper channel for presence",
    async function (assert) {
      const composerActions = composerActionsDropdown();

      await visit("/t/internationalization-localization/280");
      await click("#topic-footer-buttons .create");

      await fillIn(".d-editor-input", "this is the content of my reply");

      assert.deepEqual(presentUserIds("/discourse-presence/whisper/280"), []);
      assert.deepEqual(presentUserIds("/discourse-presence/reply/280"), [
        User.current().id,
      ]);

      await composerActions.expand();
      await composerActions.selectRowByValue("toggle_reply_as_staff_alias");

      assert.deepEqual(presentUserIds("/discourse-presence/reply/280"), []);
      assert.deepEqual(presentUserIds("/discourse-presence/whisper/280"), [
        User.current().id,
      ]);

      await composerActions.expand();
      await composerActions.selectRowByValue("toggle_reply_as_staff_alias");

      assert.deepEqual(presentUserIds("/discourse-presence/whisper/280"), []);
      assert.deepEqual(presentUserIds("/discourse-presence/reply/280"), [
        User.current().id,
      ]);
    }
  );

  test("editing post", async function (assert) {
    const composerActions = composerActionsDropdown();

    await visit("/t/internationalization-localization/280");
    await click("article#post_1 button.show-more-actions");
    await click("article#post_1 button.edit");
    await composerActions.expand();

    assert.strictEqual(composerActions.rows().length, 2);

    assert.strictEqual(
      composerActions.rowByIndex(1).value(),
      "toggle_reply_as_staff_alias"
    );
  });
});
