# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SuperStay.Repo.insert!(%SuperStay.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias SuperStay.Catalog
alias SuperStay.Bookings
alias SuperStay.Repo

# Ruim voor de zekerheid oude seeds op om dubbelingen te voorkomen bij herhaaldelijk draaien
Repo.delete_all(Bookings.BookingAddon)
Repo.delete_all(Bookings.Booking)
Repo.delete_all(Bookings.Addon)
Repo.delete_all(Catalog.AccommodationImage)
Repo.delete_all(Catalog.Accommodation)
Repo.delete_all(Catalog.Location)

# =========================================================================
# 1. ZEEUWS VAKANTIEPARK (4 Huisjes, 12 Fietsen)
# =========================================================================
{:ok, park_zeeland} = Catalog.create_location(%{
  name: %{"nl" => "Vakantiepark De Zeeuwse Parels", "en" => "Zeeland Pearls Resort"},
  type: "holiday_park",
  latitude: 51.501,
  longitude: 3.610
})

# De 12 fietsen (Eindige voorraad: stock is 12)
{:ok, _} = Bookings.create_addon(%{
  name: %{"nl" => "Toerfiets met versnellingen", "en" => "Touring Bike"},
  price: 12.50,
  stock: 12,
  location_id: park_zeeland.id
})

# 4 Huisjes toevoegen
for i <- 1..4 do
  {:ok, _} = Catalog.create_accommodation(%{
    title: %{"nl" => "6-persoons Comfort Bungalow (Nummer #{i})", "en" => "6-person Comfort Bungalow (No. #{i})"},
    description: %{"nl" => "Gezellig familiehuisje vlakbij het strand.", "en" => "Cozy family house near the beach."},
    type: "house",
    max_guests: 6,
    price_per_night: 110.00,
    location_id: park_zeeland.id
  })
end

# =========================================================================
# 2. ZEEUWS HOTEL (3 Kamers, 6 Fietsen, Oneindig Kaartjes)
# =========================================================================
{:ok, hotel_zeeland} = Catalog.create_location(%{
  name: %{"nl" => "Grand Hotel Middelburg", "en" => "Grand Hotel Middelburg"},
  type: "hotel",
  latitude: 51.498,
  longitude: 3.613
})

# 6 Fietsen (Eindige voorraad: stock is 6)
{:ok, _} = Bookings.create_addon(%{
  name: %{"nl" => "Stadsfiets Hotel", "en" => "Hotel City Bike"},
  price: 15.00,
  stock: 6,
  location_id: hotel_zeeland.id
})

# Kaartjes piratenpark (Oneindige voorraad: stock is nil!)
{:ok, _} = Bookings.create_addon(%{
  name: %{"nl" => "Ticket Deltapark Neeltje Jans / Piratenpark", "en" => "Ticket Pirate Theme Park"},
  price: 22.50,
  stock: nil,
  location_id: hotel_zeeland.id
})

# 3 Kamers toevoegen
for i <- ["101", "102", "103"] do
  {:ok, _} = Catalog.create_accommodation(%{
    title: %{"nl" => "Luxe Tweepersoonskamer #{i}", "en" => "Luxury Double Room #{i}"},
    description: %{"nl" => "Inclusief kingsize bed en heerlijk ontbijt.", "en" => "Includes king-size bed and delicious breakfast."},
    type: "room",
    max_guests: 2,
    price_per_night: 85.00,
    location_id: hotel_zeeland.id
  })
end

# =========================================================================
# 3. ANDALUSISCH LOS VAKANTIEHUIS (12 Personen, 12 Mountainbikes)
# =========================================================================
{:ok, villa_andalusia} = Catalog.create_location(%{
  name: %{"nl" => "Losse villa Andalusië (Finca de la Luz)", "en" => "Single Villa Andalusia (Finca de la Luz)"},
  type: "individual_property",
  latitude: 36.721,
  longitude: -4.421
})

# 12 Mountainbikes (Eindige voorraad: stock is 12)
{:ok, _} = Bookings.create_addon(%{
  name: %{"nl" => "Pro Mountainbike", "en" => "Pro Mountain Bike"},
  price: 20.00,
  stock: 12,
  location_id: villa_andalusia.id
})

# 1 Huis (Aangezien het een los vakantiehuis is, heeft de locatie maar 1 child!)
{:ok, _} = Catalog.create_accommodation(%{
  title: %{"nl" => "Exclusieve 12-persoons Finca met privézwembad", "en" => "Exclusive 12-person Finca with Private Pool"},
  description: %{"nl" => "Prachtige rustieke villa in de bergen met panoramisch uitzicht.", "en" => "Stunning rustic villa in the mountains with panoramic views."},
  type: "house",
  max_guests: 12,
  price_per_night: 245.00,
  location_id: villa_andalusia.id
})

IO.puts("🚀 SuperStay database succesvol gevuld met de nieuwe, realistische test-data!")
