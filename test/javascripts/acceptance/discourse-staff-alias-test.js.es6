import { acceptance } from "helpers/qunit-helpers";

acceptance("discourse-staff-alias", { loggedIn: true });

test("discourse-staff-alias works", async assert => {
  await visit("/admin/plugins/discourse-staff-alias");

  assert.ok(false, "it shows the discourse-staff-alias button");
});
