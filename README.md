# carun.github.io #

My Static Site hosting on Github

## Install Jekyll for Github ##

To install Jekyll software for local testing:

1. Run command: `gem install bundler`
1. Go to root directory of repo and create file called `Gemfile`
1. Add line `gem 'github-pages'` to top of Gemfile
1. Run command `bundle install`

## Running Jekyll ##

In the repo root folder, run command `bundle exec jekyll serve`

## Updating Jekyll ##

Every once in a while, update Jekyll with the command `bundle update` in the root directory.

# SHORTCUT #

Just run the script `sudo update_and_run_jekyll.sh` from the repo root directory. It will update the software and then run the test server on port 4000.
