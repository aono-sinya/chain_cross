port = ENV.fetch("PORT") { 3000 }
bind "tcp://0.0.0.0:#{port}"
environment ENV.fetch("RAILS_ENV") { "development" }
workers Integer(ENV.fetch("WEB_CONCURRENCY") { 0 })
threads_count = Integer(ENV.fetch("RAILS_MAX_THREADS") { 5 })
threads threads_count, threads_count
plugin :tmp_restart

