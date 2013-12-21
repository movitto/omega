# Omega Project Gemfile
source 'https://rubygems.org'

# RJR & deps for optional transports
gem 'rjr'
gem 'eventmachine_httpserver'
gem 'em-http-request', '~> 1.0.3'
gem 'em-websocket'  # requires gcc-c++,ruby-devel
gem 'em-websocket-client', '>= 0.1.2'
gem 'amqp'          # requires a running AMQP server to connect to

# Other deps
gem 'curb'          # requires gcc,openssl-devel,libcurl-devel

# For command line utilities
gem 'colored'
gem 'pry'
gem 'ncursesw'      # requires ncurses-devel
#gem 'rgl'

# For Spec Suite
group :test do
  gem 'rake'
  gem 'rspec'
end
