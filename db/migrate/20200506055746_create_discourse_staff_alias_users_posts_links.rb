# frozen_string_literal: true

class CreateDiscourseStaffAliasUsersPostsLinks < ActiveRecord::Migration[6.0]
  def change
    create_table :discourse_staff_alias_users_posts_links do |t|
      t.bigint :user_id, null: false
      t.bigint :post_id, null: false
      t.timestamps
    end

    add_index :discourse_staff_alias_users_posts_links,
              %i[user_id post_id],
              name: "idx_user_id_post_id",
              unique: true
    add_foreign_key :discourse_staff_alias_users_posts_links, :users, column: :user_id
    add_foreign_key :discourse_staff_alias_users_posts_links, :posts, column: :post_id
  end
end
