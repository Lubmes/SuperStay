defmodule SuperStay.BookingsTest do
  use SuperStay.DataCase, async: true
  alias SuperStay.{Catalog, Bookings}

  setup do
    # Helpers om snel testdata aan te maken binnen de test-sandbox
    {:ok, location} =
      Catalog.create_location(%{
        name: %{"nl" => "Test Park"},
        type: "holiday_park",
        latitude: 51.0,
        longitude: 3.0
      })

    {:ok, accommodation} =
      Catalog.create_accommodation(%{
        title: %{"nl" => "Luxe Huisje"},
        type: "house",
        max_guests: 4,
        price_per_night: 100.00,
        location_id: location.id
      })

    {:ok, addon} =
      Catalog.create_addon(%{
        name: %{"nl" => "Fiets"},
        price: 10.00,
        location_id: location.id
      })

    %{accommodation: accommodation, addon: addon}
  end

  test "boekt een week en huurt een fiets van maandag t/m vrijdag", %{
    accommodation: acc,
    addon: addon
  } do
    # 1. Definieer de week (Zaterdag 3 oktober t/m Zaterdag 10 oktober 2026)
    start_date = ~D[2026-10-03]
    end_date = ~D[2026-10-10]

    booking_attrs = %{
      start_date: start_date,
      end_date: end_date,
      total_price: 700.00,
      guest_name: "Jan Modaal",
      guest_email: "jan@modaal.nl",
      accommodation_id: acc.id
    }

    assert {:ok, booking} = Bookings.create_booking(booking_attrs)

    # 2. Huur een fiets voor doordeweeks (maandag 5 okt t/m vrijdag 9 okt)
    work_days = [
      # Maandag
      ~D[2026-10-05],
      # Dinsdag
      ~D[2026-10-06],
      # Woensdag
      ~D[2026-10-07],
      # Donderdag
      ~D[2026-10-08],
      # Vrijdag
      ~D[2026-10-09]
    ]

    for date <- work_days do
      assert {:ok, _booking_addon} = Bookings.add_addon_to_booking(booking.id, addon.id, date, 1)
    end

    # 3. Haal de boeking opnieuw op en controleer de data
    saved_booking = Bookings.get_booking!(booking.id)

    assert length(saved_booking.booking_addons) == 5

    # Controleer of de zaterdag (aankomstdag) géén fiets heeft
    dates_with_bike = Enum.map(saved_booking.booking_addons, & &1.date)
    refute ~D[2026-10-03] in dates_with_bike
    assert ~D[2026-10-05] in dates_with_bike
  end
end
