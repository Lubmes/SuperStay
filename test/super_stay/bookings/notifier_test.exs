defmodule SuperStay.Bookings.NotifierTest do
  use SuperStay.DataCase, async: true

  import Swoosh.TestAssertions

  alias SuperStay.{Bookings, Catalog}
  alias SuperStay.Bookings.Notifier

  setup do
    {:ok, location} =
      Catalog.create_location(%{
        name: %{"nl" => "Testlocatie"},
        type: "hotel",
        latitude: 52.0,
        longitude: 4.0
      })

    {:ok, accommodation} =
      Catalog.create_accommodation(%{
        title: %{"nl" => "Testkamer"},
        description: %{"nl" => "Omschrijving"},
        type: "room",
        max_guests: 2,
        price_per_night: 100,
        location_id: location.id
      })

    %{accommodation: accommodation}
  end

  test "sends a booking confirmation with stay and guest details", %{accommodation: accommodation} do
    booking = create_booking(accommodation, Date.add(Date.utc_today(), 12), "confirmed")

    assert {:ok, _email} =
             booking.id |> Bookings.get_booking!() |> Notifier.deliver_confirmation()

    assert_email_sent(fn email ->
      assert email.to == [{"Testgast", "guest@example.com"}]
      assert email.subject == "Je boeking is bevestigd"
      assert email.text_body =~ ~r/Testgast.*Testkamer/s
    end)
  end

  test "sends reminders once for active bookings arriving within three days", %{
    accommodation: accommodation
  } do
    today = Date.utc_today()
    due_booking = create_booking(accommodation, Date.add(today, 3), "confirmed")
    _future_booking = create_booking(accommodation, Date.add(today, 6), "pending")

    {:ok, cancelled_accommodation} =
      Catalog.create_accommodation(%{
        title: %{"nl" => "Andere kamer"},
        type: "room",
        max_guests: 2,
        price_per_night: 100,
        location_id: accommodation.location_id
      })

    _cancelled_booking = create_booking(cancelled_accommodation, Date.add(today, 3), "cancelled")

    {:ok, early_accommodation} =
      Catalog.create_accommodation(%{
        title: %{"nl" => "Vroege kamer"},
        type: "room",
        max_guests: 2,
        price_per_night: 100,
        location_id: accommodation.location_id
      })

    _early_booking = create_booking(early_accommodation, Date.add(today, 2), "confirmed")

    assert [due] = Bookings.list_due_reminders(today)
    assert due.id == due_booking.id

    assert Bookings.send_due_reminders(today) == 1

    assert_email_sent(fn email ->
      assert email.to == [{"Testgast", "guest@example.com"}]
      assert email.subject == "Je verblijf begint over drie dagen"
    end)

    assert Bookings.get_booking!(due_booking.id).reminder_sent_at

    assert Bookings.send_due_reminders(today) == 0
    refute_email_sent()
  end

  defp create_booking(accommodation, start_date, status) do
    {:ok, booking} =
      Bookings.create_booking(%{
        start_date: start_date,
        end_date: Date.add(start_date, 2),
        total_price: 200,
        guest_name: "Testgast",
        guest_email: "guest@example.com",
        accommodation_id: accommodation.id,
        status: status
      })

    booking
  end
end
