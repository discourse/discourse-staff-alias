# frozen_string_literal: true

RSpec.describe "Core features", type: :system do
  before do
    SiteSetting.set(:staff_alias_username, "new_username")
    enable_current_plugin
  end

  it_behaves_like "having working core features"
end
