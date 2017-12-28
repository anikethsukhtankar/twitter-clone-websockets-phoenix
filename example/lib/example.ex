defmodule Example do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    :ets.new(:clientsregistry, [:set, :public, :named_table])
    :ets.new(:tweets, [:set, :public, :named_table])
    :ets.new(:hashtags_mentions, [:set, :public, :named_table])
    :ets.new(:subscribedto, [:set, :public, :named_table])
    :ets.new(:followers, [:set, :public, :named_table])

    children = [
      # Start the endpoint when the application starts
      supervisor(ExampleWeb.Endpoint, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Example.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  # def config_change(changed, _new, removed) do
  #   Example.Endpoint.config_change(changed, removed)
  #   :ok
  # end
end
