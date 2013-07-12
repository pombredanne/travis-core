source 'https://rubygems.org'

gemspec

gem 'travis-support',     github: 'travis-ci/travis-support'
gem 'travis-sidekiqs',    github: 'travis-ci/travis-sidekiqs', require: nil
gem 'gh',                 github: 'rkh/gh'
gem 'newrelic_rpm',       '~> 3.4'
gem 'addressable'
gem 'aws-sdk'
gem 'json', '~> 1.7'

gem 'dalli'
gem 'connection_pool'

platform :mri do
  gem 'bunny',            '~> 0.7'
  gem 'pg',               '~> 0.14'
end

platform :jruby do
  gem 'jruby-openssl',    '~> 0.8'
  gem 'hot_bunnies',      '~> 1.4'
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'activerecord-jdbc-adapter'
end

group :development, :test do
  gem 'micro_migrations', git: 'https://gist.github.com/2087829.git'
  gem 'data_migrations',  '~> 0.0.1'
end

group :test do
  gem 'rspec',            '~> 2.8'
  gem 'factory_girl',     '~> 2.6'
  gem 'database_cleaner', '~> 1.0'
  gem 'mocha',            '~> 0.10'
  gem 'webmock',          '~> 1.8'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-fsevent'
end
