class UserFollowSuggester

  attr_accessor :user
  def initialize(user)
    @user = user
  end

  def suggestions
    user_ids = tagged_article_user_ids
    if user.decorate.cached_followed_tag_names.any?
      group_1 = User.where(id: user_ids).
        order("reputation_modifier DESC").offset(rand(0..offset_number)).limit(15).to_a
      group_2 = User.where(id: user_ids).
        order("twitter_following_count DESC").offset(rand(0..offset_number)).limit(15).to_a
      group_3 = User.where(id: user_ids).
        order("articles_count DESC").limit(20).offset(rand(0..offset_number)).to_a
      group_4 = User.where(id: user_ids).
        order("comments_count DESC").limit(25).offset(rand(0..offset_number)).to_a
      group_5 = User.order("reputation_modifier DESC").offset(rand(0..offset_number)).limit(15).to_a
      group_6 = User.order("comments_count DESC").offset(rand(0..offset_number)).limit(15).to_a
      users = (group_1 + group_2 + group_3 + group_4 + group_5 + group_6 - [user]).
        uniq.shuffle.first(50)
    else
      group_1 = User.order("reputation_modifier DESC").offset(rand(0..offset_number)).limit(100).to_a
      group_2 = User.where("articles_count > ?", 5).
        order("twitter_following_count DESC").offset(rand(0..offset_number)).limit(100).to_a
      group_3 = User.order("comments_count DESC").offset(rand(0..offset_number)).limit(100).to_a
      users = (group_1 + group_2 + group_3 - [user]).
        uniq.shuffle.first(50)
    end
    users
  end

  def tagged_article_user_ids
    Article.
      tagged_with(user.decorate.cached_followed_tag_names, any: true).
      where(published: true).
      where("positive_reactions_count > ?", article).pluck(:user_id).
      each_with_object(Hash.new(0)) { |value, counts| counts[value] += 1 }.
      sort_by { |_key, value| value }.
      map { |arr| arr[0] }
  end

  def offset_number
    Rails.env.production? ? 250 : 0
  end

  def article
    Rails.env.production? ? 15 : 0
  end
end
