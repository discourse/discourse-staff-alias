# frozen_string_literal: true

module DiscourseStaffAlias
  module PostRevisionExtension
    extend ActiveSupport::Concern

    prepended do
      has_many :users_post_revisions_links,
               class_name: "DiscourseStaffAlias::UsersPostRevisionsLink",
               dependent: :delete_all
    end
  end
end
