import selectKit from "helpers/select-kit-helper";
import { acceptance, updateCurrentUser } from "helpers/qunit-helpers";
import { _clearSnapshots } from "select-kit/components/composer-actions";

acceptance("Discourse Staff Alias", {
  loggedIn: true,
  settings: {
    enable_whispers: true,
    discourse_staff_alias_enabled: true
  },
  beforeEach() {
    _clearSnapshots();
  }
});

QUnit.test("creating topic", async assert => {
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

QUnit.test("creating post", async assert => {
  const composerActions = selectKit(".composer-actions");

  await visit("/t/internationalization-localization/280");
  await click(".topic-timeline button.create");
  await composerActions.expand();

  assert.equal(composerActions.rows().length, 5);

  assert.equal(
    composerActions.rowByIndex(4).value(),
    "toggle_reply_as_staff_alias"
  );
});

QUnit.test("editing post", async assert => {
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
