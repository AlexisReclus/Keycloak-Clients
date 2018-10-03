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

	data = JSON.parse(response.body)
	data['access_token']
end


#This fonction create the client if it doesn't exit or call the update function if the client already exist
def do_request(token)
#Try to create the client, if it already exit, the response code will be 409
	uri = URI.parse(KEYCLOAK_REALM_URL)
	request = Net::HTTP::Post.new(uri)
	request.content_type = "application/json"
	request["Authorization"] = "bearer "+token
	request.body = ""
	request.body << File.read("mydata.json").delete("\r\n")

	req_options = {
		use_ssl: uri.scheme == "https",
	}

	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
		http.request(request)
	end

	if response.code == "409"
#Update the client because it already exist
		puts ((JSON.parse(request.body))['clientId']) + " Already exists, will be updated"
		update(token, ((JSON.parse(request.body))['clientId']))
	else
		puts ((JSON.parse(request.body))['clientId']) + " Created"
	end
end


#Request for the list of all the clients
def clientslist_request (token)

	uri = URI.parse(KEYCLOAK_REALM_URL)
	request = Net::HTTP::Get.new(uri)
	request["Authorization"] = "bearer "+ token

	req_options = {
	  use_ssl: uri.scheme == "https",
	}

	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
	  http.request(request)
	end

	# response.code
	data = JSON.parse(response.body)
	
end


#Do the update of a specific client d using a valid token
def do_update (token,d)

	puts "Find in Keycloak clients with the id: " + d['id']

	uri = URI.parse(KEYCLOAK_REALM_URL + d['id'])
	request = Net::HTTP::Put.new(uri)
	request.content_type = "application/json"
	request["Authorization"] = "bearer "+token
	request.body = ""
	request.body << File.read("mydata.json").delete("\r\n")

	req_options = {
	  use_ssl: uri.scheme == "https",
	}

	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
	  http.request(request)
	end

end


#If the client already exists, we need to update it
def update(token, client_id)

#Find the list of all the clients
	data = clientslist_request(token)

#Find the good client
	data.each do |d|
		if d['clientId'] == client_id
#Update this client
			do_update(token,d)
			# response.code
			puts "Update of client: "+ d['clientId'] +" with the id: "+ d['id'] +" done"
		end

	end

end

#Create the JSON in mydata.json
def create_json (responsebody)

	open('mydata.json','w') { |f|
		f.puts(responsebody)
	}

end


#Using for request the JSON of the client with client id specify in parameter
def take_json (client_id, token)
	uri = URI.parse(KEYCLOAK_REALM_URL + client_id)
	request = Net::HTTP::Get.new(uri)
	request["Authorization"] = "bearer " + token

	req_options = {
  	use_ssl: uri.scheme == "https",
	}

	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  	http.request(request)
	end
end 


def adapt_json(ligne)
	mydata = JSON.parse(File.read('mydata.json'))
#delete the id because keycloak an id automatically
	mydata.delete("id")
#Fix some config for this specific client
	mydata['clientId'] = "https://" + ligne +".jobreadyplus.com/jr/metadata"
	mydata['redirectUris'] = ["https://" + ligne +".jobreadyplus.com/jr/consume"]
#Write the new json in the mydata.json
	open('mydata.json','w') { |f|
		f.write(mydata.to_json)
	}
end


#Read the name of the client
# eg https://master.jobreadyplus.com/saml/metadata
input_array = ARGV
client_name = input_array[0]
client_id = ""
KEYCLOAK_REALM_URL = "https://staging.auth.jobready.io/auth/admin/realms/Plus/clients/"

#Request for a token
token = oauth_token

#Find the client id using the client name
myclientlist = clientslist_request(token)
myclientlist.each do |d| 
	if d['clientId'] == client_name
		puts "The client id you asked is: " + d['id']
		client_id = d['id']
	end

end	
#if not existing, exit the program with error code
if client_id == ""
	fail("CLIENT not found")
end

#Import the JSON of the client given as parameter
my_json = take_json(client_id, token)

#create a generic json in mydata.json
create_json(my_json.body)

#open the domain.txt, read the values
fic = File.open("domains.txt", "r")

#foreach value, adapt the json to make minors modifications
fic.each_line do |ligne|
	adapt_json(ligne.delete("\n\r"))
	puts ""

	#Create the client
	do_request(token)
end