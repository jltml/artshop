# This script removes all SKU lists

require "faraday"

mode = "test"

auth_token = JSON.parse((Faraday.new(url: "https://max-mapellentz-art.commercelayer.io/oauth/token", headers: {"Accept" => "application/json", "Content-Type" => "application/json"}).post { |req| req.body = {"grant_type" => "client_credentials", "client_id" => `op read "op://Shared/4hyrrxvjgueahus4vy4xgikt5i/#{mode} mode client id"`.strip, "client_secret" => `op read "op://Shared/4hyrrxvjgueahus4vy4xgikt5i/#{mode} mode client secret"`.strip}.to_json }).body)["access_token"]
# shipments = JSON.parse(Faraday.new(url: "https://max-mapellentz-art.commercelayer.io/api/shipments", headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}"}).get.body)["data"]

response = JSON.parse((Faraday.new(url: "https://max-mapellentz-art.commercelayer.io/api/cleanups", headers: {"Accept" => "application/vnd.api+json", "Authorization" => "Bearer #{auth_token}", "Content-Type" => "application/vnd.api+json"}).post { |req| req.body = {"data" => {"type" => "cleanups", "attributes" => {"resource_type" => "sku_lists", "filters" => {}}}}.to_json }).body)

puts response
