# frozen_string_literal: true

class DiscourseStaffAlias::EnabledValidator
  def initialize(opts = {})
  end

  def valid_value?(val)
    if val == 't'
      return SiteSetting.staff_alias_user_id > 0
    end

    true
  end

  def error_message
    I18n.t("site_settings.errors.staff_alias_username_not_set")
  end
end
