require 'net/http'
require 'uri'
require 'json'
require "Nokogiri" 

def request_xml(lien)
	uri = URI.parse(lien)
	response = Net::HTTP.get_response(uri)

	#puts response.code
	if(response.code != "200")
		puts "Issue with this client: " + lien
		response = "error"
	end
	response
end


def oauth_token
	uri = URI.parse("https://auth.staging.jobready.io/auth/realms/master/protocol/openid-connect/token")
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


#Create the JSON in mydata.json
def create_json (xmlbody)

	doc = Nokogiri::XML xmlbody
	# Compact uses as little whitespace as possible

	root = doc.root;
	chemin = (root.at_xpath("@entityID")).to_str;
	puts "Parameter AuthnRequestsSigned: " + root.at_xpath("//@AuthnRequestsSigned")
	puts "Parameter Location: " + root.at_xpath("//@Location")
	puts "Parameter WantAssertionsSigned: " + root.at_xpath("//@WantAssertionsSigned")
	puts "Parameter XMLNS:EC: " + root.at_xpath("//@Algorithm")


	chemin = chemin.slice(0, chemin.rindex('/'))
	chemin = chemin.slice(0, chemin.rindex('/'))
	puts "Parameter webOrigins: " + chemin

	open('mydata.json','w') { |f|
		f.puts "{
    \"clientId\": \"" + root.at_xpath("@entityID") + "\",
    \"surrogateAuthRequired\": false,
    \"enabled\": true,
    \"clientAuthenticatorType\": \"client-secret\",
    \"redirectUris\": [
        \"" + root.at_xpath("//@Location") + "\"
    ],
    \"webOrigins\": [
        \"" + chemin + "\"
    ],
    \"notBefore\": 0,
    \"bearerOnly\": false,
    \"consentRequired\": false,
    \"standardFlowEnabled\": true,
    \"implicitFlowEnabled\": false,
    \"directAccessGrantsEnabled\": false,
    \"serviceAccountsEnabled\": false,
    \"publicClient\": false,
    \"frontchannelLogout\": true,
    \"protocol\": \"saml\",
    \"attributes\": {
        \"saml.assertion.signature\": \""+root.at_xpath("//@AuthnRequestsSigned")+"\",
        \"saml.force.post.binding\": \"true\",
        \"saml.encrypt\": \"true\",
        \"saml_assertion_consumer_url_post\": \"" + root.at_xpath("//@Location") + "\",
        \"saml.server.signature\": \"true\",
        \"saml.server.signature.keyinfo.ext\": \"false\",
        \"saml.signing.certificate\": \"" + doc.at_css('[@use="signing"]').content + "\",
        \"saml.signature.algorithm\": \"RSA_SHA256\",
        \"saml_force_name_id_format\": \"false\",
        \"saml.client.signature\": \"true\",
        \"saml.encryption.certificate\": \"" + doc.at_css('[@use="encryption"]').content + "\",
        \"saml.authnstatement\": \"true\",
        \"saml_name_id_format\": \"email\",
        \"saml_signature_canonicalization_method\": \"" + root.at_xpath("//@Algorithm") + "\"
    },
    \"authenticationFlowBindingOverrides\": {},
    \"fullScopeAllowed\": true,
    \"nodeReRegistrationTimeout\": -1,
    \"defaultClientScopes\": [
        \"role_list\",
        \"profile\",
        \"email\"
    ],
    \"optionalClientScopes\": [
        \"address\",
        \"phone\",
        \"offline_access\"
    ],
    \"access\": {
        \"view\": true,
        \"configure\": true,
        \"manage\": true
    }
}"
	}

end


#This fonction create the client if it doesn't exit or call the update function if the client already exist
def do_request(token)
#Try to create the client, if it already exit, the response code will be 409
	uri = URI.parse(KEYCLOAK_REALM_URL)
	request = Net::HTTP::Post.new(uri)
	request.content_type = "application/json"
	request["Authorization"] = "bearer " + token
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



KEYCLOAK_REALM_URL = "https://auth.staging.jobready.io/auth/admin/realms/Plus/clients/";

#open the domain.txt, read the values
fic = File.open("domains.txt", "r");

#Request for a token
token = oauth_token()

fic.each_line do |ligne|
	#Request for the medata in the website
	puts "Client: " + ligne
	my_xml = request_xml(ligne.delete("\n")
);

	if my_xml != "error"
		#create a generic json in mydata.json depending on metadata file
		create_json(my_xml.body)
		puts "JSON created for: " + ligne

		#Create the client
		do_request(token)
	else
		puts "METADATA NOT FOUND, PLEASE CHECK URI FOR CLIENT: " + ligne
	end
	puts ""
end