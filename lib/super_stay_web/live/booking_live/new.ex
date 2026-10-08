defmodule SuperStayWeb.BookingLive.New do
  use SuperStayWeb, :live_view
  alias SuperStay.{Catalog, Bookings}
  alias SuperStay.Bookings.Booking

  @impl true
  def mount(params, _session, socket) do
    accommodation_id = params["accommodation_id"] || params["id"]

    # We halen de accommodatie op en laden DIRECT de locatie en de bijbehorende add-ons in!
    accommodation =
      SuperStay.Catalog.get_accommodation!(accommodation_id)
      |> SuperStay.Repo.preload(location: :addons)

    # Nu kunnen we de add-ons super simpel en veilig uit de relatie pakken
    addons = accommodation.location.addons

    # 1. Lees de datums uit de URL-parameters (als ze bestaan)
    start_date = case Date.from_iso8601(params["start_date"] || "") do
      {:ok, date} -> date
      _ -> nil
    end

    end_date = case Date.from_iso8601(params["end_date"] || "") do
      {:ok, date} -> date
      _ -> nil
    end

    # 2. Maak de initiële changeset aan met de meegestuurde datums
    booking_attrs = %{
      "start_date" => start_date,
      "end_date" => end_date,
      "accommodation_id" => accommodation.id
    }

    changeset = Bookings.change_booking(%SuperStay.Bookings.Booking{}, booking_attrs)

    {:ok,
     socket
     |> assign(:step, 1)
     |> assign(:accommodation, accommodation)
     |> assign(:addons, addons)
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> assign(:selected_addons, %{})
     |> assign(:warnings, %{})
     |> assign(:dates_available, true)
     |> assign_form(changeset)}
  end


  @impl true
  # Formulier-validatie tijdens het typen in Stap 1
  def handle_event("validate", %{"booking" => booking_params}, socket) do
    changeset =
      %Booking{}
      |> Bookings.change_booking(booking_params)
      |> Map.put(:action, :validate)

    # Update de start- en einddatum live in de staat zodat de kalender-logica meebeweegt
    start_date = case Date.from_iso8601(booking_params["start_date"] || "") do
      {:ok, date} -> date
      _ -> socket.assigns.start_date
    end

    end_date = case Date.from_iso8601(booking_params["end_date"] || "") do
      {:ok, date} -> date
      _ -> socket.assigns.end_date
    end

    {:noreply,
     socket
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("next_step", %{"booking" => booking_params}, socket) do
    # Voeg alle ontbrekende verplichte database-velden tijdelijk als dummy toe
    # zodat Ecto de changeset in deze tussenstap als 'valid' markeert!
    full_params =
      booking_params
      |> Map.put("accommodation_id", socket.assigns.accommodation.id)
      |> Map.put("status", "pending")
      |> Map.put("total_price", "0.00") # Wordt in stap 2 definitief berekend

    changeset =
      %Booking{}
      |> Bookings.change_booking(full_params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      start_date = Date.from_iso8601!(booking_params["start_date"])
      end_date = Date.from_iso8601!(booking_params["end_date"])

      selected_addons = initialize_addons_map(start_date, end_date, socket.assigns.addons)

      {:noreply,
       socket
       |> assign(:step, 2) # GAAT NU WEL NAAR STAP 2!
       |> assign(:start_date, start_date)
       |> assign(:end_date, end_date)
       |> assign(:selected_addons, selected_addons)
       |> assign_form(changeset)}
    else
      # Mocht er toch een echte invoerfout zijn, toon de rode errors op het scherm
      {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end


  @impl true
  # Event om terug te keren naar de kalender vanuit de add-ons pagina
  def handle_event("prev_step", _params, socket) do
    {:noreply, assign(socket, :step, 1)}
  end

  @impl true
  # Event wanneer de gast van Stap 2 naar Stap 3 (Overzicht) gaat
  def handle_event("next_to_review", _params, socket) do
    days = Date.diff(socket.assigns.end_date, socket.assigns.start_date)
    accommodation_price = Decimal.mult(socket.assigns.accommodation.price_per_night, days)

    addons_price = calculate_addons_total(socket.assigns.selected_addons, socket.assigns.addons)
    total_price = Decimal.add(accommodation_price, addons_price)

    {:noreply,
     socket
     |> assign(:step, 3) # Schakel door naar het overzicht!
     |> assign(:total_addons_price, addons_price)
     |> assign(:total_price, total_price)}
  end

  @impl true
  # Event om vanuit het overzicht terug te gaan naar de add-ons
  def handle_event("prev_to_addons", _params, socket) do
    {:noreply, assign(socket, :step, 2)}
  end


  @impl true
  # Event voor de plus- en min-knoppen bij de add-ons per datum
  def handle_event("change_qty", %{"date" => date_str, "addon-id" => addon_id_str, "op" => op}, socket) do
    addon_id = String.to_integer(addon_id_str)
    date = Date.from_iso8601!(date_str)

    current_qty = get_in(socket.assigns.selected_addons, [date_str, addon_id]) || 0
    new_qty = if op == "inc", do: current_qty + 1, else: max(0, current_qty - 1)

    # 1. Update de map los via put_in op de MAP (niet op de socket!)
    updated_selected_addons = put_in(socket.assigns.selected_addons, [date_str, addon_id], new_qty)

    # 2. Sla de map veilig op in de socket via assign/3
    new_socket =
      socket
      |> assign(:selected_addons, updated_selected_addons)
      |> validate_stock_for_day(date_str, date, addon_id, new_qty)

    {:noreply, new_socket}
  end


  @impl true
  # Event voor de "Pas toe op alle dagen" snelkeuze-knop
  def handle_event("apply_all_days", %{"addon-id" => addon_id_str, "qty" => qty_str}, socket) do
    addon_id = String.to_integer(addon_id_str)
    qty = String.to_integer(qty_str)

    days = Date.range(socket.assigns.start_date, Date.add(socket.assigns.end_date, -1))

    # We passen de wijzigingen eerst toe op de losse map
    updated_addons = Enum.reduce(days, socket.assigns.selected_addons, fn date, acc_map ->
      date_str = Date.to_string(date)
      put_in(acc_map, [date_str, addon_id], qty)
    end)

    # Daarna voeren we de voorraadchecks uit over de socket
    new_socket = assign(socket, :selected_addons, updated_addons)

    checked_socket = Enum.reduce(days, new_socket, fn date, acc_socket ->
      date_str = Date.to_string(date)
      validate_stock_for_day(acc_socket, date_str, date, addon_id, qty)
    end)

    {:noreply, checked_socket}
  end


  @impl true
  # Gewijzigd naar een algemene click-handler!
  def handle_event("save", _params, socket) do
    # Verkrijg de ingevulde gegevens rechtstreeks uit de changeset die we in stap 1 hebben bewaard
    booking_params = socket.assigns.form.params

    days = Date.diff(socket.assigns.end_date, socket.assigns.start_date)
    accommodation_price = Decimal.mult(socket.assigns.accommodation.price_per_night, days)

    # Bereken de prijs van alle geselecteerde extra's over alle dagen
    addons_price = calculate_addons_total(socket.assigns.selected_addons, socket.assigns.addons)
    total_price = Decimal.add(accommodation_price, addons_price)

    # Voeg de definitieve berekende totaalprijs en de juiste relaties samen
    extended_params =
      booking_params
      |> Map.put("total_price", total_price)
      |> Map.put("accommodation_id", socket.assigns.accommodation.id)
      |> Map.put("status", "confirmed") # Direct bevestigd!

    # Sla alles op via onze database-transactie
    case Bookings.create_booking_with_addons(extended_params, socket.assigns.selected_addons) do
      {:ok, _booking} ->
        {:noreply,
         socket
         |> put_flash(:info, "🎉 Boeking succesvol geplaatst!")
         |> redirect(to: "/")}

      {:error, message} when is_binary(message) ->
        {:noreply, put_flash(socket, :error, message)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end


    # --- PRIVATE HELPERS ---

  # Zorgt dat de waarschuwingen netjes als string-keys worden opgeslagen
  defp validate_stock_for_day(socket, date_str, date, addon_id, qty) do
    if Bookings.stock_available?(addon_id, date, qty) do
      new_warnings = Map.update(socket.assigns.warnings, date_str, %{}, &Map.delete(&1, addon_id))
      assign(socket, :warnings, new_warnings)
    else
      available = Bookings.get_available_stock(addon_id, date)
      msg = "Slechts #{available} beschikbaar"

      current_date_warnings = Map.get(socket.assigns.warnings, date_str, %{})
      new_date_warnings = Map.put(current_date_warnings, addon_id, msg)

      new_warnings = Map.put(socket.assigns.warnings, date_str, new_date_warnings)
      assign(socket, :warnings, new_warnings)
    end
  end

  # Belangrijk: Date.range genereert een lijst van Date structs.
  # We zetten deze DIRECT om naar Strings, zodat de template ze kan vinden!
  defp initialize_addons_map(start_date, end_date, addons) do
    Date.range(start_date, Date.add(end_date, -1))
    |> Enum.map(&Date.to_string/1) # Zet alle datums om naar "YYYY-MM-DD" strings
    |> Map.new(fn date_str ->
      {date_str, Map.new(addons, fn a -> {a.id, 0} end)}
    end)
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  # Telt de prijzen van alle gekozen add-ons bij elkaar op (veilig met string-keys)
  defp calculate_addons_total(selected_addons, addons_catalog) do
    Enum.reduce(selected_addons, Decimal.new(0), fn {_date_str, addons}, acc ->
      Enum.reduce(addons, acc, fn {id, qty}, i_acc ->
        addon = Enum.find(addons_catalog, &(&1.id == id))
        Decimal.add(i_acc, Decimal.mult(addon.price, qty))
      end)
    end)
  end

end
