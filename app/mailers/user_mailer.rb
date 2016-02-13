class UserMailer < ActionMailer::Base 
  default from: 'movierama-noreply@example.com'

  def vote_cast_notification(user_id, movie_id, vote)
    @voting_user = User[user_id]
    @movie = Movie[movie_id]
    @recipient = @movie.user
    @vote = vote

    subject = I18n.t('user_mailer.vote_cast_notification.subject', title: @movie.title)

    mail(to: @recipient.email, subject: subject)
  end 
end
