class ImageUploadsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized
  rescue_from Errno::ENAMETOOLONG, with: :log_image_data_to_datadog

  def create
    authorize :image_upload

    begin
      rate_limiter = rate_limit!

      raise CarrierWave::IntegrityError if params[:image].blank?

      unless valid_filename?
        respond_to do |format|
          format.json { render json: { error: FILENAME_TOO_LONG_MESSAGE }, status: :unprocessable_entity }
        end
        return
      end

      uploaders = upload_images(params[:image], rate_limiter)
    rescue RateLimitChecker::UploadRateLimitReached => e
      respond_to do |format|
        message = "Upload limit reached! Retry after #{e.retry_after} seconds."
        format.json do
          response.headers["Retry-After"] = e.retry_after
          render json: { error: message }, status: :too_many_requests
        end
      end
      return
    rescue CarrierWave::IntegrityError => e # client error
      respond_to do |format|
        format.json do
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end
      return
    rescue CarrierWave::ProcessingError # server error
      respond_to do |format|
        format.json do
          render json: { error: "A server error has occurred!" }, status: :server_error
        end
      end
      return
    end

    cloudinary_link(uploaders)
  end

  def cloudinary_link(uploaders)
    links = if params[:wrap_cloudinary]
              [ApplicationController.helpers.cloud_cover_url(uploaders[0].url)]
            else
              uploaders.map(&:url)
            end
    respond_to do |format|
      format.json { render json: { links: links }, status: :ok }
    end
  end

  private

  def rate_limit!
    RateLimitChecker.new(current_user).tap do |rate_limiter|
      if rate_limiter.limit_by_action(:image_upload)
        retry_after = RateLimitChecker::RETRY_AFTER[:image_upload]
        raise RateLimitChecker::UploadRateLimitReached, retry_after
      end
    end
  end

  def valid_filename?
    images = Array.wrap(params.dig("image"))
    images.none? { |image| long_filename?(image) }
  end

  def upload_images(images, rate_limiter)
    Array.wrap(images).map do |image|
      ArticleImageUploader.new.tap do |uploader|
        uploader.store!(image)
        rate_limiter.track_image_uploads
      end
    end
  end
end
