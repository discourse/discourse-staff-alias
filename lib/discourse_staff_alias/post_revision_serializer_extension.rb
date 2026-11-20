# frozen_string_literal: true

module DiscourseStaffAlias
  module PostRevisionSerializerExtension
    def include_user_changes?
      if !DiscourseStaffAlias.user_allowed?(scope.current_user) && alias_ownership_change?
        return false
      end

      super
    end

    private

    def alias_ownership_change?
      current["user_id"] == SiteSetting.get(:staff_alias_user_id)
    end
  end
end
