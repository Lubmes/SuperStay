defmodule SuperStay.Repo.Migrations.CreateAddons do
  use Ecto.Migration

  def change do
    # 1. De catalogus van extra's (bijv. Fietsverhuur, Ontbijtservice)
    create table(:addons) do
      # Meertalige naam
      add :name, :map, null: false
      add :price, :decimal, precision: 10, scale: 2, null: false

      # DEZE REGEL MOET HIER BINNEN STAAN:
      add :location_id, references(:locations, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:addons, [:location_id])

    # 2. De koppeltabel voor flexibele boekingen per dag
    create table(:booking_addons) do
      add :booking_id, references(:bookings, on_delete: :delete_all), null: false
      add :addon_id, references(:addons, on_delete: :restrict), null: false
      add :date, :date, null: false
      add :quantity, :integer, null: false, default: 1

      timestamps()
    end

    create index(:booking_addons, [:booking_id])
    create index(:booking_addons, [:addon_id])

    # Voorkomt dat er voor dezelfde boeking twee keer dezelfde addon op dezelfde dag ontstaat
    create unique_index(:booking_addons, [:booking_id, :addon_id, :date])
  end
end
