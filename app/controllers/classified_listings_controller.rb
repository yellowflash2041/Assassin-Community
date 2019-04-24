class ClassifiedListingsController < ApplicationController
  before_action :set_classified_listing, only: [:show, :edit, :update]
  before_action :set_cache_control_headers, only: %i[index]
  after_action :verify_authorized, only: %i[edit update]
  before_action :authenticate_user!, only: %i[edit update new]

  def index
    if params[:category].blank?
      @classified_listings = ClassifiedListing.where(published: true).order("bumped_at DESC").limit(12)
    else
      @classified_listings = []
    end
    set_surrogate_key_header "classified-listings-#{params[:category]}"
  end

  def new
    @classified_listing = ClassifiedListing.new
    @credits = current_user.credits.where(spent: false)
  end

  def edit
    authorize @classified_listing
    @credits = current_user.credits.where(spent: false)
  end

  def create
    @classified_listing = ClassifiedListing.new(classified_listing_params)
    @classified_listing.user_id = current_user.id
    number_of_credits_needed = ClassifiedListing.cost_by_category(@classified_listing.category)
    available_credits = current_user.credits.where(spent: false)
    if available_credits.size >= number_of_credits_needed
      @classified_listing.bumped_at = Time.current
      @classified_listing.published = true
      @classified_listing.organization_id = current_user.organization_id if @classified_listing.post_as_organization.to_i == 1
      if @classified_listing.save
        CacheBuster.new.bust("/listings")
        CacheBuster.new.bust("/listings?i=i")
        available_credits.limit(number_of_credits_needed).update_all(spent: true)
        redirect_to "/listings"
      else
        @credits = current_user.credits.where(spent: false)
        render :new
      end
    else
      redirect_to "/credits"
    end
  end

  def update
    authorize @classified_listing
    available_credits = current_user.credits.where(spent: false)
    number_of_credits_needed = ClassifiedListing.cost_by_category(@classified_listing.category) # Bumping
    if params[:classified_listing][:action] == "bump"
      @classified_listing.bumped_at = Time.current
      if available_credits.size >= number_of_credits_needed
        @classified_listing.save
        available_credits.limit(number_of_credits_needed).update_all(spent: true)
      end
    elsif params[:classified_listing][:action] == "unpublish"
      @classified_listing.published = false
      @classified_listing.save
      @classified_listing.remove_from_index!
    elsif params[:classified_listing][:body_markdown].present? && @classified_listing.bumped_at > 24.hours.ago
      @classified_listing.body_markdown = params[:classified_listing][:body_markdown]
      @classified_listing.save
    end
    redirect_to "/listings"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_classified_listing
      @classified_listing = ClassifiedListing.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def classified_listing_params
      accessible = %i[title body_markdown category tag_list contact_via_connect post_as_organization action]
      params.require(:classified_listing).permit(accessible)
    end
end
