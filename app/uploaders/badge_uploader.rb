class BadgeUploader < CarrierWave::Uploader::Base
  include CarrierWave::BombShelter

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
    %w(jpg jpeg gif png)
  end
end
