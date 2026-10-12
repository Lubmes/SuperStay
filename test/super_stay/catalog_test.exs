defmodule SuperStay.CatalogTest do
  use SuperStay.DataCase, async: true

  alias SuperStay.{Bookings, Catalog, Repo}
  alias SuperStay.Catalog.{Accommodation, Addon, Location}

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

    {:ok, addon} =
      Catalog.create_addon(%{
        name: %{"nl" => "Ontbijt"},
        price: 15,
        stock: 8,
        location_id: location.id
      })

    %{location: location, accommodation: accommodation, addon: addon}
  end

  test "creates, updates and deletes all catalog types", %{
    location: location,
    accommodation: accommodation,
    addon: addon
  } do
    assert {:ok, updated_location} =
             Catalog.update_location(location, %{
               name: %{"nl" => "Gewijzigde locatie"},
               type: "hotel",
               latitude: 52.1,
               longitude: 4.1
             })

    assert updated_location.name["nl"] == "Gewijzigde locatie"

    assert {:ok, updated_accommodation} =
             Catalog.update_accommodation(accommodation, %{
               title: %{"nl" => "Nieuwe kamer"},
               description: %{"nl" => "Nieuwe omschrijving"},
               type: "room",
               max_guests: 3,
               price_per_night: 120,
               location_id: location.id
             })

    assert updated_accommodation.max_guests == 3

    assert {:ok, updated_addon} =
             Catalog.update_addon(addon, %{
               name: %{"nl" => "Uitgebreid ontbijt"},
               price: 20,
               stock: 9,
               location_id: location.id
             })

    assert updated_addon.stock == 9

    assert {:ok, image} =
             Catalog.create_accommodation_image(%{
               url: "https://example.test/room.jpg",
               position: 1,
               caption: %{"nl" => "Kamer"},
               accommodation_id: accommodation.id
             })

    assert {:ok, image} =
             Catalog.update_accommodation_image(image, %{
               url: "https://example.test/room-updated.jpg",
               position: 2,
               accommodation_id: accommodation.id
             })

    assert image.position == 2
    assert {:ok, _image} = Catalog.delete_accommodation_image(image)
    assert {:ok, _accommodation} = Catalog.delete_accommodation(updated_accommodation)
    assert {:ok, _addon} = Catalog.delete_addon(updated_addon)
    assert {:ok, _location} = Catalog.delete_location(updated_location)
  end

  test "prevents deleting items referenced by booking history", %{
    location: location,
    accommodation: accommodation,
    addon: addon
  } do
    {:ok, booking} =
      Bookings.create_booking(%{
        start_date: ~D[2026-11-03],
        end_date: ~D[2026-11-06],
        total_price: 300,
        guest_name: "Testgast",
        guest_email: "test@example.com",
        accommodation_id: accommodation.id,
        status: "confirmed"
      })

    {:ok, _line} = Bookings.add_addon_to_booking(booking.id, addon.id, ~D[2026-11-03], 1)

    assert {:error, :in_use} = Catalog.delete_accommodation(accommodation)
    assert {:error, :in_use} = Catalog.delete_addon(addon)
    assert {:error, :in_use} = Catalog.delete_location(location)

    assert %Accommodation{} = Repo.get!(Accommodation, accommodation.id)
    assert %Addon{} = Repo.get!(Addon, addon.id)
    assert %Location{} = Repo.get!(Location, location.id)
  end
end
