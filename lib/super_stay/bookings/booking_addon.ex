defmodule SuperStay.Bookings.BookingAddon do
  use Ecto.Schema
  import Ecto.Changeset

  schema "booking_addons" do
    field :date, :date
    field :quantity, :integer

    belongs_to :booking, SuperStay.Bookings.Booking
    belongs_to :addon, SuperStay.Catalog.Addon

    timestamps()
  end

  def changeset(booking_addon, attrs) do
    booking_addon
    |> cast(attrs, [:date, :quantity, :booking_id, :addon_id])
    |> validate_required([:date, :quantity, :booking_id, :addon_id])
    |> validate_number(:quantity, greater_than: 0)
    # De unieke index-fout uit de database netjes opvangen in de changeset:
    |> unique_constraint([:booking_id, :addon_id, :date],
      message: "is al toegevoegd voor deze dag"
    )
  end
end
