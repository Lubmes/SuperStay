defmodule SuperStay.Catalog do
  import Ecto.Query, warn: false
  alias SuperStay.Repo
  alias SuperStay.Catalog.{Location, Accommodation}

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
end
