module ArtShop
  module Scripts
    def self.ship(test: false)
      require "faraday"
      require "paint"
      require "clipboard"
      require "tty-prompt"
      require "launchy"

      mode = test ? "test" : "live"
      puts Paint["→ Using test mode", :faint, :italic] if mode == "test"

      prompt = TTY::Prompt.new

      auth_token = JSON.parse((Faraday.new(url: "https://max-mapellentz-art.commercelayer.io/oauth/token", headers: {"Accept" => "application/json", "Content-Type" => "application/json"}).post { |req| req.body = {"grant_type" => "client_credentials", "client_id" => `op read "op://Shared/4hyrrxvjgueahus4vy4xgikt5i/#{mode} mode client id"`.strip, "client_secret" => `op read "op://Shared/4hyrrxvjgueahus4vy4xgikt5i/#{mode} mode client secret"`.strip}.to_json }).body)["access_token"]

      shipments = JSON.parse(Faraday.new(url: "https://max-mapellentz-art.commercelayer.io/api/shipments", headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)["data"]

      need_to_ship = shipments.select do |element|
        status = element["attributes"]["status"]
        status == "picking" || status == "packing"
      end

      puts
      puts Paint["→ Hello, Max!", :faint]
      puts "→ You have #{Paint[need_to_ship.count, :bold]} order#{"s" if need_to_ship.count != 1} to ship today."

      Launchy.open "https://ship.pirateship.com/ship/single" if need_to_ship.count > 0

      need_to_ship.each do |shipment|
        puts
        address = JSON.parse(Faraday.new(url: shipment["relationships"]["shipping_address"]["links"]["related"], headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)["data"]["attributes"]
        order = JSON.parse(Faraday.new(url: shipment["relationships"]["order"]["links"]["related"], headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)["data"]["attributes"]
        str = ""
        str << "#{address["full_name"]}\n" if address["full_name"] # Name
        str << "#{address["line_1"]}\n" if address["line_1"] # Address
        str << "#{address["line_2"]}\n" if address["line_2"] # Address Line 2
        str << "#{address["city"]}\n" if address["city"] # City
        str << "#{address["state_code"]}\n" if address["state_code"] # State
        str << "#{address["zip_code"]}\n" if address["zip_code"] # Zipcode
        str << "#{address["country_code"]}\n" if address["country_code"] # Country
        str << "#{order["customer_email"]}\n" if order["customer_email"] # Email Address
        Clipboard.copy str.strip
        puts Paint["→ Shipment ##{shipment["attributes"]["number"]}", :faint]
        puts Paint["→ Copied to clipboard: #{str.gsub("\n", ", ").chomp(", ")}", :faint]
        if prompt.yes?("→ Mark as shipped (irreversible)?")
          shipped_api_response = Faraday.new(url: "https://max-mapellentz-art.commercelayer.io/api/shipments/#{shipment["id"]}", headers: {"Accept" => "application/vnd.api+json", "Content-Type" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).patch { |req| req.body = {"data" => {"type" => "shipments", "id" => shipment["id"], "attributes" => {"_ship" => "true"}}}.to_json }
          if shipped_api_response.status == 200
            puts Paint["→ Marked as shipped!", :green]
          else
            puts Paint["→ Error while marking as shipped.", :red]
            puts "→ Got HTTP response #{shipped_api_response.status} from server."
            puts shipped_api_response.body
          end
        else
          puts Paint["→ Not marked as shipped.", :red]
        end
      end
    end
  end
end
