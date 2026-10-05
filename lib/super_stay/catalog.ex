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
end
