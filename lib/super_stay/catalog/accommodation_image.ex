defmodule SuperStay.Catalog.AccommodationImage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accommodation_images" do
    field :url, :string
    field :position, :integer
    # Nieuw toegevoegd veld
    field :caption, :map

    belongs_to :accommodation, SuperStay.Catalog.Accommodation

    timestamps()
  end

  def changeset(image, attrs) do
    image
    # :caption toegevoegd aan cast (optioneel, dus niet bij validate_required)
    |> cast(attrs, [:url, :position, :caption, :accommodation_id])
    |> validate_required([:url, :accommodation_id])
  end
end
