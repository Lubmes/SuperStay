defmodule SuperStayWeb.AccommodationLive.Index do
  use SuperStayWeb, :live_view
  alias SuperStay.Catalog

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:start_date, nil)
     |> assign(:end_date, nil)
     |> assign(:accommodations, Catalog.list_available_accommodations(nil, nil))}
  end

  @impl true
  # Dit event vuurt direct zodra de gast typt of een datum aanklikt in de zoekbalk
  def handle_event("filter_dates", %{"start_date" => start_str, "end_date" => end_str}, socket) do
    # Probeer de datums veilig om te zetten van string naar Ecto Date objecten
    start_date = case Date.from_iso8601(start_str) do
      {:ok, date} -> date
      _ -> nil
    end

    end_date = case Date.from_iso8601(end_str) do
      {:ok, date} -> date
      _ -> nil
    end

    # Haal de live gefilterde lijst op uit de catalogus
    accommodations = Catalog.list_available_accommodations(start_date, end_date)

    {:noreply,
     socket
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> assign(:accommodations, accommodations)}
  end
end
