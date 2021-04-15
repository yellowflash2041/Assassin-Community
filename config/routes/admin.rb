scope :content_manager do
  resources :articles, only: %i[index show update]
  resources :badges, only: %i[index edit update new create]
  resources :badge_achievements, only: %i[index destroy]
  get "/badge_achievements/award_badges", to: "badge_achievements#award"
  post "/badge_achievements/award_badges", to: "badge_achievements#award_badges"
  resources :comments, only: [:index]
  resources :organizations, only: %i[index show] do
    member do
      patch "update_org_credits"
    end
  end
  resources :podcasts, only: %i[index edit update destroy] do
    member do
      post :fetch
      post :add_owner
    end
  end
  resources :tags, only: %i[index new create update edit] do
    resource :moderator, only: %i[create destroy], module: "tags"
  end
end

scope :customization do
  resource :config
  resources :display_ads, only: %i[index edit update new create destroy]
  resources :html_variants, only: %i[index edit update new create show destroy]
  resources :navigation_links, only: %i[index update create destroy]
  resources :pages, only: %i[index new create edit update destroy]

  # NOTE: @citizen428 The next two resources have a temporary constraint
  # while profile generalization is still WIP
  constraints(->(_request) { FeatureFlag.enabled?(:profile_admin) }) do
    resources :profile_field_groups, only: %i[update create destroy]
    resources :profile_fields, only: %i[index update create destroy]
  end
end

scope :moderation do
  resources :feedback_messages, only: %i[index show]
  resources :reports, only: %i[index show], controller: "feedback_messages" do
    collection do
      post "send_email"
      post "create_note"
      post "save_status"
    end
  end
  resources :mods, only: %i[index update]
  resources :moderator_actions, only: %i[index]
  resources :privileged_reactions, only: %i[index]
end

scope :advanced do
  resources :broadcasts
  resources :response_templates, only: %i[index new edit create update destroy]
  resources :secrets, only: %i[index]
  put "secrets", to: "secrets#update"
  resources :sponsorships, only: %i[index edit update new create destroy]
  resources :tools, only: %i[index create] do
    collection do
      post "bust_cache"
    end
  end
  resources :webhook_endpoints, only: :index

  # We do not expose the Data Update Scripts to all Forems by default.
  constraints(->(_request) { FeatureFlag.enabled?(:data_update_scripts) }) do
    resources :data_update_scripts, only: %i[index show] do
      member do
        post :force_run
      end
    end
  end
end

scope :apps do
  resources :chat_channels, only: %i[index create update destroy] do
    member do
      delete :remove_user
    end
  end
  resources :events, only: %i[index create update new edit]
  resources :listings, only: %i[index edit update destroy]
  resources :listing_categories, only: %i[index edit update new create
                                          destroy], path: "listings/categories"
  resources :welcome, only: %i[index create]
end
