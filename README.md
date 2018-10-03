# firstfinished.rb

This files creates clients in keycloak:
1. In the same folder, you can do ~ touch domain.txt to create the domain.txt file, file were the client_name will be readen.
2. In the script: change the function 'create_json' and inside the f.puts "{    }" write a Json describing the client you want to add in Keycloak.
3. If you want to add a client using an url given in domain.txt file you can add  "\clientId\":ligne  in the Json.
4. Make sure you have exported the username and password using the command line:
```
export KEYCLOAK_USER=username
export KEYCLOAK_PASSWORD=password
```
5. You also have to change all the url in the curl requests.
6. You can export a client from keycloak if you want to have a template to create the JSON.

Run this script : 
````
ruby firstfinished.rb
````



# try.rb

This files extracted a client in your keycloak environment, use its Json configurations to create another client with a new ID given in domain.txt.
1. In the same folder, you can do ~ touch domain.txt to create the domain.txt file, file were the client name will be readen.
2. In the domain.txt file, add clients name, one client per line.
3. Make sure you have exported the username and password using the command line:
```
export KEYCLOAK_USER = username
export KEYCLOAK_PASSWORD = password
```
4. run the script like this:
````
ruby try.rb client_name
````
5. You also have to change all the url in the curl requests.
6. client_name corresponds to the client which the script is importing the Json configs to create all the other clients using this same config and modify the client_id with the list given in domain.txt.
