export default {
  shouldRender(_, component) {
    return component.siteSettings.discourse_staff_alias_enabled;
  }
};
