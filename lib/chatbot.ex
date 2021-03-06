defmodule ChatBot do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Ensure my FSM registry has the appropriate buckets
    Stash.Registry.create(Stash.Registry, "www")
    Stash.Registry.create(Stash.Registry, "fb-messenger")

    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(ChatBot.Endpoint, []),
      # Start the Ecto repository
      supervisor(ChatBot.Repo, []),
      # Here you could define other workers and supervisors as children
      # worker(ChatBot.Worker, [arg1, arg2, arg3]),
      # worker(ChatBot.FSM.QA, [["What's your name?", "How old are you?",
      #   "Where do you live?"]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChatBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ChatBot.Endpoint.config_change(changed, removed)
    :ok
  end
end
