# frozen_string_literal: true

require 'rails_helper'

describe PostRevision do
  fab!(:user) { Fabricate(:user) }
  fab!(:post_revision) { Fabricate(:post_revision) }

  it 'cleans up users_posts_links association on destroy' do
    link = ::DiscourseStaffAlias::UsersPostRevisionsLink.create!(
      user: user,
      post_revision: post_revision
    )

    expect(post_revision.reload.users_post_revisions_links).to contain_exactly(link)

    post_revision.destroy!

    expect(DiscourseStaffAlias::UsersPostRevisionsLink.exists?(
      post_revision_id: post_revision.id
    )).to eq(false)
  end

  it 'allows non human users to edit posts made by the staff alias user' do
    SiteSetting.set(:staff_alias_username, 'staff_alias_user')
    SiteSetting.set(:staff_alias_enabled, true)

    post = Fabricate(:post, user: User.find(SiteSetting.get(:staff_alias_user_id)))
    post_revision = Fabricate.build(:post_revision, post: post, user: Discourse.system_user)

    expect(post_revision.valid?).to eq(true)
  end
end
