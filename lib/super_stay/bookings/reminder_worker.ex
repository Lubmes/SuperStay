defmodule SuperStay.Bookings.ReminderWorker do
  use GenServer

  alias SuperStay.Bookings

  @interval :timer.minutes(15)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    send(self(), :send_reminders)
    {:ok, nil}
  end

  @impl true
  def handle_info(:send_reminders, state) do
    Bookings.send_due_reminders(Date.utc_today())
    Process.send_after(self(), :send_reminders, @interval)
    {:noreply, state}
  end
end
