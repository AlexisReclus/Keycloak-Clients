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
			\"clientId\": \"https://" + ligne + ".jobreadyplus.com/saml/metadata\",
			\"surrogateAuthRequired\": false,
			\"enabled\": true,
			\"clientAuthenticatorType\": \"client-secret\",
			\"redirectUris\": [
			\"https://master.jobreadyplus.com/*\"
		],
		\"webOrigins\": [],
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
		\"saml.assertion.signature\": \"false\",
		\"saml.force.post.binding\": \"true\",
		\"saml.multivalued.roles\": \"false\",
		\"saml.encrypt\": \"false\",
		\"saml.server.signature\": \"true\",
		\"saml.server.signature.keyinfo.ext\": \"false\",
		\"exclude.session.state.from.auth.response\": \"false\",
		\"saml.signing.certificate\": \"MIIC6TCCAdECBgFmE9DMEzANBgkqhkiG9w0BAQsFADA4MTYwNAYDVQQDDC1odHRwczovL21hc3Rlci5qb2JyZWFkeXBsdXMuY29tL3NhbWwvbWV0YWRhdGEwHhcNMTgwOTI2MDI1NzIyWhcNMjgwOTI2MDI1OTAyWjA4MTYwNAYDVQQDDC1odHRwczovL21hc3Rlci5qb2JyZWFkeXBsdXMuY29tL3NhbWwvbWV0YWRhdGEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCBRd+JiUcjMXjYFVqkSeeJkOauZYDY21in/WlmG5MeXe4Gq/chWqSAxH5mJlpQYUvHpE+tneg8YP8nrNdi3LJ3TdqeF9IVl8DAWgbtSCF1w8UM+awapSkVe9RNFgTEdKD6KDLELBIrCTaQVcWD6Ru1yruF2LemjI011rBjqLkr9YZxKrS+wSuF3uzYxmS9JmxiBXhZQ6vXDDzgIEARQF9IZDgbI8t9qbKOKB99Yr/1gPAYHemghr0KALUGNM9fY/GU5kGX6K3fYt6Ax1I/v3M6wk9ueBHa5717nn4Bmz3uWm38xDVspj3gYon5dneeyLRsMXPoqc00riXocTx9CWMPAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAB8aXWxzG1LlnUX1ngetMOQMXNUPsQfC6w+NorsIHPQZ7jHUKokh7AJGDXP65d/XKNP6i1s4V80VdbM6nj6xR8b5BHk4VhAp02103XIj6q8mevMYA9fjvezQSNBbIR6CCaLBIQxeO5Dxzhpo4lBpxws4X+DCnGUF9R3k9VKKrf50utFdGfFOvOvot4aZEPQ2SgqxzX9QTgXpogAQ7qmoxKkkgVWwgQLKROsSMHfOtA57tYnug1jwj64INXsboagozBlPvFYzCmCQhV9aRamrr4ACcc9idM5Tcjo0p//xVLVay5MwcNgJTMm3pPRW4RKPVgJ+dLJsZFWNkyuNJzPp5pA=\",
		\"saml.signature.algorithm\": \"RSA_SHA256\",
		\"saml_force_name_id_format\": \"false\",
		\"saml.client.signature\": \"false\",
		\"tls.client.certificate.bound.access.tokens\": \"false\",
		\"saml.authnstatement\": \"true\",
		\"display.on.consent.screen\": \"false\",
		\"saml.signing.private.key\": \"MIIEpAIBAAKCAQEAgUXfiYlHIzF42BVapEnniZDmrmWA2NtYp/1pZhuTHl3uBqv3IVqkgMR+ZiZaUGFLx6RPrZ3oPGD/J6zXYtyyd03anhfSFZfAwFoG7UghdcPFDPmsGqUpFXvUTRYExHSg+igyxCwSKwk2kFXFg+kbtcq7hdi3poyNNdawY6i5K/WGcSq0vsErhd7s2MZkvSZsYgV4WUOr1ww84CBAEUBfSGQ4GyPLfamyjigffWK/9YDwGB3poIa9CgC1BjTPX2PxlOZBl+it32LegMdSP79zOsJPbngR2ue9e55+AZs97lpt/MQ1bKY94GKJ+XZ3nsi0bDFz6KnNNK4l6HE8fQljDwIDAQABAoIBAGxs5qi882WZQPo8LuJM+l5voovzprY8g4ejDJwP1L1LmzENWyImnINES5/x2x4//Qdd0VaVcwvxbxEf7yeEZEuciRjAcfyaY5jx6Y1rSmUz5jqTzr4qeOMEEXT2WtlL2Rj4TlwrerGN8K3uwtN42T0I5W/F7YNLr8TQZPGxul4bRzqTByKLv0BHsKM0mLN6wLasHMt1xgaWyqAfghUBsPNE9rS6Gv/xk7Suz2gFSVQYhT6lI0I6pIplOtMMghs4Y9ppgCUaxB35n7Xu/2hsDJ3gojJgDpA9bVL6J884OECztmOsd75ZHAurU7yoL3cEnfO6ZcHo5PrAzhxR6qIXCsECgYEAvu14TwVYLaLflCMGTRsMrz6YsGsb1UpiqurxPbT0+qSDWMHgQmrb47U85rKZkDDV3+dVmiMkn4Q04OaCOPv9BY1miyu77w8oASlnsCWxX3vN85pszyD22zRwgfiFKAeVSE3uCeh4XoOWTVkZmXFcK62xkun2zaUKRYAui/HV6hMCgYEArVUAhP674eym91dZ8yhAK2phB07nHSueuO9Jc8DDCcgtbbQrbkZ/LTFbkrOD19UzwbqgSVhbyYUBayqnkoPEhLyo6HdzTnCP0t+07eMoZSVQrwx6u3pvRkbYwyxel5enHxdVBIgDRoH795Zb/eNC7lhfpM2Zccb6iObJ52f8ApUCgYBxcu3QFp7kzykG/yDZZD9PSmS0P5DUVlT2tpAOWJ5Q6LxbWyiEjraGQcUkV+/DrCEJ4I4O/t7eIlLBaHbsoV8hk3nhLGWJkXn15sKD+oHA+PHR1GrfUPkeG7TWpfOJa6gaxKOzI32Su6Ht6Am8EY3xLk6bu4Y5f93wmlAOO+8eHQKBgQCjC+KBOF3kF4i4AiNK6AH01QyQo1gjyHR14iFmEV1mRjb1ixWPliDrkhJh3RuYW6VkBvngBI3S8ppzBJy85dZmRlFc24BLuPaRln3LiHLnMkLDZynMUU96/AnLDmGsl6tNQ9VlfcwW9w7dx0KhgLXlHpxZmk1NCa+COBaU5uvYQQKBgQCRoc2lpZ0Z6ETWvmpQYSGbvfJL2wrvEhxYPEkJSR+4le2bOfnqTq5silgmqw3SjoN8zeVgHMhhXkei3+pf+0p4W7SVy41UAc/y7pzbfvQH8B3yQdPVffgk5UqgLFtPgR6e2yjb8BVr1d33E+3cG110840so/Ii6D8BcwnnOYb5CQ==\",
		\"saml_name_id_format\": \"email\",
		\"saml_signature_canonicalization_method\": \"http://www.w3.org/2001/10/xml-exc-c14n#\",
		\"saml.onetimeuse.condition\": \"false\"
	},
	\"authenticationFlowBindingOverrides\": {},
	\"fullScopeAllowed\": false,
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
	

fic = File.open("domains.txt", "r")
token = oauth_token

fic.each_line do |ligne|
	create_json(ligne)
	do_request(token)
end
