module Users
  module DeleteArticles
    module_function

    def call(user, cache_buster = CacheBuster)
      return if user.articles.blank?

      virtual_articles = user.articles.map { |article| Article.new(article.attributes) }
      user.articles.find_each do |article|
        remove_reactions(article)
        article.buffer_updates.delete_all
        article.comments.includes(:user).find_each do |comment|
          comment.reactions.delete_all
          cache_buster.bust_comment(comment.commentable)
          cache_buster.bust_user(comment.user)
          comment.remove_from_elasticsearch
          comment.delete
        end
        article.remove_from_elasticsearch
        article.delete
        article.purge
      end
      virtual_articles.each do |article|
        cache_buster.bust_article(article)
      end
    end

    def remove_reactions(article)
      readinglist_ids = article.reactions.readinglist.pluck(:id)
      article.reactions.delete_all
      readinglist_ids.each do |id|
        Search::RemoveFromIndexWorker.perform_async("Search::Reaction", id)
      end
    end
  end
end
