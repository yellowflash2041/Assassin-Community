class NotificationsController < ApplicationController
  # No authorization required because we provide authentication on notifications page
  def index
    return unless user_signed_in?

    @notifications_index = true
    @user = user_to_view

    @initial_page_size = 8

    # NOTE: this controller is using offset based pagination by assuming that
    # the id of the last notification also corresponds to the newest `notified_at`
    # this might not be forever true but it's good enough for now
    if params[:offset]
      num = 30
      notified_at_offset = Notification.find(params[:offset])&.notified_at
    else
      num = @initial_page_size
    end

    @notifications = if (params[:org_id].present? || params[:filter] == "org") && allowed_user?
                       organization_notifications
                     elsif params[:org_id].blank? && params[:filter].present?
                       filtered_notifications
                     else
                       @user.notifications
                     end

    @notifications = @notifications.includes(:notifiable).without_past_aggregations.order(notified_at: :desc)

    # if offset based pagination is invoked by the frontend code, we filter out all earlier ones
    @notifications = @notifications.where("notified_at < ?", notified_at_offset) if notified_at_offset

    @notifications = NotificationDecorator.decorate_collection(@notifications.limit(num))

    @last_user_reaction = @user.reactions.last&.id
    @last_user_comment = @user.comments.last&.id

    @organizations = @user.member_organizations if @user.organizations

    # The first call, the one coming from the browser URL bar will render the "index" view, which renders
    # the first few notifications. After that the JS frontend code (see `initNotification.js`)
    # will call this action again by sending the offset id for the last known notifications, the result
    # will be the partial rendering of only the list of notifications that will be attached to the DOM by JS
    render partial: "notifications_list" if notified_at_offset
  end

  private

  def user_to_view
    if params[:username] && current_user.admin?
      User.find_by(username: params[:username])
    else
      current_user
    end
  end

  def filtered_notifications
    if params[:filter].to_s.casecmp("posts").zero?
      @user.notifications.for_published_articles
    elsif params[:filter].to_s.casecmp("comments").zero?
      @user.notifications.for_comments.or(@user.notifications.for_mentions)
    end
  end

  def organization_notifications
    org_id = params[:org_id]

    if params[:filter].to_s.casecmp("comments").zero?
      Notification.for_organization_comments(org_id).or(Notification.for_organization_mentions(org_id))
    else
      Notification.for_organization(org_id)
    end
  end

  def allowed_user?
    @user.organization_id == params[:org_id] || @user.admin?
  end
end
