defmodule SuperStay.Repo.Migrations.AddReminderSentAtToBookings do
  use Ecto.Migration

  def change do
    alter table(:bookings) do
      add :reminder_sent_at, :utc_datetime
    end
  end
end
