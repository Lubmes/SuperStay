defmodule SuperStay.Bookings.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookings" do
    field :start_date, :date
    field :end_date, :date
    field :total_price, :decimal
    field :status, :string, default: "pending"
    field :guest_name, :string
    field :guest_email, :string

    belongs_to :accommodation, SuperStay.Catalog.Accommodation
    has_many :booking_addons, SuperStay.Bookings.BookingAddon

    timestamps()
  end

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [
      :start_date,
      :end_date,
      :total_price,
      :status,
      :guest_name,
      :guest_email,
      :accommodation_id
    ])
    |> validate_required([
      :start_date,
      :end_date,
      :total_price,
      :status,
      :guest_name,
      :guest_email,
      :accommodation_id
    ])
    |> validate_inclusion(:status, ["pending", "confirmed", "cancelled"])
    |> validate_dates()
  end

  # Custom validatie om te zorgen dat de einddatum na de startdatum ligt
  defp validate_dates(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && Date.compare(end_date, start_date) != :gt do
      add_error(changeset, :end_date, "moet na de startdatum liggen")
    else
      changeset
    end
  end
end
