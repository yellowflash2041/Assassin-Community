module ClassifiedListingsToolkit
  extend ActiveSupport::Concern

  def unpublish_listing
    @classified_listing.published = false
    @classified_listing.save
    @classified_listing.remove_from_index!
  end

  def publish_listing
    @classified_listing.published = true
    @classified_listing.save
    @classified_listing.index!
  end

  def update_listing_details
    @classified_listing.title = listing_params[:title] if listing_params[:title]
    @classified_listing.body_markdown = listing_params[:body_markdown] if listing_params[:body_markdown]
    @classified_listing.tag_list = listing_params[:tag_list] if listing_params[:tag_list]
    @classified_listing.category = listing_params[:category] if listing_params[:category]
    @classified_listing.contact_via_connect = listing_params[:contact_via_connect] if listing_params[:contact_via_connect]
    @classified_listing.save
  end

  def bump_listing
    @classified_listing.bumped_at = Time.current
    @classified_listing.save
  end

  def clear_listings_cache
    cb = CacheBuster.new
    cb.bust("/listings")
    cb.bust("/listings?i=i")
    cb.bust("/listings/#{@classified_listing.category}/#{@classified_listing.slug}")
    cb.bust("/listings/#{@classified_listing.category}/#{@classified_listing.slug}?i=i")
    cb.bust("/listings/#{@classified_listing.category}")
  end
end
