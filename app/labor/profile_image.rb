class ProfileImage
  attr_accessor :resource, :image_link, :backup_link

  def initialize(resource)
    @resource = resource
    @image_link = resource.profile_image_url
    @backup_link = "https://thepracticaldev.s3.amazonaws.com/i/99mvlsfu5tfj9m7ku25d.png"
  end

  def get(width = 120)
    CloudinaryHelper.cl_image_path(get_link,
                                   type: "fetch",
                                   crop: "fill",
                                   width: width,
                                   height: width,
                                   quality: "auto",
                                   flags: "progressive",
                                   fetch_format: "auto",
                                   sign_url: true)
  end

  def get_link
    image_link || backup_link
  end

  def get_external_link
    image_link ? "#{ENV['APP_PROTOCOL']}#{ENV['APP_DOMAIN']}#{image_link}" : backup_link
  end
end
