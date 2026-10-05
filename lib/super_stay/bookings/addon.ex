defmodule SuperStay.Bookings.Addon do
  use Ecto.Schema
  import Ecto.Changeset

  schema "addons" do
    field :name, :map
    field :price, :decimal
    field :stock, :integer

    # Nieuwe relatie toegevoegd:
    belongs_to :location, SuperStay.Catalog.Location

    timestamps()
  end

  def changeset(addon, attrs) do
    addon
    |> cast(attrs, [:name, :price, :location_id, :stock])
    |> validate_required([:name, :price, :location_id])
    |> validate_required_locale(:name, "nl")
  end

  defp validate_required_locale(changeset, field, locale) do
    validate_change(changeset, field, fn _field, map ->
      case Map.get(map, to_string(locale)) do
        nil -> [{field, "moet tenminste een Nederlandse ('#{locale}') vertaling bevatten"}]
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
