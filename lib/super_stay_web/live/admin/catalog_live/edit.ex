defmodule SuperStayWeb.Admin.CatalogLive.Edit do
  use SuperStayWeb, :live_view

  alias SuperStay.Catalog
  alias SuperStay.Catalog.{Location, Accommodation, Addon, AccommodationImage}

  @types ["locations", "accommodations", "addons", "images"]

  @impl true
  def mount(%{"type" => type, "id" => id} = route_params, _session, socket)
      when type in @types do
    new? = id == "new"
    item = load_item(type, id, new?)
    title = if new?, do: "Nieuw", else: "Bewerken"

    form_values =
      form_params(type, item)
      |> maybe_set_location(type, new?, route_params["location_id"])

    {:ok,
     socket
     |> assign(:type, type)
     |> assign(:item, item)
     |> assign(:new?, new?)
     |> assign(:title, title)
     |> assign(:form, to_form(form_values, as: :item))
     |> assign(:location_options, location_options())
     |> assign(:accommodation_options, accommodation_options())}
  end

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: ~p"/admin/catalog")}
  end

  @impl true
  def handle_event("save", %{"item" => params}, socket) do
    type = socket.assigns.type
    attrs = build_attrs(type, params)

    result =
      if socket.assigns.new? do
        create_item(type, attrs)
      else
        update_item(type, socket.assigns.item, attrs)
      end

    case result do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Catalogusitem opgeslagen.")
         |> push_navigate(to: ~p"/admin/catalog")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(params, as: :item))
         |> put_flash(:error, "Controleer de verplichte velden en Nederlandse vertaling.")}
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    case delete_item(socket.assigns.type, socket.assigns.item) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Catalogusitem verwijderd.")
         |> push_navigate(to: ~p"/admin/catalog")}

      {:error, :in_use} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Dit item is nog gekoppeld aan andere catalogusitems of boekingen."
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Catalogusitem kon niet worden verwijderd.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main class="mx-auto max-w-3xl px-5 py-10">
        <.link
          navigate={~p"/admin/catalog"}
          class="mb-6 inline-flex items-center gap-2 text-sm font-semibold text-primary hover:underline"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Terug naar catalogus
        </.link>
        <header class="mb-7 border-b border-base-300 pb-5">
          <p class="text-sm font-semibold uppercase tracking-wide text-primary">Catalogusbeheer</p>
          <h1 class="mt-1 text-3xl font-bold">{@title} {type_label(@type)}</h1>
        </header>

        <.form for={@form} id="catalog-item-form" phx-submit="save" class="space-y-4">
          <%= case @type do %>
            <% "locations" -> %>
              <.input field={@form[:name_nl]} label="Naam (Nederlands)" />
              <.input field={@form[:name_en]} label="Naam (Engels)" />
              <.input
                field={@form[:type]}
                type="select"
                label="Type locatie"
                options={[
                  {"Vakantiepark", "holiday_park"},
                  {"Hotel", "hotel"},
                  {"Individuele accommodatie", "individual_property"}
                ]}
                prompt="Kies een type"
              />
              <div class="grid gap-4 sm:grid-cols-2">
                <.input field={@form[:latitude]} type="number" step="any" label="Breedtegraad" />
                <.input field={@form[:longitude]} type="number" step="any" label="Lengtegraad" />
              </div>
            <% "accommodations" -> %>
              <.input field={@form[:title_nl]} label="Titel (Nederlands)" />
              <.input field={@form[:title_en]} label="Titel (Engels)" />
              <.input
                field={@form[:description_nl]}
                type="textarea"
                label="Beschrijving (Nederlands)"
              />
              <.input field={@form[:description_en]} type="textarea" label="Beschrijving (Engels)" />
              <.input
                field={@form[:type]}
                type="select"
                label="Type accommodatie"
                options={[{"Huis", "house"}, {"Kamer", "room"}, {"Appartement", "apartment"}]}
                prompt="Kies een type"
              />
              <.input
                field={@form[:location_id]}
                type="select"
                label="Locatie"
                options={@location_options}
                prompt="Kies een locatie"
              />
              <div class="grid gap-4 sm:grid-cols-2">
                <.input field={@form[:max_guests]} type="number" label="Maximaal aantal gasten" />
                <.input
                  field={@form[:price_per_night]}
                  type="number"
                  step="0.01"
                  label="Prijs per nacht"
                />
              </div>
            <% "addons" -> %>
              <.input field={@form[:name_nl]} label="Naam (Nederlands)" />
              <.input field={@form[:name_en]} label="Naam (Engels)" />
              <.input
                field={@form[:location_id]}
                type="select"
                label="Locatie"
                options={@location_options}
                prompt="Kies een locatie"
              />
              <div class="grid gap-4 sm:grid-cols-2">
                <.input field={@form[:price]} type="number" step="0.01" label="Prijs" />
                <.input field={@form[:stock]} type="number" label="Voorraad (leeg is onbeperkt)" />
              </div>
            <% "images" -> %>
              <.input field={@form[:url]} type="url" label="Afbeeldings-URL" />
              <.input field={@form[:caption_nl]} label="Bijschrift (Nederlands)" />
              <.input field={@form[:caption_en]} label="Bijschrift (Engels)" />
              <.input
                field={@form[:accommodation_id]}
                type="select"
                label="Accommodatie"
                options={@accommodation_options}
                prompt="Kies een accommodatie"
              />
              <.input field={@form[:position]} type="number" label="Volgorde" />
          <% end %>
          <div class="flex flex-wrap gap-3 border-t border-base-300 pt-5">
            <.button id="save-catalog-item" class="btn btn-primary">Opslaan</.button>
            <button
              :if={!@new?}
              id="delete-catalog-item"
              type="button"
              phx-click="delete"
              phx-confirm="Weet je zeker dat je dit catalogusitem wilt verwijderen?"
              class="btn btn-error btn-outline"
            >Verwijderen</button>
          </div>
        </.form>
      </main>
    </Layouts.app>
    """
  end

  defp load_item("locations", _id, true), do: %Location{}
  defp load_item("locations", id, false), do: Catalog.get_location!(id)
  defp load_item("accommodations", _id, true), do: %Accommodation{}
  defp load_item("accommodations", id, false), do: Catalog.get_accommodation_for_admin!(id)
  defp load_item("addons", _id, true), do: %Addon{}
  defp load_item("addons", id, false), do: Catalog.get_addon!(id)
  defp load_item("images", _id, true), do: %AccommodationImage{}
  defp load_item("images", id, false), do: Catalog.get_accommodation_image!(id)

  defp maybe_set_location(params, "accommodations", true, location_id)
       when is_binary(location_id),
       do: Map.put(params, "location_id", location_id)

  defp maybe_set_location(params, "addons", true, location_id) when is_binary(location_id),
    do: Map.put(params, "location_id", location_id)

  defp maybe_set_location(params, _type, _new?, _location_id), do: params

  defp form_params("locations", item),
    do:
      translated_params(
        %{"type" => item.type, "latitude" => item.latitude, "longitude" => item.longitude},
        "name",
        item.name
      )

  defp form_params("accommodations", item) do
    item
    |> Map.take([:type, :max_guests, :price_per_night, :location_id])
    |> stringify_keys()
    |> Map.merge(translated_params(%{}, "title", item.title))
    |> Map.merge(translated_params(%{}, "description", item.description))
  end

  defp form_params("addons", item) do
    item
    |> Map.take([:price, :stock, :location_id])
    |> stringify_keys()
    |> Map.merge(translated_params(%{}, "name", item.name))
  end

  defp form_params("images", item) do
    item
    |> Map.take([:url, :position, :accommodation_id])
    |> stringify_keys()
    |> Map.merge(translated_params(%{}, "caption", item.caption))
  end

  defp translated_params(attrs, field, map) do
    attrs
    |> Map.put("#{field}_nl", translated_value(map, "nl"))
    |> Map.put("#{field}_en", translated_value(map, "en"))
  end

  defp translated_value(map, locale) when is_map(map), do: Map.get(map, locale) || ""
  defp translated_value(_, _), do: ""

  defp stringify_keys(map), do: Map.new(map, fn {key, value} -> {to_string(key), value} end)

  defp build_attrs(type, params) when type in ["locations", "addons"] do
    params
    |> Map.put("name", %{"nl" => params["name_nl"], "en" => params["name_en"]})
    |> Map.drop(["name_nl", "name_en"])
  end

  defp build_attrs("accommodations", params) do
    params
    |> Map.put("title", %{"nl" => params["title_nl"], "en" => params["title_en"]})
    |> Map.put("description", %{
      "nl" => params["description_nl"],
      "en" => params["description_en"]
    })
    |> Map.drop(["title_nl", "title_en", "description_nl", "description_en"])
  end

  defp build_attrs("images", params) do
    params
    |> Map.put("caption", %{"nl" => params["caption_nl"], "en" => params["caption_en"]})
    |> Map.drop(["caption_nl", "caption_en"])
  end

  defp create_item("locations", attrs), do: Catalog.create_location(attrs)
  defp create_item("accommodations", attrs), do: Catalog.create_accommodation(attrs)
  defp create_item("addons", attrs), do: Catalog.create_addon(attrs)
  defp create_item("images", attrs), do: Catalog.create_accommodation_image(attrs)

  defp update_item("locations", item, attrs), do: Catalog.update_location(item, attrs)
  defp update_item("accommodations", item, attrs), do: Catalog.update_accommodation(item, attrs)
  defp update_item("addons", item, attrs), do: Catalog.update_addon(item, attrs)
  defp update_item("images", item, attrs), do: Catalog.update_accommodation_image(item, attrs)

  defp delete_item("locations", item), do: Catalog.delete_location(item)
  defp delete_item("accommodations", item), do: Catalog.delete_accommodation(item)
  defp delete_item("addons", item), do: Catalog.delete_addon(item)
  defp delete_item("images", item), do: Catalog.delete_accommodation_image(item)

  defp location_options do
    Enum.map(Catalog.list_locations(), &{translated(&1.name), &1.id})
  end

  defp accommodation_options do
    Enum.map(Catalog.list_accommodations(), &{translated(&1.title), &1.id})
  end

  defp translated(map), do: translated_value(map, "nl")

  defp type_label("locations"), do: "locatie"
  defp type_label("accommodations"), do: "accommodatie"
  defp type_label("addons"), do: "extra"
  defp type_label("images"), do: "afbeelding"
end
