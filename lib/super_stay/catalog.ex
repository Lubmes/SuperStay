defmodule SuperStay.Catalog do
  import Ecto.Query, warn: false
  alias SuperStay.Repo
  alias SuperStay.Catalog.{Location, Accommodation}
  alias SuperStay.Bookings.Booking

  # Locaties
  def list_locations, do: Repo.all(Location)

  def create_location(attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  # Accommodaties
  def list_accommodations do
    Accommodation
    |> Repo.all()
    |> Repo.preload([:location, :images])
  end

  def create_accommodation(attrs \\ %{}) do
    %Accommodation{}
    |> Accommodation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Haalt alle accommodaties op uit de database, inclusief hun gekoppelde locatiegegevens.
  """
  def list_accommodations_with_locations do
    Accommodation
    |> Repo.all()
    |> Repo.preload(:location)
  end

  @doc """
  Haalt een specifieke accommodatie op via zijn ID, inclusief de overkoepelende locatiegegevens.
  Werpt een Ecto.NoResultsError op als er niets wordt gevonden.
  """
  def get_accommodation!(id) do
    Accommodation
    |> Repo.get!(id)
    |> Repo.preload(:location)
  end

  @doc """
  Haalt een specifieke locatie op inclusief alle bijbehorende add-ons (extra's) die bij dit park/hotel horen.
  """
  def get_location_with_addons!(id) do
    Location
    |> Repo.get!(id)
    |> Repo.preload(:addons)
  end

  @doc """
  Haalt accommodaties op. Als er datums worden meegegeven, worden alleen de
  verblijven getoond die in die periode volledig vrij zijn van andere confirmed boekingen.
  """
  def list_available_accommodations(start_date \\ nil, end_date \\ nil)

  # Als er geen datums zijn ingevuld (of ze zijn leeg): toon ALLES
  def list_available_accommodations(nil, _), do: list_accommodations_with_locations()
  def list_available_accommodations(_, nil), do: list_accommodations_with_locations()

  # Veilig hernoemd naar start_date en end_date zodat Elixir niet meer crasht op het woord 'end'
  def list_available_accommodations(%Date{} = start_date, %Date{} = end_date) do
    # 1. Zoek eerst alle accommodatie_ids die BEZET zijn in deze periode
    busy_ids_query =
      from b in Booking,
        where: b.status == "confirmed",
        where: b.start_date < ^end_date and b.end_date > ^start_date,
        select: b.accommodation_id

    # 2. Geef alle accommodaties terug waarvan het ID NIET in de bezette lijst staat
    from(a in Accommodation,
      where: a.id not in subquery(busy_ids_query),
      preload: [:location]
    )
    |> Repo.all()
  end

end
