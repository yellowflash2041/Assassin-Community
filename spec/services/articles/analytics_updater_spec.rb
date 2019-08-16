require "rails_helper"

RSpec.describe Articles::AnalyticsUpdater do
  let(:stubbed_ga) { double }
  let(:user) { build(:user) }

  before do
    srand(2) # disabling #occasionally_force_fetch
    allow(Notification).to receive(:send_milestone_notification)
    allow(GoogleAnalytics).to receive(:new).and_return(stubbed_ga)
  end

  describe "#call" do
    context "when positive_reactions_count is LOWER than previous_positive_reactions_count" do
      it "does nothing " do
        build_stubbed(:article, positive_reactions_count: 2, previous_positive_reactions_count: 3, user: user)
        described_class.call(user)
        expect(Notification).not_to have_received(:send_milestone_notification)
      end
    end

    context "when positive_reactions_count is HIGHER than previous_positive_reactions_count" do
      let(:article) { build_stubbed(:article, positive_reactions_count: 5, previous_positive_reactions_count: 3, user: user) }
      let(:pageview) { {} }
      let(:counts) { 1000 }
      let(:user_articles) { double }
      let(:analytics_updater_service) { described_class.new(user) }

      before do
        pageview[article.id] = counts
        allow(stubbed_ga).to receive(:get_pageviews).and_return(pageview)
        allow(article).to receive(:update_columns)
        allow(analytics_updater_service).to receive(:published_articles).and_return([article])
        analytics_updater_service.call
      end

      it "sends send_milestone_notification for Reaction and View" do
        %w[Reaction View].each do |type|
          expect(Notification).to have_received(:send_milestone_notification).with(type: type, article_id: article.id)
        end
      end

      it "updates appropriate column" do
        expect(article).to have_received(:update_columns).with(previous_positive_reactions_count: article.positive_reactions_count)
        expect(article).to have_received(:update_columns).with(page_views_count: counts)
      end
    end
  end
end
