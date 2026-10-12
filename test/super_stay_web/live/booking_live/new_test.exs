defmodule SuperStayWeb.BookingLive.NewTest do
  use SuperStayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SuperStay.Bookings

  setup do
    {:ok, location} =
      SuperStay.Catalog.create_location(%{
        name: %{"nl" => "Test Park"},
        type: "holiday_park",
        latitude: 51.0,
        longitude: 3.0
      })

    {:ok, accommodation} =
      SuperStay.Catalog.create_accommodation(%{
        title: %{"nl" => "Luxe Huisje"},
        type: "house",
        max_guests: 4,
        price_per_night: 100.00,
        location_id: location.id
      })

    {:ok, _booking} =
      SuperStay.Bookings.create_booking(%{
        start_date: ~D[2026-10-03],
        end_date: ~D[2026-10-10],
        total_price: 700.00,
        guest_name: "Jan Modaal",
        guest_email: "jan@modaal.nl",
        accommodation_id: accommodation.id,
        status: "confirmed"
      })

    %{accommodation: accommodation}
  end

  test "rendert het boekingsformulier met een datumpicker", %{
    conn: conn,
    accommodation: accommodation
  } do
    {:ok, view, _html} =
      live(conn, "/accommodations/#{accommodation.id}/book")

    assert has_element?(view, "#booking-form")
    assert has_element?(view, "#booking-date-picker")
    assert has_element?(view, "input[name='booking[start_date]']")
    assert has_element?(view, "input[name='booking[end_date]']")
  end

  test "maakt de boeking aan en verstuurt daarna een bevestiging", %{
    conn: conn,
    accommodation: accommodation
  } do
    {:ok, view, _html} =
      live(
        conn,
        "/accommodations/#{accommodation.id}/book?start_date=2026-11-03&end_date=2026-11-05"
      )

    view
    |> form("#booking-form", %{
      "booking" => %{
        "guest_name" => "Ada Voorbeeld",
        "guest_email" => "ada@example.com"
      }
    })
    |> render_submit()

    view
    |> element("button[phx-click='next_to_review']")
    |> render_click()

    view
    |> element("button[phx-click='save']")
    |> render_click()

    assert [%{status: "confirmed", guest_email: "ada@example.com"}] =
             Bookings.list_bookings("Ada Voorbeeld")
  end
end
