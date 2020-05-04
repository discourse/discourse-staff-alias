module DiscourseStaffAlias
  class DiscourseStaffAliasController < ::ApplicationController
    requires_plugin DiscourseStaffAlias

    before_action :ensure_logged_in

    def index
    end
  end
end
