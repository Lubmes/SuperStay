defmodule SuperStay.Bookings do
  import Ecto.Query, warn: false
  alias SuperStay.Repo
  alias SuperStay.Bookings.{Booking, Addon, BookingAddon}

  # Addons catalogus
  def create_addon(attrs \\ %{}) do
    %Addon{}
    |> Addon.changeset(attrs)
    |> Repo.insert()
  end

  # Boekingen
  def create_booking(attrs \\ %{}) do
    %Booking{}
    |> Booking.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Voegt een add-on toe aan een boeking voor een specifieke dag.
  """
  def add_addon_to_booking(booking_id, addon_id, date, quantity \\ 1) do
    %BookingAddon{}
    |> BookingAddon.changeset(%{
      booking_id: booking_id,
      addon_id: addon_id,
      date: date,
      quantity: quantity
    })
    |> Repo.insert()
  end

  @doc """
  Haalt een boeking op inclusief alle gekoppelde dag-extra's.
  """
  def get_booking!(id) do
    Booking
    |> Repo.get!(id)
    |> Repo.preload([:accommodation, booking_addons: :addon])
  end


  @doc """
  Berekent de resterende beschikbare voorraad van een add-on op een specifieke datum.
  Als het een oneindig product is (stock is nil), geeft het :infinite terug.
  """
  def get_available_stock(addon_id, %Date{} = date) do
    addon = Repo.get!(Addon, addon_id)

    case addon.stock do
      nil ->
        :infinite

      max_stock ->
        # Bereken hoeveel er al gereserveerd zijn voor deze specifieke dag
        already_booked =
          Repo.one(
            from ba in BookingAddon,
              where: ba.addon_id == ^addon_id and ba.date == ^date,
              select: sum(ba.quantity)
          ) || 0

        # Beschikbare voorraad kan nooit negatief zijn
        max(0, max_stock - already_booked)
    end
  end

  @doc """
  Controleert of een specifieke hoeveelheid (quantity) van een add-on nog beschikbaar is op een datum.
  Gefft true als het past, anders false.
  """
  def stock_available?(addon_id, %Date{} = date, requested_quantity) do
    case get_available_stock(addon_id, date) do
      :infinite -> true
      available -> requested_quantity <= available
    end
  end


  @doc """
  Slaat een boeking en alle gekoppelde add-ons per dag veilig op in een transactie.
  Valideert de actuele voorraad vlak voor het opslaan.
  """
  def create_booking_with_addons(booking_attrs, selected_addons_map) do
    Repo.transaction(fn ->
      # 1. Maak de basis boeking aan
      case create_booking(booking_attrs) do
        {:ok, booking} ->
          # 2. Loop door alle geselecteerde add-ons per dag heen
          # selected_addons_map structuur: %{ "2026-10-05" => %{addon_id => quantity} }
          for {date_str, addons} <- selected_addons_map,
              {addon_id_str, quantity} <- addons,
              quantity > 0 do

            date = Date.from_iso8601!(date_str)
            addon_id = String.to_integer(to_string(addon_id_str))

            # 3. Last-minute voorraad check in de database
            if stock_available?(addon_id, date, quantity) do
              # Sla de regel op
              {:ok, _} = add_addon_to_booking(booking.id, addon_id, date, quantity)
            else
              # Als er inmiddels te weinig voorraad is, breken we de hele transactie af
              addon = Repo.get!(Addon, addon_id)
              Repo.rollback("Helaas zijn er niet genoeg stuks meer beschikbaar van '#{addon.name["nl"]}' op #{date}.")
            end
          end

          booking

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Genereert een changeset om een boeking te kunnen wijzigen of te tonen in een formulier.
  """
  def change_booking(%Booking{} = booking, attrs \\ %{}) do
    Booking.changeset(booking, attrs)
  end

end
