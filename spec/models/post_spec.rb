# frozen_string_literal: true

require 'rails_helper'

describe Post do
  fab!(:user) { Fabricate(:user) }
  fab!(:post) { Fabricate(:post) }

  it 'cleans up users_posts_links association on destroy' do
    link = ::DiscourseStaffAlias::UsersPostsLink.create!(
      user: user,
      post: post
    )

    expect(post.reload.users_posts_links).to contain_exactly(link)

    post.destroy!

    expect(DiscourseStaffAlias::UsersPostsLink.exists?(post_id: post.id)).to eq(false)
  end
end
