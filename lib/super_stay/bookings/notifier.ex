defmodule SuperStay.Bookings.Notifier do
  import Swoosh.Email

  alias SuperStay.Mailer

  def deliver_confirmation(booking) do
    deliver(booking, "Je boeking is bevestigd", "Bedankt voor je boeking bij SuperStay.")
  end

  def deliver_reminder(booking) do
    deliver(
      booking,
      "Je verblijf begint over drie dagen",
      "We verwelkomen je binnenkort bij SuperStay."
    )
  end

  defp deliver(booking, subject, introduction) do
    accommodation = translated(booking.accommodation.title)
    addons = Enum.map_join(booking.booking_addons, "\n", &addon_line/1)

    text =
      [
        "Hallo #{booking.guest_name},",
        "",
        introduction,
        "",
        "Accommodatie: #{accommodation}",
        "Aankomst: #{Date.to_iso8601(booking.start_date)}",
        "Vertrek: #{Date.to_iso8601(booking.end_date)}",
        "Totaal: EUR #{Decimal.to_string(booking.total_price, :normal)}",
        if(addons == "", do: nil, else: "Extra's:\n#{addons}"),
        "",
        "SuperStay"
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")

    email =
      new()
      |> from(Application.fetch_env!(:super_stay, :booking_email_from))
      |> to({booking.guest_name, booking.guest_email})
      |> subject(subject)
      |> text_body(text)

    try do
      Mailer.deliver(email)
    rescue
      error -> {:error, error}
    end
  end

  defp addon_line(line) do
    "- #{translated(line.addon.name)} op #{Date.to_iso8601(line.date)} (#{line.quantity})"
  end

  defp translated(map), do: Map.get(map, "nl") || Map.get(map, "en") || ""
end
