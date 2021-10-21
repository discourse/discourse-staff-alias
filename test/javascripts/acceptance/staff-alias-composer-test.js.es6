import selectKit from "discourse/tests/helpers/select-kit-helper";
import {
  acceptance,
  updateCurrentUser,
} from "discourse/tests/helpers/qunit-helpers";
import { _clearSnapshots } from "select-kit/components/composer-actions";
import { presentUserIds } from "discourse/tests/helpers/presence-pretender";
import User from "discourse/models/user";
import topicFixtures from "discourse/tests/fixtures/topic";
import { skip, test } from "qunit";

const discoursePresenceInstalled = Object.keys(requirejs.entries).any((name) =>
  name.includes("/discourse-presence/")
);
const testIfPresenceInstalled = discoursePresenceInstalled ? test : skip;

acceptance("Discourse Staff Alias", function (needs) {
  needs.user();
  needs.settings({
    enable_whispers: true,
    staff_alias_enabled: true,
  });
  needs.hooks.beforeEach(() => {
    _clearSnapshots();
  });

  const topicResponse = topicFixtures["/t/280/1.json"];
  topicResponse["staff_alias_user"] = {
    id: -1,
    username: "system",
    avatar_template: "/a/b/c.jpg",
    moderator: false,
  };

  test("creating topic", async (assert) => {
    updateCurrentUser({ can_act_as_staff_alias: true });
    const composerActions = selectKit(".composer-actions");

    await visit("/");
    await click("button#create-topic");
    await composerActions.expand();

    assert.equal(composerActions.rows().length, 3);

    assert.equal(
      composerActions.rowByIndex(0).value(),
      "toggle_reply_as_staff_alias"
    );
  });

  test("creating post", async (assert) => {
    updateCurrentUser({ can_act_as_staff_alias: true });
    const composerActions = selectKit(".composer-actions");

    await visit("/t/internationalization-localization/280");
    await click("#topic-footer-buttons .create");
    await composerActions.expand();

    assert.equal(composerActions.rows().length, 5);

    assert.equal(
      composerActions.rowByIndex(4).value(),
      "toggle_reply_as_staff_alias"
    );
  });

  testIfPresenceInstalled(
    "uses whisper channel for presence",
    async (assert) => {
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

  test("editing post", async (assert) => {
    updateCurrentUser({ can_act_as_staff_alias: true });
    const composerActions = selectKit(".composer-actions");

    await visit("/t/internationalization-localization/280");
    await click("article#post_1 button.show-more-actions");
    await click("article#post_1 button.edit");
    await composerActions.expand();

    assert.equal(composerActions.rows().length, 2);

    assert.equal(
      composerActions.rowByIndex(1).value(),
      "toggle_reply_as_staff_alias"
    );
  });
});
