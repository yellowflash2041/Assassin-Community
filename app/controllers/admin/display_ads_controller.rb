module Admin
  class DisplayAdsController < Admin::ApplicationController
    layout "admin"

    def index
      @display_ads = DisplayAd.order(id: :desc)
        .joins(:organization)
        .includes([:organization])
        .page(params[:page]).per(50)

      return if params[:search].blank?

      @display_ads = @display_ads.where("organizations.name ILIKE :search", search: "%#{params[:search]}%")
    end

    def new
      @display_ad = DisplayAd.new
    end

    def edit
      @display_ad = DisplayAd.find(params[:id])
    end

    def create
      @display_ad = DisplayAd.new(display_ad_params)

      if @display_ad.save
        flash[:success] = "Display Ad has been created!"
        redirect_to admin_display_ads_path
      else
        flash[:danger] = @display_ad.errors_as_sentence
        render new_admin_display_ad_path
      end
    end

    def update
      @display_ad = DisplayAd.find(params[:id])

      if @display_ad.update(display_ad_params)
        flash[:success] = "Display Ad has been updated!"
        redirect_to admin_display_ads_path
      else
        flash[:danger] = @display_ad.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @display_ad = DisplayAd.find(params[:id])

      if @display_ad.destroy
        flash[:success] = "Display Ad has been deleted!"
        redirect_to admin_display_ads_path
      else
        flash[:danger] = "Something went wrong with deleting the Display Ad."
        render :edit
      end
    end

    private

    def display_ad_params
      params.permit(:organization_id, :body_markdown, :placement_area, :published, :approved)
    end

    def authorize_admin
      authorize DisplayAd, :access?, policy_class: InternalPolicy
    end
  end
end
