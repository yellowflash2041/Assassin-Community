#!/bin/bash

notify () {
  FAILED_COMMAND="$(caller): ${BASH_COMMAND}" \
    bundle exec rails runner "ReleasePhaseNotifier.ping_slack"
}

trap notify ERR

# enable echo mode (-x) and exit on error (-e)
# -E ensures that ERR traps get inherited by functions, command substitutions, and subshell environments.
set -Eex

# abort release if deploy status equals "blocked"
[[ $DEPLOY_STATUS = "blocked" ]] && echo "Deploy blocked" && exit 1

# runs migration for Postgres, setups/updates Elasticsearch
# and boots the app to check there are no errors
STATEMENT_TIMEOUT=180000 bundle exec rails db:migrate
bundle exec rake fastly:update_configs
bundle exec rake search:setup
bundle exec rake data_updates:enqueue_data_update_worker
bundle exec rails runner "puts 'app load success'"
