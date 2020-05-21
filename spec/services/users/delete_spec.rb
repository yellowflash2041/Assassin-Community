require "rails_helper"

RSpec.describe Users::Delete, type: :service do
  before { omniauth_mock_github_payload }

  let(:user) { create(:user, :with_identity, identities: ["github"]) }

  it "deletes user" do
    described_class.call(user)
    expect(User.find_by(id: user.id)).to be_nil
  end

  it "busts user profile page" do
    allow(CacheBuster).to receive(:bust)
    described_class.new(user).call
    expect(CacheBuster).to have_received(:bust).with("/#{user.username}")
  end

  it "deletes user's follows" do
    create(:follow, follower: user)
    create(:follow, followable: user)

    expect do
      described_class.call(user)
    end.to change(Follow, :count).by(-2)
  end

  it "deletes user's articles" do
    article = create(:article, user: user)
    described_class.call(user)
    expect(Article.find_by(id: article.id)).to be_nil
  end

  it "deletes the destroy token" do
    allow(Rails.cache).to receive(:delete).and_call_original
    described_class.call(user)
    expect(Rails.cache).to have_received(:delete).with("user-destroy-token-#{user.id}")
  end

  it "does not delete user's audit logs" do
    audit_log = create(:audit_log, user: user)

    expect do
      described_class.call(user)
    end.to change(AuditLog, :count).by(0)

    expect(audit_log.reload.user_id).to be(nil)
  end

  it "removes user from Elasticsearch" do
    sidekiq_perform_enqueued_jobs { user }
    expect(user.elasticsearch_doc).not_to be_nil
    sidekiq_perform_enqueued_jobs do
      described_class.call(user)
    end
    expect { user.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
  end

  it "removes articles from Elasticsearch" do
    article = create(:article, user: user)
    sidekiq_perform_enqueued_jobs
    expect(article.elasticsearch_doc).not_to be_nil
    sidekiq_perform_enqueued_jobs do
      described_class.call(user)
    end
    expect { article.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
  end

  it "removes reactions from Elasticsearch" do
    article = create(:article, user: user)
    reaction = create(:reaction, category: "readinglist", reactable: article)
    user_reaction = create(:reaction, user_id: user.id, category: "readinglist")
    sidekiq_perform_enqueued_jobs
    expect(reaction.elasticsearch_doc).not_to be_nil
    expect(user_reaction.elasticsearch_doc).not_to be_nil
    sidekiq_perform_enqueued_jobs do
      described_class.call(user)
    end
    expect { reaction.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    expect { user_reaction.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
  end

  it "deletes field tests memberships" do
    create(:field_test_membership, participant_id: user.id)

    expect do
      described_class.call(user)
    end.to change(FieldTest::Membership, :count).by(-1)
  end

  # check that all the associated records are being destroyed, except for those that are kept explicitly (kept_associations)
  describe "deleting associations" do
    let(:kept_association_names) do
      %i[
        affected_feedback_messages audit_logs created_podcasts notes
        offender_feedback_messages reporter_feedback_messages
      ]
    end
    let(:direct_associations) { User.reflect_on_all_associations.reject { |a| a.options.key?(:join_table) || a.options.key?(:through) } }
    let!(:user_associations) do
      create_associations(direct_associations.reject { |a| kept_association_names.include?(a.name) })
    end
    let!(:kept_associations) do
      create_associations(direct_associations.select { |a| kept_association_names.include?(a.name) })
    end

    def create_associations(names)
      associations = []

      names.each do |association|
        if user.public_send(association.name).present?
          associations.push(*user.public_send(association.name))
        else
          singular_name = ActiveSupport::Inflector.singularize(association.name)
          class_name = association.options[:class_name] || singular_name
          possible_factory_name = class_name.underscore.tr("/", "_")
          inverse_of = association.options[:inverse_of] || association.options[:as] || :user

          # as we can't be automatically sure that the other side of the relation
          # has defined a `has_one` relation we need to guard against third party
          # models that don't have them defined
          model = class_name.safe_constantize
          if model && !model.reflect_on_association(inverse_of)
            next
          end

          record = create(possible_factory_name, inverse_of => user)
          associations.push(record)
        end
      end

      associations
    end

    it "keeps the kept associations" do
      expect(kept_associations).not_to be_empty
      user.reload
      described_class.call(user)
      aggregate_failures "associations should exist" do
        kept_associations.each do |kept_association|
          expect { kept_association.reload }.not_to raise_error
        end
      end
    end

    it "deletes all the associations" do
      # making sure that the association records were actually created
      expect(user_associations).not_to be_empty
      user.reload
      described_class.call(user)
      aggregate_failures "associations should not exist" do
        user_associations.each do |user_association|
          expect { user_association.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  context "when cleaning up chat channels" do
    let_it_be(:other_user) { create(:user) }

    it "deletes the user's private chat channels" do
      chat_channel = ChatChannel.create_with_users(users: [user, other_user])
      described_class.call(user)
      expect(ChatChannel.find_by(id: chat_channel.id)).to be_nil
    end

    it "does not delete the user's open channels" do
      chat_channel = ChatChannel.create_with_users(users: [user, other_user], channel_type: "open")
      described_class.call(user)
      expect(ChatChannel.find_by(id: chat_channel.id)).not_to be_nil
    end
  end
end
