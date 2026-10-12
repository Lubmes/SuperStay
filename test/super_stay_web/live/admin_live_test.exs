defmodule SuperStayWeb.AdminLiveTest do
  use SuperStayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SuperStay.AccountsFixtures

  alias SuperStay.{Accounts, Bookings, Catalog}

  setup %{conn: conn} do
    {:ok, location} =
      Catalog.create_location(%{
        name: %{"nl" => "Testlocatie"},
        type: "hotel",
        latitude: 52.0,
        longitude: 4.0
      })

    {:ok, other_location} =
      Catalog.create_location(%{
        name: %{"nl" => "Tweede locatie"},
        type: "hotel",
        latitude: 53.0,
        longitude: 5.0
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

    {:ok, addon} =
      Catalog.create_addon(%{
        name: %{"nl" => "Ontbijt"},
        price: 12,
        stock: 10,
        location_id: location.id
      })

    {:ok, image} =
      Catalog.create_accommodation_image(%{
        url: "https://example.test/room.jpg",
        caption: %{"nl" => "Kamer"},
        position: 1,
        accommodation_id: accommodation.id
      })

    {:ok, booking} =
      Bookings.create_booking(%{
        start_date: ~D[2026-11-03],
        end_date: ~D[2026-11-06],
        total_price: 300,
        guest_name: "Mira de Vries",
        guest_email: "mira@example.com",
        accommodation_id: accommodation.id,
        status: "confirmed"
      })

    user = user_fixture()

    %{
      conn: log_in_user(conn, user),
      accommodation: accommodation,
      addon: addon,
      image: image,
      other_location: other_location,
      booking: booking
    }
  end

  test "searches bookings by guest name and shows booking details", %{
    conn: conn,
    booking: booking
  } do
    {:ok, view, _html} = live(conn, "/admin/bookings")

    assert has_element?(view, "#booking-search")
    assert has_element?(view, "a[href='/admin/bookings/#{booking.id}']")

    view
    |> element("#booking-search")
    |> render_change(%{"search" => %{"query" => "MIRA"}})

    assert has_element?(view, "a[href='/admin/bookings/#{booking.id}']")

    {:ok, details, _html} = live(conn, "/admin/bookings/#{booking.id}")
    assert has_element?(details, "#cancel-booking")
    assert has_element?(details, "main", "mira@example.com")
  end

  test "cancels a booking from its detail page", %{conn: conn, booking: booking} do
    {:ok, view, _html} = live(conn, "/admin/bookings/#{booking.id}")

    view
    |> element("#cancel-booking")
    |> render_click()

    assert Bookings.get_booking!(booking.id).status == "cancelled"
  end

  test "support staff cannot access catalog management", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/admin/bookings"}}} = live(conn, "/admin/catalog")
  end

  test "catalog admins can browse location-grouped tabs and edit catalog items", %{
    accommodation: accommodation,
    addon: addon,
    image: image,
    other_location: other_location
  } do
    {:ok, admin} =
      Accounts.create_admin_user(%{
        email: unique_user_email(),
        password: "secure admin password",
        role: "catalog_admin"
      })

    conn = build_conn() |> log_in_user(admin)
    {:ok, catalog, _html} = live(conn, "/admin/catalog")

    assert has_element?(catalog, "#location-#{accommodation.location_id}-tab-accommodations")
    assert has_element?(catalog, "#location-#{accommodation.location_id}-tab-addons")
    assert has_element?(catalog, "#location-#{accommodation.location_id}-panel-accommodations")
    assert has_element?(catalog, "#catalog-location-#{other_location.id}")
    assert has_element?(catalog, "#location-#{other_location.id}-panel-accommodations")

    assert has_element?(
             catalog,
             "#location-#{accommodation.location_id}-panel-accommodations #add-accommodation-for-#{accommodation.location_id}"
           )

    assert has_element?(catalog, "#catalog-accommodation-#{accommodation.id}")
    assert has_element?(catalog, "#catalog-image-#{image.id}")

    catalog
    |> element("#location-#{accommodation.location_id}-tab-addons")
    |> render_click()

    assert has_element?(catalog, "#location-#{accommodation.location_id}-panel-addons")
    assert has_element?(catalog, "#catalog-addon-#{addon.id}")
    assert has_element?(catalog, "#location-#{other_location.id}-panel-accommodations")
    refute has_element?(catalog, "#location-#{other_location.id}-panel-addons")

    catalog
    |> element("#location-#{accommodation.location_id}-tab-accommodations")
    |> render_click()

    {:ok, form, _html} = live(conn, "/admin/catalog/accommodations/#{accommodation.id}")
    assert has_element?(form, "#catalog-item-form")
    assert has_element?(form, "input[name='item[title_nl]']")

    {:ok, new_form, _html} =
      live(conn, "/admin/catalog/accommodations/new?location_id=#{accommodation.location_id}")

    assert has_element?(
             new_form,
             "select[name='item[location_id]'] option[value='#{accommodation.location_id}'][selected]"
           )

    {:ok, addon_form, _html} =
      live(conn, "/admin/catalog/addons/new?location_id=#{accommodation.location_id}")

    assert has_element?(
             addon_form,
             "select[name='item[location_id]'] option[value='#{accommodation.location_id}'][selected]"
           )
  end
end
