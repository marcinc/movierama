require 'rails_helper'

RSpec.describe UserMailer, :type => :mailer do
  include ActiveJob::TestHelper

  describe 'vote_cast_notification' do
    let(:voting_user) { User.create(name: 'Foo Bar', email: 'foo.bar@example.com') }
    let(:recipient) { User.create(name: 'Joe Doe', email: 'joe.doe@example.com') }
    let(:movie) { Movie.create(title: 'Fight Club', user: recipient) }
    let(:vote) { 'like' }

    let(:mail) { UserMailer.vote_cast_notification(voting_user.to_param, movie.to_param, vote) }

    it 'renders the subject' do
      expect(mail.subject).to eq I18n.t('user_mailer.vote_cast_notification.subject', title: movie.title)
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq [recipient.email]
    end

    it 'renders the sender email' do
      expect(mail.from).to eq ['movierama-noreply@example.com']
    end

    it 'assigns @vote' do
      expect(mail.body.encoded).to match(vote)
    end

    it 'assigns @recipient' do
      expect(mail.body.encoded).to match(recipient.name)
    end

    it 'assigns @movie' do
      expect(mail.body.encoded).to match(movie.title)
    end

    it 'assigns @voting_user' do
      expect(mail.body.encoded).to match(voting_user.name)
    end

    it 'delivers email asynchronously via activejob queue' do
      expect do
        UserMailer.vote_cast_notification(voting_user.to_param, movie.to_param, vote).deliver_later
      end.to change { enqueued_jobs.count }.from(0).to(1)

      expect do
        perform_enqueued_jobs do
          ActionMailer::DeliveryJob.perform_now(*enqueued_jobs.first[:args])
        end
      end.to change { UserMailer.deliveries.count }.from(0).to(1)
    end
  end

end
