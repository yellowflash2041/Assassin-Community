class Internal::ClassifiedListingsController < Internal::ApplicationController
  layout "internal"

  def index
    @classified_listings = ClassifiedListing.page(params[:page]).order("bumped_at DESC").per(50)
    @classified_listings = @classified_listings.joins(:user).where("classified_listings.title ILIKE :search OR users.username ILIKE :search", search: "%#{params[:search]}%") if params[:search].present?
  end

  def edit
    @classified_listing = ClassifiedListing.find(params[:id])
  end

  def update
    @classified_listing = ClassifiedListing.find(params[:id])
    @classified_listing.update!(listing_params)
    reindex_and_bust_cache
    flash[:success] = "Listing updated successfully"
    redirect_to "/internal/listings/#{@classified_listing.id}/edit"
  end

  def destroy
    @classified_listing = ClassifiedListing.find(params[:id])
    @classified_listing.destroy
    flash[:warning] = "'#{@classified_listing.title}' was destroyed successfully"
    redirect_to "/internal/listings"
  end

  private

  def listing_params
    allowed_params = %i[published body_markdown title category tag_list]
    params.require(:classified_listing).permit(allowed_params)
  end

  def reindex_and_bust_cache
    @classified_listing.index! if @classified_listing.published
    cb = CacheBuster.new
    cb.bust("/listings")
    cb.bust("/listings/#{@classified_listing.category}")
    cb.bust("/listings/#{@classified_listing.category}/#{@classified_listing.path}")
  end
end
