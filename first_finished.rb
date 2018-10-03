require 'net/http'
require 'uri'
require 'json'

def oauth_token
	uri = URI.parse("https://staging.auth.jobready.io/auth/realms/master/protocol/openid-connect/token")
	request = Net::HTTP::Post.new(uri)
	request.set_form_data(
	  "client_id" => "admin-cli",
	  "grant_type" => "password",
	  "password" => ENV['KEYCLOAK_PASSWORD'],
	  "username" => ENV['KEYCLOAK_USER'],
	)

	req_options = {
	  use_ssl: uri.scheme == "https",
	}

	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
	  http.request(request)
	end

	puts response
	puts response.code
	puts response.body['access_token']
	data = JSON.parse(response.body)
	data['access_token']
end

def do_request(token)
	uri = URI.parse("https://staging.auth.jobready.io/auth/admin/realms/Plus/clients")
	request = Net::HTTP::Post.new(uri)
	request.content_type = "application/json"
	request["Authorization"] = "bearer " + token
	request.body = ""
	request.body << File.read("data2.json").delete("\r\n")

	req_options = {
		use_ssl: uri.scheme == "https",
	}

	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
		http.request(request)
	end

	puts request.body
end

def create_json (ligne)

	open('data2.json','w') { |f|
		f.puts "{


		}
	}"
}

end
	

fic = File.open("domains.txt", "r")
token = oauth_token

fic.each_line do |ligne|
	create_json(ligne)
	do_request(token)
end
