web: bundle exec unicorn -p $PORT -c config/unicorn.rb config.ru
sidekiq: bundle exec sidekiq -q default -q mailers
