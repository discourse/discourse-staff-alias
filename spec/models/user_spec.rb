# frozen_string_literal: true

require 'rails_helper'

describe User do
  fab!(:user) { Fabricate(:user) }
  fab!(:post) { Fabricate(:post) }
  fab!(:post_revision) { Fabricate(:post_revision) }

  it 'does not clean up users_posts_links association on destroy' do
    link = ::DiscourseStaffAlias::UsersPostsLink.create!(
      user: user,
      post: post
    )

    expect(user.reload.users_posts_links).to contain_exactly(link)

    UserDestroyer.new(Discourse.system_user).destroy(user)

    expect(User.exists?(id: user.id)).to eq(false)
    expect(DiscourseStaffAlias::UsersPostsLink.exists?(user_id: user.id)).to eq(true)
  end

  it 'does not clean up users_post_revisions_links association on destroy' do
    link = ::DiscourseStaffAlias::UsersPostRevisionsLink.create!(
      user: user,
      post_revision: post_revision
    )

    expect(user.reload.users_post_revisions_links).to contain_exactly(link)

    UserDestroyer.new(Discourse.system_user).destroy(user)

    expect(User.exists?(id: user.id)).to eq(false)
    expect(DiscourseStaffAlias::UsersPostRevisionsLink.exists?(user_id: user.id)).to eq(true)
  end
end
