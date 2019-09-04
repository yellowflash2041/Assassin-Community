class ImageUploadsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def create
    authorize :image_upload

    rate_limiter = RateLimitChecker.new(current_user)

    begin
      raise RateLimitChecker::UploadRateLimitReached if rate_limiter.limit_by_action("image_upload")
      raise CarrierWave::IntegrityError if params[:image].blank?

      uploaders = upload_images(params[:image], rate_limiter)
    rescue RateLimitChecker::UploadRateLimitReached
      respond_to do |format|
        format.json { render json: { error: "Upload limit reached!" } }
      end
      return
    rescue CarrierWave::IntegrityError => e # client error
      respond_to do |format|
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
      return
    rescue CarrierWave::ProcessingError # server error
      respond_to do |format|
        format.json { render json: { error: "A server error has occurred!" }, status: :server_error }
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

  def upload_images(images, rate_limiter)
    Array.wrap(images).map do |image|
      ArticleImageUploader.new.tap do |uploader|
        uploader.store!(image)
        rate_limiter.track_image_uploads
      end
    end
  end
end
