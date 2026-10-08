defmodule SuperStay.Catalog.Location do
  use Ecto.Schema
  import Ecto.Changeset

  schema "locations" do
    # Gewijzigd naar :map
    field :name, :map
    field :type, :string
    field :latitude, :float
    field :longitude, :float

    has_many :accommodations, SuperStay.Catalog.Accommodation
    has_many :addons, SuperStay.Catalog.Addon

    timestamps()
  end

  def changeset(location, attrs) do
    location
    |> cast(attrs, [:name, :type, :latitude, :longitude])
    |> validate_required([:name, :type, :latitude, :longitude])
    |> validate_inclusion(:type, ["holiday_park", "hotel", "individual_property"])
    # Zorgt dat NL altijd is ingevuld
    |> validate_required_locale(:name, "nl")
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
