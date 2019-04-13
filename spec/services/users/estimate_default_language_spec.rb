require "rails_helper"

RSpec.describe Users::EstimateDefaultLanguage, type: :service do
  it "estimates default language when the email is nil" do
    no_email_user = create(:user, email: nil)
    described_class.call(no_email_user)
    no_email_user.reload
    expect(no_email_user.estimated_default_language).to eq(nil)
  end

  it "estimates default language to be nil" do
    user = create(:user)
    described_class.call(user)
    expect(user.estimated_default_language).to eq(nil)
  end

  it "estimates default language to be japan with jp email" do
    user = create(:user, email: "anna@example.jp")
    described_class.call(user)
    expect(user.estimated_default_language).to eq("ja")
  end

  it "estimates default language based on identity data dump" do
    user = create(:user)
    create(:identity, provider: :twitter, user: user, auth_data_dump: { "extra" => { "raw_info" => { "lang" => "it" } } })
    described_class.call(user)
    user.reload
    expect(user.estimated_default_language).to eq("it")
  end

  it "sets preferred_languages_array" do
    user = create(:user, email: "annaboo@example.jp")
    described_class.call(user)
    user.reload
    expect(user.decorate.preferred_languages_array).to include("ja")
  end
end
