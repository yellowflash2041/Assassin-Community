namespace :app_initializer do
  desc "Prepare Application on Boot Up"
  task setup: :environment do
    puts "\n== Preparing Elasticsearch =="
    Rake::Task["search:setup"].execute

    puts "\n== Preparing database =="
    system("bin/rails db:prepare")

    puts "\n== Updating Data =="
    Rake::Task["data_updates:enqueue_data_update_worker"].execute

    SiteConfig.health_check_token ||= SecureRandom.hex(10)
  end
end

if ENV["ENABLE_HYPERSHIELD"].present?
  # enhance must be passed a block here to ensure that our hypershield task
  # runs AFTER db:prepare. Passing it as an argument will cause it to run BEFORE
  # https://ruby-doc.org/stdlib-2.0.0/libdoc/rake/rdoc/Rake/Task.html#method-i-enhance
  Rake::Task["db:prepare"].enhance do
    Rake::Task["hypershield:refresh"].execute
  end
end
