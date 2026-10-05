defmodule SuperStay.Repo.Migrations.CreateBookings do
  use Ecto.Migration

  def change do
    # Activeer de btree_gist extensie in PostgreSQL (nodig voor de overlap-beveiliging)
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"

    create table(:bookings) do
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :total_price, :decimal, precision: 10, scale: 2, null: false
      add :status, :string, null: false, default: "pending" # pending, confirmed, cancelled

      # Gastgegevens (eenvoudige opzet zonder verplichte user-tabel)
      add :guest_name, :string, null: false
      add :guest_email, :string, null: false

      # Relatie naar de specifieke accommodatie
      add :accommodation_id, references(:accommodations, on_delete: :restrict), null: false

      timestamps()
    end

    create index(:bookings, [:accommodation_id])

    # Database-level beveiliging: Voorkom dat dezelfde accommodation_id overlappende datums heeft
    execute """
    ALTER TABLE bookings
    ADD CONSTRAINT prevent_double_bookings
    EXCLUDE USING gist (
      accommodation_id WITH =,
      daterange(start_date, end_date, '[]') WITH &&
    )
    """
  end
end
