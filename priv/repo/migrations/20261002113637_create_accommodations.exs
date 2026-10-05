defmodule SuperStay.Repo.Migrations.CreateAccommodations do
  use Ecto.Migration

  def change do
    # 1. De parent tabel: Locaties (Nu met meertalige naam!)
    create table(:locations) do
      add :name, :map, null: false            # Gewijzigd van :string naar :map
      add :type, :string, null: false         # "holiday_park", "hotel", "individual_property"
      add :latitude, :float, null: false
      add :longitude, :float, null: false

      timestamps()
    end

    # 2. De kind tabel: Accommodaties
    create table(:accommodations) do
      add :title, :map, null: false
      add :description, :map
      add :type, :string, null: false
      add :max_guests, :integer, null: false
      add :price_per_night, :decimal, precision: 10, scale: 2, null: false

      add :location_id, references(:locations, on_delete: :delete_all), null: false

      timestamps()
    end

    # 3. De foto's met captions
    create table(:accommodation_images) do
      add :url, :string, null: false
      add :position, :integer, default: 0
      add :caption, :map
      add :accommodation_id, references(:accommodations, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:accommodations, [:location_id])
    create index(:accommodation_images, [:accommodation_id])
  end
end
