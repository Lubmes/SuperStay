defmodule SuperStayWeb.Admin.BookingLive.Show do
  use SuperStayWeb, :live_view

  alias SuperStay.Bookings

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok, assign(socket, :booking, Bookings.get_booking!(id))}
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    case Bookings.cancel_booking(socket.assigns.booking.id) do
      {:ok, booking} ->
        {:noreply,
         socket
         |> put_flash(:info, "De boeking is geannuleerd en de beschikbaarheid is vrijgegeven.")
         |> push_navigate(to: ~p"/admin/bookings/#{booking.id}")}

      {:error, :already_cancelled} ->
        {:noreply, put_flash(socket, :info, "Deze boeking was al geannuleerd.")}

      _ ->
        {:noreply, put_flash(socket, :error, "De boeking kon niet worden geannuleerd.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main class="mx-auto max-w-4xl px-5 py-10">
        <.link
          navigate={~p"/admin/bookings"}
          class="mb-6 inline-flex items-center gap-2 text-sm font-semibold text-primary hover:underline"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Terug naar boekingen
        </.link>

        <header class="flex flex-wrap items-start justify-between gap-4 border-b border-base-300 pb-6">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-primary">
              Boeking #{@booking.id}
            </p>
            <h1 class="mt-1 text-3xl font-bold">{@booking.guest_name}</h1>
            <p class="mt-1 text-base-content/70">{@booking.guest_email}</p>
          </div>
          <button
            :if={@booking.status != "cancelled"}
            id="cancel-booking"
            type="button"
            phx-click="cancel"
            phx-confirm="Weet je zeker dat je deze boeking wilt annuleren?"
            class="btn btn-error btn-outline"
          >
            Annuleer boeking
          </button>
        </header>

        <dl class="grid gap-x-8 gap-y-5 py-7 sm:grid-cols-2">
          <div>
            <dt class="text-sm text-base-content/60">Status</dt><dd class="mt-1 font-semibold">
              {status_label(@booking.status)}
            </dd>
          </div>
          <div>
            <dt class="text-sm text-base-content/60">Accommodatie</dt><dd class="mt-1 font-semibold">
              {@booking.accommodation.title["nl"] || @booking.accommodation.title["en"]}
            </dd>
          </div>
          <div>
            <dt class="text-sm text-base-content/60">Aankomst</dt><dd class="mt-1">
              {Date.to_iso8601(@booking.start_date)}
            </dd>
          </div>
          <div>
            <dt class="text-sm text-base-content/60">Vertrek</dt><dd class="mt-1">
              {Date.to_iso8601(@booking.end_date)}
            </dd>
          </div>
          <div>
            <dt class="text-sm text-base-content/60">Totaal</dt><dd class="mt-1 font-semibold">
              € {Decimal.to_string(@booking.total_price, :normal)}
            </dd>
          </div>
        </dl>

        <section class="border-t border-base-300 py-6">
          <h2 class="text-xl font-semibold">Extra's</h2>
          <p :if={@booking.booking_addons == []} class="mt-3 text-sm text-base-content/60">
            Geen extra's bij deze boeking.
          </p>
          <ul :if={@booking.booking_addons != []} class="mt-3 divide-y divide-base-300">
            <li :for={line <- @booking.booking_addons} class="flex justify-between gap-4 py-3">
              <span>{line.addon.name["nl"] || line.addon.name["en"]} · {Date.to_iso8601(line.date)}</span>
              <span>Aantal: {line.quantity}</span>
            </li>
          </ul>
        </section>
      </main>
    </Layouts.app>
    """
  end

  defp status_label("confirmed"), do: "Bevestigd"
  defp status_label("cancelled"), do: "Geannuleerd"
  defp status_label(_), do: "In afwachting"
end
