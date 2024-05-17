# frozen_string_literal: true

module DiscourseStaffAlias
  module PostExtension
    extend ActiveSupport::Concern

    prepended do
      has_many :users_posts_links,
               class_name: "DiscourseStaffAlias::UsersPostsLink",
               dependent: :delete_all
    end
  end
end
