source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.13"

gem "rails", "~> 8.0"
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "solid_queue"
gem "solid_cache"
gem "solid_cable"
gem "propshaft"
gem "tailwindcss-rails"
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "brakeman", require: false
  gem "bundler-audit", require: false
end

group :test do
  gem "minitest"
end