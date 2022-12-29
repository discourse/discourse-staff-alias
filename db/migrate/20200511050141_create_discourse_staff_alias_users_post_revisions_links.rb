# frozen_string_literal: true

class CreateDiscourseStaffAliasUsersPostRevisionsLinks < ActiveRecord::Migration[6.0]
  def change
    create_table :discourse_staff_alias_users_post_revisions_links do |t|
      t.bigint :user_id, null: false
      t.bigint :post_revision_id, null: false
      t.timestamps
    end

    add_index(
      :discourse_staff_alias_users_post_revisions_links,
      %i[user_id post_revision_id],
      name: "idx_user_id_post_revision_id",
      unique: true,
    )

    add_foreign_key :discourse_staff_alias_users_post_revisions_links, :users, column: :user_id
    add_foreign_key :discourse_staff_alias_users_post_revisions_links,
                    :post_revisions,
                    column: :post_revision_id
  end
end
