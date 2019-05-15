module Notifications
  def self.user_data(user)
    {
      id: user.id,
      class: { name: "User" },
      name: user.name,
      username: user.username,
      path: user.path,
      profile_image_90: user.profile_image_90,
      comments_count: user.comments_count,
      created_at: user.created_at
    }
  end

  def self.comment_data(comment)
    {
      id: comment.id,
      class: { name: "Comment" },
      path: comment.path,
      processed_html: comment.processed_html,
      updated_at: comment.updated_at,
      commentable: {
        id: comment.commentable.id,
        title: comment.commentable.title,
        path: comment.commentable.path,
        class: {
          name: comment.commentable.class.name
        }
      }
    }
  end

  def self.article_data(article)
    {
      id: article.id,
      cached_tag_list_array: article.decorate.cached_tag_list_array,
      class: { name: "Article" },
      title: article.title,
      path: article.path,
      updated_at: article.updated_at
    }
  end

  def self.organization_data(organization)
    {
      id: organization.id,
      class: { name: "Organization" },
      name: organization.name,
      slug: organization.slug,
      path: organization.path,
      profile_image_90: organization.profile_image_90
    }
  end
end
