# frozen_string_literal: true

class DiscourseStaffAlias::UsernameValidator
  def initialize(opts = {})
  end

  def valid_value?(val)
    return true if val.blank? && SiteSetting.get(:staff_alias_user_id).zero?
    @result = UsernameCheckerService.new.check_username(val, nil)
    return false if @result[:errors]
    @result[:available]
  end

  def error_message
    if @result[:errors]
      @result[:errors].join(", ")
    else
      I18n.t("login.not_available", suggestion: @result[:suggestion])
    end
  end
end
