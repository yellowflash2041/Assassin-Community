require "rails_helper"
require "date"

RSpec.describe "Admin creates new event", type: :system do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
    visit "/internal/events"
  end

  def select_date_and_time(year, month, date, hour, min, field_name)
    select year, from: "event[#{field_name}(1i)]"
    select month, from: "event[#{field_name}(2i)]"
    select date, from: "event[#{field_name}(3i)]"
    select hour, from: "event[#{field_name}(4i)]"
    select min, from: "event[#{field_name}(5i)]"
  end

  def create_and_publish_event
    fill_in("Title", with: "Workshop Title")
    select_date_and_time(Time.current.year.to_s, "December", "30", "15", "30", "starts_at")
    select_date_and_time(Time.current.year.to_s, "December", "30", "16", "30", "ends_at")
    check("event[published]")
    click_button("Create Event")
  end

  it "loads /internal/events" do
    expect(page).to have_content("Create New Event")
  end

  # TODO: Uncomment this spec when we decide to use percy again
  xit "renders the page", js: true, percy: true do
    Percy.snapshot(page, name: "Admin: /internal/events shows published events")
  end

  it "loads published events on /events" do
    create_and_publish_event
    visit "/events"

    expect(page).to have_content("Workshop Title")
  end
end
