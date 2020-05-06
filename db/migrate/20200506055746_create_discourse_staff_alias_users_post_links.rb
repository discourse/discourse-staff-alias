class CreateDiscourseStaffAliasUsersPostLinks < ActiveRecord::Migration[6.0]
  def change
    create_table :discourse_staff_alias_users_post_links do |t|
      t.integer :user_id, null: false
      t.integer :post_id, null: false
      t.integer :action, null: false
      t.timestamps
    end

    add_index :discourse_staff_alias_users_post_links, [:user_id, :post_id, :action], name: 'idx_user_id_post_id_action'
    add_foreign_key :discourse_staff_alias_users_post_links, :users, column: :user_id
    add_foreign_key :discourse_staff_alias_users_post_links, :posts, column: :post_id
  end
end
