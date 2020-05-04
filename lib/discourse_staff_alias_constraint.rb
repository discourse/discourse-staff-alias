class DiscourseStaffAliasConstraint
  def matches?(request)
    SiteSetting.discourse_staff_alias_enabled
  end
end
