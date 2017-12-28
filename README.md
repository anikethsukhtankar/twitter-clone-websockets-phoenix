# twitter-clone-websockets-phoenix
The goal of this project is to use the Phoenix web framework to implement a WebSocket interface to the Twitter Clone and client tester/simulator built in Elixir. The problem statement is to implement a JSON based API that represents all messages and their replies (including errors), design an engine using Phoenix and multiple clients to implement the WebSocket interface. 

Authors

Aniketh Sukhtankar (UF ID 7819 9584) asukhtankar@ufl.edu
Shikha Mehta (UF ID 4851 9256) shikha.mehta@ufl.edu

-------------------------------------------------------
 COP5615 : DISTRIBUTED SYSTEMS - TWITTER CLONE 
-------------------------------------------------------
The goal of this project is to:
 • Design a JSON based API that represents all messages and their replies (including errors) 
 • Re-write our engine using Phoenix to implement the WebSocket interface 
 • Re-write our client to use WebSockets. 

Further, the now Phoenix-based Twitter engine (Server) has been implemented with the following functionality: 
 • Register account 
 • Send tweet. Tweets can have hashtags (e.g. #COP5615isgreat) and mentions (@bestuser) 
 • Subscribe to user's tweets 
 • Re-tweets (so that your subscribers get an interesting tweet you got by other means) 
 • Allow querying tweets subscribed to, tweets with specific hashtags, tweets in which the user is mentioned (my mentions) 
 • If the user is connected, deliver the above types of tweets live (without querying) 

PRE-REQUISITES
--------------
The following need to be installed to run the project:
 - Elixir
 - Erlang
 - Phoenix Framework

Two terminals are required to execute Twitter server and clients simulator separately.

CLIENTS SIMULATOR PROGRAM INPUTS
--------------------------------
 - numClients: 		the number of clients to simulate
 - maxSubscribers: 	the maximum number of subscribers a Twitter account can have in the simulation (must be < numClients)
 - disconnectClients: 	the percentage of clients to disconnect to simulate periods of live connection and disconnection

RUNNING project4.tgz
--------------------
1. Go to the folder ‘example’ in one terminal using command line. 
2. Start the Twitter engine in that by executing the following sequence of commands:  
a. mix deps.get 
b. mix deps.compile 
c. mix phx.server  
3. Start the clients simulator in the other terminal using the following command: escript project4 <numClients> <maxSubscribers> <disconnectClients> 
   e.g. escript project4 10 5 20    
4. Note that both programs do not terminate by themselves.  
   a. Twitter engine is designed to always stay on-line to handle incoming client connections. 
   b. Clients simulator simulates recurring periods of live connection and disconnection. 
5. To simulate the system with different parameter values, please restart both the programs and repeat the steps above.

OUTPUT
------
1. On the simulator's console we print query results for all the 3 types of queries, prefixed with the corresponding user's ID. 
2. The simulator's console also prints live tweets for every user. User ID is prefixed to this output as well to identify which user's live view is getting updated. 
3. If <disconnectClients> parameter is 0, the clients simulator console displays the performance statistics at the end. Otherwise, it prints the statistics and continues to simulate periods of live connection and disconnection. 
