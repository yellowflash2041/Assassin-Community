namespace :metrics do
  desc "Collects metrics from Forem instances"
  task overview: :environment do
    puts "Admin Overview Link Tracking for #{SiteConfig.app_domain}:"
    links_by_target = Ahoy::Event.overview_link_clicks.group("properties -> 'target'").count
    links_by_target.each do |k, v|
      puts "#{k.delete_prefix(URL.url)}: #{v}"
    end
  end
end
