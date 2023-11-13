require "faraday"
require "csv"
require "ruby-units"

mode = "test"

auth_token = JSON.parse((Faraday.new(url: "https://max-mapellentz-art.commercelayer.io/oauth/token", headers: {"Accept" => "application/json", "Content-Type" => "application/json"}).post { |req| req.body = {"grant_type" => "client_credentials", "client_id" => `op read "op://Shared/4hyrrxvjgueahus4vy4xgikt5i/#{mode} mode client id"`.strip, "client_secret" => `op read "op://Shared/4hyrrxvjgueahus4vy4xgikt5i/#{mode} mode client secret"`.strip}.to_json }).body)["access_token"]

shipments = JSON.parse(Faraday.new(url: "https://max-mapellentz-art.commercelayer.io/api/shipments", headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)["data"]

# shipments_picking = shipments.select do |element|
#   element["attributes"]["status"] == "picking"
# end
#
# shipments_packing = shipments.select do |element|
#   element["attributes"]["status"] == "packing"
# end

shipments_ready = shipments.select do |element|
  element["attributes"]["status"] == "ready_to_ship"
end

path = "Shipment Batch from #{Time.now.strftime("%F %R %Z")}.csv"
CSV.open(path, "w", headers: ["Name", "Address 1", "Address 2", "City", "State", "Zipcode", "Country", "Email", "Override Weight (Ounces)", "Override Length (Inches)", "Override Height (Inches)", "Override Width (Inches)", "Order ID"], write_headers: true) do |csv|
end

shipments_ready.each do |shipment|
  address = JSON.parse(Faraday.new(url: shipment["relationships"]["shipping_address"]["links"]["related"], headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)["data"]["attributes"]
  order = JSON.parse(Faraday.new(url: shipment["relationships"]["order"]["links"]["related"], headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)["data"]["attributes"]
  parcels = JSON.parse(Faraday.new(url: shipment["relationships"]["parcels"]["links"]["related"], headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)["data"]
  parcels.each do |parcel|
    package = JSON.parse(Faraday.new(url: parcel["relationships"]["package"]["links"]["related"], headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)["data"]["attributes"]
    parcel = parcel["attributes"]
    CSV.open(path, "a") do |csv|
      csv << [
        address["full_name"], # Name
        address["line_1"], # Address
        address["line_2"], # Address Line 2
        address["city"], # City
        address["state_code"], # State
        address["zip_code"], # Zipcode
        address["country_code"], # Country
        order["customer_email"], # Email Address
        "#{parcel["weight"]} #{parcel["unit_of_weight"]}".to_unit.convert_to("ounces").abs.round(2).to_s, # Package Weight (oz)
        "#{package["length"]} #{package["unit_of_length"]}".to_unit.convert_to("inches").abs.round(2).to_s, # Package Length (in)
        "#{package["height"]} #{package["unit_of_length"]}".to_unit.convert_to("inches").abs.round(2).to_s, # Package Height (in)
        "#{package["width"]} #{package["unit_of_length"]}".to_unit.convert_to("inches").abs.round(2).to_s, # Package Width (in)
        parcel["number"] # Order ID
      ]
    end
  end
end

# puts JSON.pretty_generate shipments_ready.first["relationships"]["order"]["links"]["related"]
#
# test_address = JSON.parse(Faraday.new(url: shipments.first["relationships"]["shipping_address"]["links"]["related"], headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)
#
# puts JSON.pretty_generate test_address["data"]["attributes"]
#
# test_parcel = JSON.parse(Faraday.new(url: shipments_ready[1]["relationships"]["parcels"]["links"]["related"], headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)["data"]
# puts JSON.pretty_generate test_parcel["data"]
#
# test_package = JSON.parse(Faraday.new(url: test_parcel["data"][0]["relationships"]["package"]["links"]["related"], headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)
# puts JSON.pretty_generate test_package["data"]["attributes"]
#
# test_order_id = JSON.parse(Faraday.new(url: shipments_ready.first["relationships"]["order"]["links"]["related"], headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)
# puts JSON.pretty_generate test_order_id["data"]["attributes"]["customer_email"]
