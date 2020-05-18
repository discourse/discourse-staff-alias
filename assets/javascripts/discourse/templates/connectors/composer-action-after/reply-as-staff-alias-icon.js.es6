export default {
  shouldRender(_, component) {
    return component.siteSettings.staff_alias_enabled;
  }
};
