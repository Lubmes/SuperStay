defmodule SuperStay.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        SuperStayWeb.Telemetry,
        SuperStay.Repo,
        {DNSCluster, query: Application.get_env(:super_stay, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: SuperStay.PubSub}
      ] ++
        if(Application.get_env(:super_stay, :start_reminder_worker, true),
          do: [SuperStay.Bookings.ReminderWorker],
          else: []
        ) ++ [SuperStayWeb.Endpoint]

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
