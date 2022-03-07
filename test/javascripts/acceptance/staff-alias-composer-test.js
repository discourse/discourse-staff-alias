import selectKit from "discourse/tests/helpers/select-kit-helper";
import {
  acceptance,
  updateCurrentUser,
} from "discourse/tests/helpers/qunit-helpers";
import { _clearSnapshots } from "select-kit/components/composer-actions";
import { presentUserIds } from "discourse/tests/helpers/presence-pretender";
import User from "discourse/models/user";
import topicFixtures from "discourse/tests/fixtures/topic";
import { cloneJSON } from "discourse-common/lib/object";
import { skip, test } from "qunit";
import { click, fillIn, visit } from "@ember/test-helpers";

const discoursePresenceInstalled = Object.keys(requirejs.entries).any((name) =>
  name.includes("/discourse-presence/")
);
const testIfPresenceInstalled = discoursePresenceInstalled ? test : skip;
let staffAliasCanCreatePost = true;

acceptance("Discourse Staff Alias", function (needs) {
  needs.user();

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
    updateCurrentUser({ can_act_as_staff_alias: true });
    const composerActions = selectKit(".composer-actions");

    await visit("/");
    await click("button#create-topic");
    await composerActions.expand();

    assert.strictEqual(composerActions.rows().length, 3);

    assert.strictEqual(
      composerActions.rowByIndex(0).value(),
      "toggle_reply_as_staff_alias"
    );
  });

  test("creating post", async function (assert) {
    updateCurrentUser({ can_act_as_staff_alias: true });
    const composerActions = selectKit(".composer-actions");

    await visit("/t/internationalization-localization/280");
    await click("#topic-footer-buttons .create");
    await composerActions.expand();

    assert.strictEqual(composerActions.rows().length, 5);

    assert.strictEqual(
      composerActions.rowByIndex(4).value(),
      "toggle_reply_as_staff_alias"
    );
  });

  test("creating post when staff alias user can not create post in given topic", async function (assert) {
    updateCurrentUser({ can_act_as_staff_alias: true });
    staffAliasCanCreatePost = false;

    await visit("/t/internationalization-localization/280");
    await click("#topic-footer-buttons .create");
    const composerActions = selectKit(".composer-actions");
    await composerActions.expand();

    assert.strictEqual(composerActions.rows().length, 4);
  });

  testIfPresenceInstalled(
    "uses whisper channel for presence",
    async function (assert) {
      updateCurrentUser({ can_act_as_staff_alias: true });
      const composerActions = selectKit(".composer-actions");

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
    updateCurrentUser({ can_act_as_staff_alias: true });
    const composerActions = selectKit(".composer-actions");

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
