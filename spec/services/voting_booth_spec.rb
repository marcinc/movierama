require 'rails_helper'

RSpec.describe VotingBooth do
  include ActiveJob::TestHelper

  subject(:voting_booth) { VotingBooth.new(user, movie) }

  let(:user) { User.create(uid: 123, name: 'Foo Bar', email: 'foo.bar@example.com') }
  let(:movie) { Movie.create(title: 'Reservoir Dogs') }

  let(:likers) { Ohm::MutableSet.new(User, "User", "Movie:1:likers") }
  let(:haters) { Ohm::MutableSet.new(User, "User", "Movie:1:haters") }

  before do  
    allow(movie).to receive(:likers) { likers }
    allow(movie).to receive(:haters) { haters }
  end

  describe '#vote' do
    it 'persists user vote' do
      expect(voting_booth).to receive(:unvote)
      expect(likers).to receive(:add).with(user)
      voting_booth.vote(:like)
    end

    it 'updates counts' do
      expect(voting_booth).to receive(:_update_counts).twice
      voting_booth.vote(:like)
    end

    it 'notifies movie submitter about a new vote' do
      expect(voting_booth).to receive(:_notify_user).with(:like)
      voting_booth.vote(:like)
    end
  end

  describe '#unvote' do
    it 'removes user from likers and haters' do
      expect(likers).to receive(:delete).with(user)
      expect(haters).to receive(:delete).with(user)
      voting_booth.unvote
    end

    it 'updates counts' do
      expect(voting_booth).to receive(:_update_counts)
      voting_booth.unvote
    end
  end

  describe 'private methods' do
    describe '#_update_counts' do
      it 'updates likers / haters counts for a movie' do
        expect(movie).to receive(:update).with(
          liker_count: anything,
          hater_count: anything
        )
        voting_booth.send(:_update_counts)
      end
    end

    describe '#_notify_user' do
      before do
        ActiveJob::Base.queue_adapter = :test
      end

      it 'enqueues an email notification for async delivery' do
        expect do
          voting_booth.send(:_notify_user, :like)
        end.to change { enqueued_jobs.count }.from(0).to(1)

        j = enqueued_jobs.first
        expect(j[:job]).to eq ActionMailer::DeliveryJob
        expect(j[:queue]).to eq 'mailers'
        expect(j[:args]).to match ["UserMailer", "vote_cast_notification", "deliver_now", "1", "1", "like"]
      end
    end
  end

end
