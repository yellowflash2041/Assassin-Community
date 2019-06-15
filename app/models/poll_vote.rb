class PollVote < ApplicationRecord
  belongs_to :user
  belongs_to :poll_option
  belongs_to :poll

  counter_culture :poll_option
  counter_culture :poll

  validates :poll_id, presence: true, presence: true, uniqueness: { scope: :user_id } # In the future we'll remove this constraint if/when we allow multi-answer polls
  validates :poll_option_id, presence: true, uniqueness: { scope: :user_id }
  validate :one_vote_per_poll_per_user

  after_save :touch_poll_votes_count
  after_destroy :touch_poll_votes_count

  def poll
    poll_option.poll
  end

  private

  def one_vote_per_poll_per_user
    errors.add(:base, "cannot vote more than once in one poll") if poll.poll_votes.where(user_id: user_id).any? || poll.poll_skips.where(user_id: user_id).any?
  end

  def touch_poll_votes_count
    poll.update_column(:poll_votes_count, poll.poll_votes.size)
    poll_option.update_column(:poll_votes_count, poll_option.poll_votes.size)
  end
end
