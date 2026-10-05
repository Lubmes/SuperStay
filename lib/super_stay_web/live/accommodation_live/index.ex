defmodule SuperStayWeb.AccommodationLive.Index do
  use SuperStayWeb, :live_view
  alias SuperStay.Catalog

  def mount(_params, _session, socket) do
    # Haal alle accommodaties op, inclusief hun overkoepelende locatiegegevens
    accommodations = Catalog.list_accommodations_with_locations()

    {:ok, assign(socket, :accommodations, accommodations)}
  end
end
