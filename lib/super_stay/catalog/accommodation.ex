defmodule SuperStay.Catalog.Accommodation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accommodations" do
    field :title, :map
    field :description, :map
    field :type, :string
    field :max_guests, :integer
    field :price_per_night, :decimal

    # Relaties
    belongs_to :location, SuperStay.Catalog.Location
    has_many :images, SuperStay.Catalog.AccommodationImage

    timestamps()
  end

  def changeset(accommodation, attrs) do
    accommodation
    |> cast(attrs, [:title, :description, :type, :max_guests, :price_per_night, :location_id])
    |> validate_required([:title, :type, :max_guests, :price_per_night, :location_id])
    |> validate_inclusion(:type, ["house", "room", "apartment"])
    |> validate_required_locale(:title, "nl")
  end

  defp validate_required_locale(changeset, field, locale) do
    validate_change(changeset, field, fn _field, map ->
      case Map.get(map, to_string(locale)) do
        nil ->
          [{field, "moet tenminste een Nederlandse ('#{locale}') vertaling bevatten"}]

        value ->
          if String.trim(value) == "" do
            [{field, "Nederlandse vertaling mag niet leeg zijn"}]
          else
            []
          end
      end
    end)
  end
end
