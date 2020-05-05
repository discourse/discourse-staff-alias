class CreateUserAliases < ActiveRecord::Migration[6.0]
  def change
    create_table :discourse_staff_alias_user_aliases do |t|
      t.integer :user_id, null: false
      t.integer :alias_user_id, null: false
      t.timestamps
    end

    add_foreign_key :discourse_staff_alias_user_aliases, :users, on_delete: :cascade
    add_foreign_key :discourse_staff_alias_user_aliases, :users, on_delete: :cascade, column: :alias_user_id
    add_index :discourse_staff_alias_user_aliases, [:user_id, :alias_user_id], name: 'idx_user_id_alias_user_id', unique: true
  end
end
