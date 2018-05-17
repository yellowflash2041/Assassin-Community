FactoryBot.define do
  factory :organization do
    name               { Faker::Company.name }
    summary            { Faker::Hipster.paragraph(1)[0..150] }
    profile_image      { File.open("#{Rails.root}/app/assets/images/android-icon-36x36.png") }
    nav_image          { Faker::Avatar.image }
    url                { Faker::Internet.url }
    slug               { "org#{rand(10_000)}" }
    github_username    { "org#{rand(10_000)}" }
    twitter_username   { "org#{rand(10_000)}" }
    bg_color_hex       { Faker::Color.hex_color }
    text_color_hex     { Faker::Color.hex_color }
    proof              { Faker::Hipster.sentence }
  end
end
