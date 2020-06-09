require "rails_helper"

RSpec.describe Metrics::RecordDataCountsWorker, type: :worker do
  default_logger = Rails.logger

  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    # Override the default Rails logger as these tests require the Timber logger.
    before do
      timber_logger = Timber::Logger.new(nil)
      Rails.logger = ActiveSupport::TaggedLogging.new(timber_logger)
    end

    after { Rails.logger = default_logger }

    it "calls count on each model" do
      allow(User).to receive(:count)
      allow(User).to receive(:estimated_count)
      described_class.new.perform
      expect(User).to have_received(:count)
      expect(User).not_to have_received(:estimated_count)
    end

    it "calls estimated_count if count times out" do
      allow(User).to receive(:count).and_raise(ActiveRecord::QueryCanceled)
      allow(User).to receive(:estimated_count)
      described_class.new.perform
      expect(User).to have_received(:count)
      expect(User).to have_received(:estimated_count)
    end

    it "logs estimated counts in Datadog" do
      allow(DatadogStatsClient).to receive(:gauge)
      described_class.new.perform

      expect(
        DatadogStatsClient,
      ).to have_received(:gauge).with("postgres.db_table_size", 0, tags: Array).at_least(1)
    end

    it "logs index counts in Datadog" do
      allow(DatadogStatsClient).to receive(:gauge)
      described_class.new.perform

      expect(
        DatadogStatsClient,
      ).to have_received(:gauge).with("elasticsearch.document_count", Integer, tags: Array).at_least(1)
    end
  end
end
