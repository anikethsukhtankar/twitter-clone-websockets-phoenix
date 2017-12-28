defmodule TwitterClone.Client do
    @moduledoc false
  require Logger
  alias Phoenix.Channels.GenSocketClient
  @behaviour GenSocketClient

  def start_link(userId,noOfTweets,noToSubscribe,existingUser) do
    GenSocketClient.start_link(
          __MODULE__,
          Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
          ["ws://localhost:4000/socket/websocket",userId,noOfTweets,noToSubscribe,existingUser]
        )
  end

  def init([url,userId,noOfTweets,noToSubscribe,existingUser]) do
    {:connect, url, [], %{"userId" => userId, "noOfTweets" => noOfTweets, "noToSubscribe" => noToSubscribe, "existingUser" => existingUser}}
  end

  def handle_connected(transport, state) do
    Logger.info("connected")
    GenSocketClient.join(transport, "ping")
    {:ok, state}
  end

  def handle_disconnected(reason, state) do
    Logger.error("disconnected: #{inspect reason}")
    {:ok, state}
  end

  def handle_joined(_topic, _payload, transport, state) do
    # Logger.info("joined the topic #{topic}")

    userId = Map.get(state,"userId")
    if Map.get(state,"existingUser") do
        Logger.info("User #{userId} :- reconnected")
        GenSocketClient.push(transport, "ping", "loginUser", %{"userId" => userId})
        for _ <- 1..5 do
          GenSocketClient.push(transport, "ping", "tweet", %{"userId" => userId,"tweet" => "user#{userId} tweeting that #{randomizer(8)} does not make sense"})  
        end
    else
        # Register Account
        GenSocketClient.push(transport, "ping", "registerUser", %{"userId" => userId})
    end
    {:ok, state}
  end

  def handle_join_error(topic, payload, _transport, state) do
    Logger.error("join error on the topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_channel_closed(topic, payload, _transport, state) do
    Logger.error("disconnected from the topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_message(_topic, "registerConfirmed", _payload, transport, state) do
    Logger.info("User #{Map.get(state,"userId")} :- registered on server")

    userId = Map.get(state,"userId")

    #Subscribe
    if Map.get(state,"noToSubscribe") > 0 do
        subList = generate_subList(1,Map.get(state,"noToSubscribe"),[])
        handle_zipf_subscribe(userId,subList,transport)
    end

    state = Map.put(state,"start_time",System.system_time(:millisecond))
    
    #Mention
    userToMention = :rand.uniform(String.to_integer(userId))
    GenSocketClient.push(transport, "ping", "tweet", %{"userId" => userId,"tweet" => "user#{userId} tweeting @#{userToMention}"}) 
    
    #Hashtag
    GenSocketClient.push(transport, "ping", "tweet", %{"userId" => userId,"tweet" => "user#{userId} tweeting that #COP5615isgreat"})
    
    #Send Tweets
    for _ <- 1..Map.get(state,"noOfTweets") do
      GenSocketClient.push(transport, "ping", "tweet", %{"userId" => userId,"tweet" => "user#{userId} tweeting that #{randomizer(8)} does not make sense"})
    end

    #ReTweet
    GenSocketClient.push(transport, "ping", "tweetsSubscribedTo", %{"userId" => userId})
    {:ok, state}
  end
  
  def handle_message(_topic, "repTweetsSubscribedTo", payload, transport, state) do
    list = Map.get(payload,"list")
    if list != [] do
        rt = hd(list)
        GenSocketClient.push(transport, "ping", "tweet", %{"userId" => Map.get(payload,"userId"),"tweet" => rt <> " -RT"})
    end
    tweets_time_diff = System.system_time(:millisecond) - Map.get(state,"start_time")
    state = Map.put(state,"a",tweets_time_diff/(Map.get(state,"noOfTweets")+3))

    #Queries
    state = Map.replace(state,"start_time",System.system_time(:millisecond))
    GenSocketClient.push(transport, "ping", "queryTweetsSubscribedTo", %{"userId" => Map.get(payload,"userId")})
    {:ok, state}
  end
  
  def handle_message(_topic, "fetchedTweetsSubscribedTo", payload, transport, state) do
    list = Map.get(payload,"list")
    if list != [], do: IO.inspect list, label: "User #{Map.get(payload,"userId")} :- Tweets Subscribed To"
    queries_subscribedto_time_diff = System.system_time(:millisecond) - Map.get(state,"start_time")
    state = Map.put(state,"b",queries_subscribedto_time_diff)

    state = Map.replace(state,"start_time",System.system_time(:millisecond))
    GenSocketClient.push(transport, "ping", "tweetsWithHashtag", %{"userId" => Map.get(payload,"userId"),"tag" => "#COP5615isgreat"})
    {:ok, state}
  end
  
  def handle_message(_topic, "repTweetsWithHashtag", payload, transport, state) do
    IO.inspect Map.get(payload,"list"), label: "User #{Map.get(payload,"userId")} :- Tweets With #COP5615isgreat"
    queries_hashtag_time_diff = System.system_time(:millisecond) - Map.get(state,"start_time")
    state = Map.put(state,"c",queries_hashtag_time_diff)
    
    state = Map.replace(state,"start_time",System.system_time(:millisecond))
    GenSocketClient.push(transport, "ping", "tweetsWithMention", %{"userId" => Map.get(payload,"userId")})
    {:ok, state}
  end

  def handle_message(_topic, "repTweetsWithMention", payload, transport, state) do
    IO.inspect Map.get(payload,"list"), label: "User #{Map.get(payload,"userId")} :- Tweets With @#{Map.get(payload,"userId")}"
    queries_mention_time_diff = System.system_time(:millisecond) - Map.get(state,"start_time")
    state = Map.put(state,"d",queries_mention_time_diff)

    #Get All Tweets
    state = Map.replace(state,"start_time",System.system_time(:millisecond))
    GenSocketClient.push(transport, "ping", "getMyTweets", %{"userId" => Map.get(payload,"userId")})
    {:ok, state}
  end

  def handle_message(_topic, "repGetMyTweets", payload, _transport, state) do
    IO.inspect Map.get(payload,"list"), label: "User #{Map.get(payload,"userId")} :- All my tweets"
    queries_myTweets_time_diff = System.system_time(:millisecond) - Map.get(state,"start_time")
    state = Map.put(state,"e",queries_myTweets_time_diff)
    send(:global.whereis_name(:mainproc),{:perfmetrics,Map.get(state,"a"),Map.get(state,"b"),Map.get(state,"c"),Map.get(state,"d"),Map.get(state,"e")})
    {:ok, state}
  end

  def handle_message(_topic, "live", %{"tweetString" => tweetString}, _transport, state) do
    IO.inspect tweetString, label:  "User #{Map.get(state,"userId")} :- Live View -----"
    {:ok, state}
  end
  
  def handle_message(topic, event, payload, _transport, state) do
    Logger.warn("message on topic #{topic}: #{event} #{inspect payload}")
    {:ok, state}
  end

  def handle_reply("ping", _ref, %{"status" => "ok"} = payload, _transport, state) do
    Logger.info("server pong ##{payload["response"]["ping_ref"]}")
    {:ok, state}
  end

  def handle_reply(topic, _ref, payload, _transport, state) do
    Logger.warn("reply on topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_info(:connect, _transport, state) do
    Logger.info("connecting")
    {:connect, state}
  end

  def handle_info({:disconnect},_transport, state) do
    Logger.info("disconnecting #{Map.get(state,"userId")}")
    {:ok, state}
  end

  def handle_info({:join, topic}, transport, state) do
    Logger.info("joining the topic #{topic}")
    case GenSocketClient.join(transport, topic) do
      {:error, reason} ->
        Logger.error("error joining the topic #{topic}: #{inspect reason}")
      {:ok, _ref} -> :ok
    end

    {:ok, state}
  end

  def handle_info(message, _transport, state) do
    Logger.warn("Unhandled message #{inspect message}")
    {:ok, state}
  end

  def generate_subList(count,noOfSubs,list) do
      if(count == noOfSubs) do 
          [count | list]
      else
          generate_subList(count+1,noOfSubs,[count | list]) 
      end
  end

  def handle_zipf_subscribe(userId,subscribeToList,transport) do
      Enum.each subscribeToList, fn accountId ->
          GenSocketClient.push(transport, "ping", "addSubscriber", %{"userId" => userId,"accountId" => Integer.to_string(accountId)}) 
      end
  end

  def randomizer(l) do
    :crypto.strong_rand_bytes(l) |> Base.url_encode64 |> binary_part(0, l) |> String.downcase
  end

  def handle_call(_message, _arg1, _transport, state) do
    {:ok, state}
  end

end