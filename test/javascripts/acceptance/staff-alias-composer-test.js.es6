import selectKit from "discourse/tests/helpers/select-kit-helper";
import {
  acceptance,
  updateCurrentUser,
} from "discourse/tests/helpers/qunit-helpers";
import { _clearSnapshots } from "select-kit/components/composer-actions";

acceptance("Discourse Staff Alias", function (needs) {
  needs.user();
  needs.settings({
    enable_whispers: true,
    staff_alias_enabled: true,
  });
  needs.hooks.beforeEach(() => {
    _clearSnapshots();
  });

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
    await click(".topic-timeline button.create");
    await composerActions.expand();

    assert.equal(composerActions.rows().length, 5);

    assert.equal(
      composerActions.rowByIndex(4).value(),
      "toggle_reply_as_staff_alias"
    );
  });

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
