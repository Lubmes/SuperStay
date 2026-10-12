defmodule SuperStayWeb.Admin.BookingLive.Index do
  use SuperStayWeb, :live_view

  alias SuperStay.Bookings

  @impl true
  def mount(params, _session, socket) do
    search = Map.get(params, "q", "")

    {:ok,
     socket
     |> assign(:search_form, to_form(%{"query" => search}, as: :search))
     |> stream(:bookings, Bookings.list_bookings(search))}
  end

  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    {:noreply,
     socket
     |> assign(:search_form, to_form(%{"query" => query}, as: :search))
     |> stream(:bookings, Bookings.list_bookings(query), reset: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main class="mx-auto max-w-6xl px-5 py-10">
        <header class="mb-8 flex flex-wrap items-end justify-between gap-4 border-b border-base-300 pb-5">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-primary">Beheer</p>
            <h1 class="mt-1 text-3xl font-bold">Boekingen</h1>
          </div>
          <.form
            for={@search_form}
            id="booking-search"
            phx-change="search"
            phx-submit="search"
            class="w-full max-w-sm"
          >
            <.input
              field={@search_form[:query]}
              type="search"
              label="Zoek gastnaam"
              placeholder="Naam of deel van naam"
              phx-debounce="250"
            />
          </.form>
        </header>

        <div id="booking-list" class="divide-y divide-base-300" phx-update="stream">
          <p id="booking-list-empty" class="hidden only:block py-10 text-center text-base-content/60">
            Geen boekingen gevonden.
          </p>
          <article
            :for={{dom_id, booking} <- @streams.bookings}
            id={dom_id}
            class="grid gap-3 py-5 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-center"
          >
            <div class="min-w-0">
              <h2 class="truncate text-lg font-semibold">{booking.guest_name}</h2>
              <p class="text-sm text-base-content/70">
                {booking.accommodation.title["nl"] || booking.accommodation.title["en"]}
              </p>
              <p class="mt-1 text-sm">
                {Date.to_iso8601(booking.start_date)} tot {Date.to_iso8601(booking.end_date)}
              </p>
            </div>
            <div class="flex items-center gap-4 sm:justify-end">
              <span class={status_class(booking.status)}>{status_label(booking.status)}</span>
              <.link navigate={~p"/admin/bookings/#{booking.id}"} class="btn btn-sm btn-outline">Details</.link>
            </div>
          </article>
        </div>
      </main>
    </Layouts.app>
    """
  end

  defp status_label("confirmed"), do: "Bevestigd"
  defp status_label("cancelled"), do: "Geannuleerd"
  defp status_label(_), do: "In afwachting"

  defp status_class("confirmed"), do: "badge badge-success"
  defp status_class("cancelled"), do: "badge badge-ghost"
  defp status_class(_), do: "badge badge-warning"
end
