module DataUpdateScripts
  class RemoveCollectiveNounFromConfig
    def run
      SiteConfig.where(var: %w[collective_noun collective_noun_disabled]).destroy_all
    end
  end
end
