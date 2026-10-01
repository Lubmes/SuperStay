defmodule SuperStay.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SuperStayWeb.Telemetry,
      SuperStay.Repo,
      {DNSCluster, query: Application.get_env(:super_stay, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SuperStay.PubSub},
      # Start a worker by calling: SuperStay.Worker.start_link(arg)
      # {SuperStay.Worker, arg},
      # Start to serve requests, typically the last entry
      SuperStayWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SuperStay.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SuperStayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
