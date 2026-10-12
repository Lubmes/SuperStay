defmodule SuperStay.Repo.Migrations.ScopeBookingOverlapConstraintToConfirmed do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE bookings DROP CONSTRAINT prevent_double_bookings"

    execute """
    ALTER TABLE bookings
    ADD CONSTRAINT prevent_double_bookings
    EXCLUDE USING gist (
      accommodation_id WITH =,
      daterange(start_date, end_date, '[]') WITH &&
    ) WHERE (status = 'confirmed')
    """
  end

  def down do
    execute "ALTER TABLE bookings DROP CONSTRAINT prevent_double_bookings"

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
