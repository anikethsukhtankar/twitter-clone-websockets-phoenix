defmodule ExampleWeb.PingChannel do
  use Phoenix.Channel
  require Logger

  def whereis(userId) do
    if :ets.lookup(:clientsregistry, userId) == [] do
            nil
    else
        [tup] = :ets.lookup(:clientsregistry, userId)
        elem(tup, 1)
    end
  end

  def join(_topic, _payload, socket) do
    {:ok, socket}
  end
  
  def handle_in("registerUser", %{"userId" => userId}, socket) do
    :ets.insert(:clientsregistry, {userId, socket})
    :ets.insert(:tweets, {userId, []})
    :ets.insert(:subscribedto, {userId, []})
    if :ets.lookup(:followers, userId) == [], do: :ets.insert(:followers, {userId, []})
    push socket, "registerConfirmed", %{}
    {:noreply, socket}
  end

  def handle_in("loginUser", %{"userId" => userId}, socket) do
    :ets.insert(:clientsregistry, {userId, socket})
    {:noreply, socket}
  end

  def handle_in("addSubscriber", %{"userId" => userId,"accountId" => subId}, socket) do
    add_subscribed_to(userId,subId)
    add_followers(subId,userId)
    {:noreply, socket}
  end

  def handle_in("tweet", %{"userId" => userId,"tweet" => tweetString}, socket) do
    process_tweet(tweetString,userId)
    {:noreply, socket}
  end

  def handle_in("tweetsSubscribedTo", %{"userId" => userId}, socket) do
    subscribedTo = get_subscribed_to(userId)
    list = generate_tweet_list(subscribedTo,[])
    push socket, "repTweetsSubscribedTo", %{"userId" => userId, "list" => list}
    {:noreply, socket}
  end

  def handle_in("queryTweetsSubscribedTo", %{"userId" => userId}, socket) do
    subscribedTo = get_subscribed_to(userId)
    list = generate_tweet_list(subscribedTo,[])
    push socket, "fetchedTweetsSubscribedTo", %{"userId" => userId, "list" => list}
    {:noreply, socket}
  end

  def handle_in("tweetsWithHashtag", %{"userId" => userId,"tag" => tag}, socket) do
    list=tweets_with_hashtag(tag,userId)
    push socket, "repTweetsWithHashtag", %{"userId" => userId, "list" => list}
    {:noreply, socket}
  end

  def handle_in("tweetsWithMention", %{"userId" => userId}, socket) do
    list=tweets_with_mention(userId)
    push socket, "repTweetsWithMention", %{"userId" => userId, "list" => list}
    {:noreply, socket}
  end

  def handle_in("getMyTweets", %{"userId" => userId}, socket) do
    list=get_my_tweets(userId)
    push socket, "repGetMyTweets", %{"userId" => userId, "list" => list}
    {:noreply, socket}
  end

  def handle_in(event, payload, socket) do
    Logger.warn("unhandled event #{event} #{inspect payload}")
    {:noreply, socket}
  end

  def get_tweets(userId) do
      if :ets.lookup(:tweets, userId) == [] do
          []
      else
          [tup] = :ets.lookup(:tweets, userId)
          elem(tup, 1)
      end
  end

  def get_my_tweets(userId) do
      [tup] = :ets.lookup(:tweets, userId)
      elem(tup, 1)
  end

  def get_subscribed_to(userId) do
      [tup] = :ets.lookup(:subscribedto, userId)
      elem(tup, 1)
  end

  def add_subscribed_to(userId,sub) do
      [tup] = :ets.lookup(:subscribedto, userId)
      list = elem(tup, 1)
      list = [sub | list]
      :ets.insert(:subscribedto, {userId, list})
  end

  def add_followers(userId,foll) do
      if :ets.lookup(:followers, userId) == [], do: :ets.insert(:followers, {userId, []})
      [tup] = :ets.lookup(:followers, userId)
      list = elem(tup, 1)
      list = [foll | list]
      :ets.insert(:followers, {userId, list})
  end

  def process_tweet(tweetString,userId) do
      [tup] = :ets.lookup(:tweets, userId)
      list = elem(tup,1)
      list = [tweetString | list]
      :ets.insert(:tweets,{userId,list})
      
      hashtagsList = Regex.scan(~r/\B#[a-zA-Z0-9_]+/, tweetString) |> Enum.concat
      Enum.each hashtagsList, fn hashtag -> 
        insert_tags(hashtag,tweetString)
      end
      mentionsList = Regex.scan(~r/\B@[a-zA-Z0-9_]+/, tweetString) |> Enum.concat
      Enum.each mentionsList, fn mention -> 
        insert_tags(mention,tweetString)
          userName = String.slice(mention,1, String.length(mention)-1)
          if whereis(userName) != nil, do: push whereis(userName),"live", %{"tweetString" => tweetString}
      end

      [{_,followersList}] = :ets.lookup(:followers, userId)
      Enum.each followersList, fn follower -> 
        if whereis(follower) != nil, do: push whereis(follower),"live", %{"tweetString" => tweetString}
      end
  end

  def insert_tags(tag,tweetString) do
      [tup] = if :ets.lookup(:hashtags_mentions, tag) != [] do
          :ets.lookup(:hashtags_mentions, tag)
      else
          [nil]
      end
      if tup == nil do 
          :ets.insert(:hashtags_mentions,{tag,[tweetString]})
      else
          list = elem(tup,1)
          list = [tweetString | list]
          :ets.insert(:hashtags_mentions,{tag,list})
      end
  end

  def generate_tweet_list([head | tail],tweetlist) do
      tweetlist = get_tweets(head) ++ tweetlist
      generate_tweet_list(tail,tweetlist)
  end

  def generate_tweet_list([],tweetlist), do: tweetlist

  def tweets_with_hashtag(hashTag, _userId) do 
      [tup] = if :ets.lookup(:hashtags_mentions, hashTag) != [] do
          :ets.lookup(:hashtags_mentions, hashTag)
      else
          [{"#",[]}]
      end
      elem(tup, 1)
  end

  def tweets_with_mention(userId) do
      [tup] = if :ets.lookup(:hashtags_mentions, "@" <> userId) != [] do
          :ets.lookup(:hashtags_mentions, "@" <> userId)
      else
          [{"#",[]}]
      end
      elem(tup, 1)
  end
end
