module Transfermarkt
  class League < Transfermarkt::EntityBase
    attr_accessor :name,
                :country,
                :league_uri,
                :clubs,
                :club_uris

    def self.fetch_by_league_uri(league_uri, fetch_clubs = false)
      puts "fetching league #{league_uri}"

      req = self.get("/#{league_uri}", headers: {"User-Agent" => Transfermarkt::USER_AGENT})
      if req.code != 200
        nil
      else
        league_html = Nokogiri::HTML(req.parsed_response)
        options = {}

        options[:league_uri] = league_uri
        options[:name] = league_html.xpath('//*[@id="wb_seite"]/table/tr[1]/td[2]/h1/text()').text.strip.gsub(" -","")
        options[:country] = league_html.xpath('//*[@id="wb_seite"]/table/tr[1]/td[2]/h1/a').text

        options[:club_uris] = league_html.xpath('//table[@id="vereine"]//tr//td[2]//a[@class="s10"]').collect{|player_html| player_html["href"]}

        puts "Found #{options[:club_uris].count} clubs"
        options[:clubs] = []

        if fetch_clubs
          options[:club_uris].each do |club_uri|
            options[:clubs] << Transfermarkt::Club.fetch_by_club_uri(club_uri, fetch_clubs)
          end
        end

        puts "fetched league clubs for #{options[:name]}"

        self.new(options)
      end
    end

    def self.fetch_league_uris
      root_uri = "/en/ligat-haal/startseite/wettbewerb_ISR1.html"
      req = self.get("/#{root_uri}", headers: {"User-Agent" => Transfermarkt::USER_AGENT})
      if req.code != 200
        nil
      else
        root_html = Nokogiri::HTML(req.parsed_response)
        league_uris = root_html.xpath('//*[@id="categorymenu"]/li/ul/li[1]/a').collect{|league| league["href"]}
      end
    end
  end
end