module Moderator
  class DeleteUser < ManageActivityAndRoles
    attr_reader :user, :admin, :user_params

    def self.call(admin:, user:, user_params:)
      if user_params[:ghostify] == "true"
        new(user: user, admin: admin, user_params: user_params).ghostify
      else
        Users::DeleteWorker.perform_async(user.id, true)
      end
    end

    def initialize(admin:, user:, user_params:)
      @user = user
      @admin = admin
      @user_params = user_params
    end

    def ghostify
      @ghost = User.find_by(username: "ghost")
      reassign_articles
      reassign_comments
      delete_user
      CacheBuster.bust("/ghost")
    end

    private

    def delete_user
      Users::DeleteWorker.new.perform(user.id, true)
    end

    def reassign_comments
      return unless user.comments.any?

      user.comments.find_each do |comment|
        comment.update(user_id: @ghost.id)
      end
      @ghost.touch(:last_comment_at)
    end

    def reassign_articles
      return unless user.articles.any?

      # preload associations that are going to be used during indexing
      user.articles.preload(:organization, :tag_taggings, :tags).find_each do |article|
        path = "/#{@ghost.username}/#{article.slug}"
        article.update_columns(user_id: @ghost.id, path: path)
        article.index_to_elasticsearch_inline
      end
    end
  end
end
