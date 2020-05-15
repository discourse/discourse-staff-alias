# frozen_string_literal: true

class RemoveForeignKeysOnUsers < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :discourse_staff_alias_users_posts_links, :users, column: :user_id
    remove_foreign_key :discourse_staff_alias_users_post_revisions_links, :users, column: :user_id
  end
end
