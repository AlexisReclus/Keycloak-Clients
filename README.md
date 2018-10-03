# firstfinished.rb

This files creates clients in keycloak:
1. In the same folder, you can do ~ touch domain.txt to create the domain.txt file, file were the client ID will be readen.
2. In the script: change the function 'create_json' and inside the f.puts "{    }" write a Json describing the client you want to add in Keycloak.
3. If you want to add a client using an url given in domain.txt file you can add  "\clientId\":ligne  in the Json
4. Make sure you have exported the username and password using the command line:
```
export KEYCLOAK_USER = username
export KEYCLOAK_PASSWORD = password
```
5. You can export a client from keycloak if you want to have a template to create the JSON


# try.rb
