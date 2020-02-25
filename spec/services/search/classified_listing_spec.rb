require "rails_helper"

RSpec.describe Search::ClassifiedListing, type: :service, elasticsearch: true do
  describe "::index" do
    it "indexes a classified_listing to elasticsearch" do
      classified_listing = FactoryBot.create(:classified_listing)
      expect { described_class.find_document(classified_listing.id) }.to raise_error(Search::Errors::Transport::NotFound)
      described_class.index(classified_listing.id, classified_listing.serialized_search_hash)
      expect(described_class.find_document(classified_listing.id)).not_to be_nil
    end
  end

  describe "::find_document" do
    it "fetches a document for a given ID from elasticsearch" do
      classified_listing = FactoryBot.create(:classified_listing)
      described_class.index(classified_listing.id, classified_listing.serialized_search_hash)
      expect { described_class.find_document(classified_listing.id) }.not_to raise_error
    end
  end

  describe "::delete_document" do
    it "deletes a document for a given ID from elasticsearch" do
      classified_listing = FactoryBot.create(:classified_listing)
      classified_listing.index_to_elasticsearch_inline
      expect { described_class.find_document(classified_listing.id) }.not_to raise_error
      described_class.delete_document(classified_listing.id)
      expect { described_class.find_document(classified_listing.id) }.to raise_error(Search::Errors::Transport::NotFound)
    end
  end

  describe "::create_index" do
    it "creates an elasticsearch index with INDEX_NAME" do
      described_class.delete_index
      expect(SearchClient.indices.exists(index: described_class::INDEX_NAME)).to eq(false)
      described_class.create_index
      expect(SearchClient.indices.exists(index: described_class::INDEX_NAME)).to eq(true)
    end

    it "creates an elasticsearch index with name argument" do
      other_name = "random"
      expect(SearchClient.indices.exists(index: other_name)).to eq(false)
      described_class.create_index(index_name: other_name)
      expect(SearchClient.indices.exists(index: other_name)).to eq(true)

      # Have to cleanup index since it wont automatically be handled by our cluster class bc of the unexpected name
      described_class.delete_index(index_name: other_name)
    end
  end

  describe "::delete_index" do
    it "deletes an elasticsearch index with INDEX_NAME" do
      expect(SearchClient.indices.exists(index: described_class::INDEX_NAME)).to eq(true)
      described_class.delete_index
      expect(SearchClient.indices.exists(index: described_class::INDEX_NAME)).to eq(false)
    end

    it "deletes an elasticsearch index with name argument" do
      other_name = "random"
      described_class.create_index(index_name: other_name)
      expect(SearchClient.indices.exists(index: other_name)).to eq(true)

      described_class.delete_index(index_name: other_name)
      expect(SearchClient.indices.exists(index: other_name)).to eq(false)
    end
  end

  describe "::add_alias" do
    it "adds alias INDEX_ALIAS to elasticsearch index with INDEX_NAME" do
      SearchClient.indices.delete_alias(index: described_class::INDEX_NAME, name: described_class::INDEX_ALIAS)
      expect(SearchClient.indices.exists(index: described_class::INDEX_ALIAS)).to eq(false)
      described_class.add_alias
      expect(SearchClient.indices.exists(index: described_class::INDEX_ALIAS)).to eq(true)
    end

    it "adds custom alias to elasticsearch index with INDEX_NAME" do
      other_alias = "random"
      expect(SearchClient.indices.exists(index: other_alias)).to eq(false)
      described_class.add_alias(index_name: described_class::INDEX_NAME, index_alias: other_alias)
      expect(SearchClient.indices.exists(index: other_alias)).to eq(true)
    end
  end

  describe "::update_mappings" do
    it "updates index mappings for classified_listing index", :aggregate_failures do
      other_name = "random"
      described_class.create_index(index_name: other_name)
      initial_mapping = SearchClient.indices.get_mapping(index: other_name).dig(other_name, "mappings")
      expect(initial_mapping).to be_empty

      # This might look a little strange...it's because es_mapping_keys returns
      # certain fields like copy_to as an Array and our mappings don't have it
      # in that format. As a result, we're just comparing keys instead.
      described_class.update_mappings(index_alias: other_name)
      es_mapping_keys = SearchClient.indices.get_mapping(index: other_name).dig(other_name, "mappings", "properties").symbolize_keys.keys
      mapping_keys = described_class::MAPPINGS.dig(:properties).keys

      expect(mapping_keys).to match_array(es_mapping_keys)

      # Have to cleanup index since it wont automatically be handled by our cluster class bc of the unexpected name
      described_class.delete_index(index_name: other_name)
    end
  end
end
