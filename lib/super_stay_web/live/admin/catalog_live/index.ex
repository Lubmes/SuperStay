defmodule SuperStayWeb.Admin.CatalogLive.Index do
  use SuperStayWeb, :live_view

  alias SuperStay.Catalog

  @tabs ["accommodations", "addons"]

  @impl true
  def mount(_params, _session, socket) do
    locations = Catalog.list_catalog_by_location()
    active_tabs = Map.new(locations, &{Integer.to_string(&1.id), "accommodations"})

    {:ok,
     socket
     |> assign(:locations, locations)
     |> assign(:active_tabs, active_tabs)}
  end

  @impl true
  def handle_event(
        "select_location_tab",
        %{"location-id" => location_id, "tab" => tab},
        socket
      )
      when tab in @tabs do
    if Map.has_key?(socket.assigns.active_tabs, location_id) do
      {:noreply, update(socket, :active_tabs, &Map.put(&1, location_id, tab))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main class="mx-auto max-w-6xl px-5 py-8 sm:py-10">
        <header class="mb-7 flex flex-wrap items-end justify-between gap-4 border-b border-base-300 pb-5">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-primary">Beheer</p>
            <h1 class="mt-1 text-3xl font-bold">Catalogus</h1>
          </div>
          <.link navigate={~p"/admin/catalog/locations/new"} class="btn btn-sm btn-outline">
            Locatie toevoegen
          </.link>
        </header>

        <p
          :if={@locations == []}
          id="catalog-locations-empty"
          class="py-10 text-center text-base-content/60"
        >
          Voeg eerst een locatie toe.
        </p>

        <section
          :for={location <- @locations}
          id={"catalog-location-#{location.id}"}
          class="border-t border-base-300 py-5"
        >
          <header class="mb-4 flex flex-wrap items-center justify-between gap-3">
            <h2 class="text-xl font-semibold">{translated(location.name)}</h2>
            <.link
              navigate={~p"/admin/catalog/locations/#{location.id}"}
              class="btn btn-xs btn-outline"
            >
              Locatie bewerken
            </.link>
          </header>

          <div
            id={"location-tabs-#{location.id}"}
            role="tablist"
            aria-label={"Catalogus voor #{translated(location.name)}"}
            class="mb-4 inline-flex gap-1 rounded-md border border-base-300 bg-base-200 p-1"
          >
            <button
              id={"location-#{location.id}-tab-accommodations"}
              type="button"
              role="tab"
              aria-selected={
                Map.get(@active_tabs, Integer.to_string(location.id)) == "accommodations"
              }
              class={[
                "min-h-10 min-w-32 rounded px-4 py-2 text-sm font-medium transition-colors",
                Map.get(@active_tabs, Integer.to_string(location.id)) == "accommodations" &&
                  "bg-base-100 text-base-content shadow-sm",
                Map.get(@active_tabs, Integer.to_string(location.id)) != "accommodations" &&
                  "text-base-content/65 hover:bg-base-300 hover:text-base-content"
              ]}
              phx-click="select_location_tab"
              phx-value-location-id={location.id}
              phx-value-tab="accommodations"
            >Accommodaties</button>
            <button
              id={"location-#{location.id}-tab-addons"}
              type="button"
              role="tab"
              aria-selected={Map.get(@active_tabs, Integer.to_string(location.id)) == "addons"}
              class={[
                "min-h-10 min-w-32 rounded px-4 py-2 text-sm font-medium transition-colors",
                Map.get(@active_tabs, Integer.to_string(location.id)) == "addons" &&
                  "bg-base-100 text-base-content shadow-sm",
                Map.get(@active_tabs, Integer.to_string(location.id)) != "addons" &&
                  "text-base-content/65 hover:bg-base-300 hover:text-base-content"
              ]}
              phx-click="select_location_tab"
              phx-value-location-id={location.id}
              phx-value-tab="addons"
            >Add-ons</button>
          </div>

          <section
            :if={Map.get(@active_tabs, Integer.to_string(location.id)) == "accommodations"}
            id={"location-#{location.id}-panel-accommodations"}
            role="tabpanel"
            aria-labelledby={"location-#{location.id}-tab-accommodations"}
          >
            <div class="mb-3 flex justify-end">
              <.link
                id={"add-accommodation-for-#{location.id}"}
                navigate={~p"/admin/catalog/accommodations/new?location_id=#{location.id}"}
                class="btn btn-xs btn-primary"
              >
                Accommodatie toevoegen
              </.link>
            </div>
            <div :if={location.accommodations == []} class="py-3 text-sm text-base-content/60">
              Nog geen accommodaties op deze locatie.
            </div>
            <article
              :for={accommodation <- location.accommodations}
              id={"catalog-accommodation-#{accommodation.id}"}
              class="border-t border-base-200 py-4 sm:pl-4"
            >
              <div class="flex flex-wrap items-start justify-between gap-3">
                <div class="min-w-0">
                  <h3 class="font-semibold">{translated(accommodation.title)}</h3>
                  <p class="mt-1 text-sm text-base-content/65">
                    {type_label(accommodation.type)} · {accommodation.max_guests} gasten · €{Decimal.to_string(
                      accommodation.price_per_night,
                      :normal
                    )} per nacht
                  </p>
                </div>
                <div class="flex shrink-0 gap-2">
                  <.link
                    navigate={~p"/admin/catalog/accommodations/#{accommodation.id}"}
                    class="btn btn-xs btn-outline"
                  >
                    Bewerken
                  </.link>
                  <.link
                    navigate={~p"/admin/catalog/images/new?accommodation_id=#{accommodation.id}"}
                    class="btn btn-xs btn-ghost"
                  >
                    Afbeelding toevoegen
                  </.link>
                </div>
              </div>

              <ul :if={accommodation.images != []} class="mt-3 space-y-2 sm:pl-3">
                <li
                  :for={image <- accommodation.images}
                  id={"catalog-image-#{image.id}"}
                  class="flex flex-wrap items-center justify-between gap-2 text-sm"
                >
                  <span class="min-w-0 truncate text-base-content/70">
                    {(image.caption && translated(image.caption)) || image.url}
                  </span>
                  <.link navigate={~p"/admin/catalog/images/#{image.id}"} class="link link-primary">
                    Afbeelding bewerken
                  </.link>
                </li>
              </ul>
            </article>
          </section>

          <section
            :if={Map.get(@active_tabs, Integer.to_string(location.id)) == "addons"}
            id={"location-#{location.id}-panel-addons"}
            role="tabpanel"
            aria-labelledby={"location-#{location.id}-tab-addons"}
          >
            <div class="mb-3 flex justify-end">
              <.link
                id={"add-addon-for-#{location.id}"}
                navigate={~p"/admin/catalog/addons/new?location_id=#{location.id}"}
                class="btn btn-xs btn-primary"
              >
                Add-on toevoegen
              </.link>
            </div>
            <div :if={location.addons == []} class="py-3 text-sm text-base-content/60">
              Nog geen add-ons op deze locatie.
            </div>
            <article
              :for={addon <- location.addons}
              id={"catalog-addon-#{addon.id}"}
              class="flex flex-wrap items-center justify-between gap-3 border-t border-base-200 py-3 sm:pl-4"
            >
              <div class="min-w-0">
                <h3 class="font-semibold">{translated(addon.name)}</h3>
                <p class="mt-1 text-sm text-base-content/65">
                  €{Decimal.to_string(addon.price, :normal)} · {if is_nil(addon.stock),
                    do: "Onbeperkte voorraad",
                    else: "Voorraad: #{addon.stock}"}
                </p>
              </div>
              <.link navigate={~p"/admin/catalog/addons/#{addon.id}"} class="btn btn-xs btn-outline">
                Bewerken
              </.link>
            </article>
          </section>
        </section>
      </main>
    </Layouts.app>
    """
  end

  defp translated(map), do: Map.get(map, "nl") || Map.get(map, :nl) || Map.get(map, "en") || ""

  defp type_label("house"), do: "Huis"
  defp type_label("room"), do: "Kamer"
  defp type_label("apartment"), do: "Appartement"
  defp type_label(type), do: type
end
