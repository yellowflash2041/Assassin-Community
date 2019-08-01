class DisplayAdEventsController < ApplicationController
  # No policy needed. All views are for all users
  def create
    # Only tracking for logged in users at the moment
    display_ad_event_create_params = display_ad_event_params.merge(user_id: current_user.id)
    @display_ad_event = DisplayAdEvent.create(display_ad_event_create_params)

    update_display_ads_data

    head :ok
  end

  private

  def update_display_ads_data
    return if Rails.env.production? && rand(20) != 1 # We need to do this operation only once in a while.

    @display_ad = DisplayAd.find(display_ad_event_params[:display_ad_id])
    num_impressions = @display_ad.display_ad_events.where(category: "impression").size
    num_clicks = @display_ad.display_ad_events.where(category: "click").size
    rate = num_clicks.to_f / num_impressions

    @display_ad.
      update_columns(success_rate: rate, clicks_count: num_clicks, impressions_count: num_impressions)
  end

  def display_ad_event_params
    params.require(:display_ad_event).permit(%i[context_type category display_ad_id])
  end
end
