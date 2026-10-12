defmodule SuperStay.Catalog do
  import Ecto.Query, warn: false
  alias SuperStay.Repo
  alias SuperStay.Catalog.{Location, Accommodation, AccommodationImage, Addon}
  alias SuperStay.Bookings.{Booking, BookingAddon}

  # Locaties
  def list_locations, do: Repo.all(Location)

  def get_location!(id), do: Repo.get!(Location, id)

  def create_location(attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  def list_catalog_by_location do
    Location
    |> Repo.all()
    |> Repo.preload(accommodations: :images, addons: [])
  end

  def update_location(location, attrs), do: location |> Location.changeset(attrs) |> Repo.update()

  def delete_location(%Location{id: id} = location) do
    if Repo.exists?(from a in Accommodation, where: a.location_id == ^id) or
         Repo.exists?(from a in Addon, where: a.location_id == ^id) do
      {:error, :in_use}
    else
      Repo.delete(location)
    end
  end

  # Add-ons
  def list_addons, do: Repo.all(Addon)

  def get_addon!(id), do: Repo.get!(Addon, id)

  def create_addon(attrs \\ %{}) do
    %Addon{}
    |> Addon.changeset(attrs)
    |> Repo.insert()
  end

  def update_addon(addon, attrs), do: addon |> Addon.changeset(attrs) |> Repo.update()

  def delete_addon(%Addon{id: id} = addon) do
    if Repo.exists?(from ba in BookingAddon, where: ba.addon_id == ^id) do
      {:error, :in_use}
    else
      Repo.delete(addon)
    end
  end

  # Accommodaties
  def list_accommodations do
    Accommodation
    |> Repo.all()
    |> Repo.preload([:location, :images])
  end

  def get_accommodation_for_admin!(id) do
    Accommodation
    |> Repo.get!(id)
    |> Repo.preload(:images)
  end

  def create_accommodation(attrs \\ %{}) do
    %Accommodation{}
    |> Accommodation.changeset(attrs)
    |> Repo.insert()
  end

  def update_accommodation(accommodation, attrs) do
    accommodation |> Accommodation.changeset(attrs) |> Repo.update()
  end

  def delete_accommodation(%Accommodation{id: id} = accommodation) do
    if Repo.exists?(from b in Booking, where: b.accommodation_id == ^id) do
      {:error, :in_use}
    else
      Repo.delete(accommodation)
    end
  end

  def list_accommodation_images do
    AccommodationImage
    |> order_by([image], asc: image.position)
    |> Repo.all()
    |> Repo.preload(:accommodation)
  end

  def get_accommodation_image!(id), do: Repo.get!(AccommodationImage, id)

  def create_accommodation_image(attrs \\ %{}) do
    %AccommodationImage{}
    |> AccommodationImage.changeset(attrs)
    |> Repo.insert()
  end

  def update_accommodation_image(image, attrs) do
    image |> AccommodationImage.changeset(attrs) |> Repo.update()
  end

  def delete_accommodation_image(image), do: Repo.delete(image)

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
