# RCommunicate
This is a simple way of sending messages between alt accounts, allowing you to control them, etc. The "server" aspect is supposed to be run locally and simply relays each websocket message to each client. You will need to create the commands yourself

## Setup
- Compile the server code or use the releases (if it is there)
- Run the server
- Keep it open in the background
- Run the client script on each of your alts

## Specifying port
By default, the websocket server port is `69420` but depending on how you launch the server, this can change. Simply pass the argument `127.0.0.1:` followed by the port, i.e. `127.0.0.1:12345`. `server.exe 127.0.0.1:12345`