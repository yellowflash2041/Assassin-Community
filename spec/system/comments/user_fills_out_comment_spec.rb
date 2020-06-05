require "rails_helper"

RSpec.describe "Creating Comment", type: :system, js: true do
  include_context "with runkit_tag"

  let(:user) { create(:user) }
  let(:raw_comment) { Faker::Lorem.paragraph }
  let(:runkit_comment) { compose_runkit_comment "comment 1" }
  let(:runkit_comment2) { compose_runkit_comment "comment 2" }

  # the article should be created before signing in
  let!(:article) { create(:article, user_id: user.id, show_comments: true) }

  before do
    sign_in user
  end

  it "User fills out comment box normally" do
    # TODO: Add Percy snapshot?
    visit article.path.to_s
    wait_for_javascript

    fill_in "text-area", with: raw_comment
    click_button("SUBMIT")
    expect(page).to have_text(raw_comment)
  end

  context "with Runkit tags" do
    before do
      visit article.path.to_s

      wait_for_javascript
    end

    it "Users fills out comment box with a Runkit tag" do
      fill_in "text-area", with: runkit_comment
      click_button("SUBMIT")

      expect_runkit_tag_to_be_active
    end

    it "Users fills out comment box 2 Runkit tags" do
      fill_in "text-area", with: runkit_comment
      click_button("SUBMIT")

      expect_runkit_tag_to_be_active

      fill_in "text-area", with: runkit_comment2
      click_button("SUBMIT")

      expect_runkit_tag_to_be_active(count: 2)
    end

    it "User fill out comment box with a Runkit tag, then clicks preview" do
      fill_in "text-area", with: runkit_comment
      click_button("PREVIEW")

      expect_runkit_tag_to_be_active
    end
  end

  it "User fill out comment box then click previews and submit" do
    visit article.path.to_s
    wait_for_javascript

    fill_in "text-area", with: raw_comment
    click_button("PREVIEW")
    expect(page).to have_text(raw_comment)
    expect(page).to have_text("MARKDOWN")
    click_button("MARKDOWN")
    expect(page).to have_text("PREVIEW")
    click_button("SUBMIT")
    expect(page).to have_text(raw_comment)
  end

  it "User replies to a comment" do
    create(:comment, commentable: article, user_id: user.id)
    visit article.path.to_s

    wait_for_javascript

    find(".toggle-reply-form").click
    find(:xpath, "//div[@class='actions']/form[@class='new_comment']/textarea").set(raw_comment)
    find(:xpath, "//div[contains(@class, 'reply-actions')]/input[@name='commit']").click
    expect(page).to have_text(raw_comment)
  end

  # This is basically a black box test for
  # ./app/javascripts/packs/validateFileInputs.js
  # which is logic to validate file size and format when uploading via a form.
  it "User attaches a valid image" do
    visit article.path.to_s

    attach_file(
      "image-upload-main",
      Rails.root.join("app/assets/images/apple-icon.png"),
      visible: :hidden,
    )

    expect(page).to have_no_css("div.file-upload-error")
  end

  it "User attaches a large image", percy: true do
    visit article.path.to_s

    reduce_max_file_size = 'document.querySelector("#image-upload-main").setAttribute("data-max-file-size-mb", "0")'
    page.execute_script(reduce_max_file_size)
    expect(page).to have_selector('input[data-max-file-size-mb="0"]', visible: :hidden)

    attach_file(
      "image-upload-main",
      Rails.root.join("app/assets/images/onboarding-background.png"),
      visible: :hidden,
    )

    Percy.snapshot(page, name: "Image: upload error")

    expect(page).to have_css("div.file-upload-error")
    expect(page).to have_css(
      "div.file-upload-error",
      text: "File size too large (0.07 MB). The limit is 0 MB.",
    )
  end

  it "User attaches an invalid file type" do
    visit article.path.to_s

    allow_only_videos = 'document.querySelector("#image-upload-main").setAttribute("data-permitted-file-types", "[\"video\"]")'
    page.execute_script(allow_only_videos)
    expect(page).to have_selector('input[data-permitted-file-types="[\"video\"]"]', visible: :hidden)

    attach_file(
      "image-upload-main",
      Rails.root.join("app/assets/images/apple-icon.png"),
      visible: :hidden,
    )

    expect(page).to have_css("div.file-upload-error")
    expect(page).to have_css(
      "div.file-upload-error",
      text: "Invalid file format (image). Only video files are permitted.",
    )
  end

  it "User attaches a file with too long of a name" do
    visit article.path.to_s

    limit_file_name_length = 'document.querySelector("#image-upload-main").setAttribute("data-max-file-name-length", "5")'
    page.execute_script(limit_file_name_length)
    expect(page).to have_selector('input[data-max-file-name-length="5"]', visible: :hidden)

    attach_file(
      "image-upload-main",
      Rails.root.join("app/assets/images/apple-icon.png"),
      visible: :hidden,
    )

    expect(page).to have_css("div.file-upload-error")
    expect(page).to have_css(
      "div.file-upload-error",
      text: "File name is too long. It can't be longer than 5 characters.",
    )
  end
end
