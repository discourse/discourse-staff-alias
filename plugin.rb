# frozen_string_literal: true

# name: discourse-staff-alias
# about: Allow staff users to post under an alias
# version: 0.1
# authors: tgxworld
# url: https://github.com/discourse/discourse-staff-alias

register_asset 'stylesheets/common/discourse-staff-alias.scss'
register_asset 'stylesheets/desktop/discourse-staff-alias.scss', :desktop
register_asset 'stylesheets/mobile/discourse-staff-alias.scss', :mobile

enabled_site_setting :discourse_staff_alias_enabled

PLUGIN_NAME ||= 'DiscourseStaffAlias'

load File.expand_path('lib/discourse-staff-alias/engine.rb', __dir__)

after_initialize do
  # https://github.com/discourse/discourse/blob/master/lib/plugin/instance.rb
end
