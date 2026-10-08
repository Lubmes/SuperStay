defmodule SuperStayWeb.DateRangePickerTest do
  use SuperStayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders a shared start/end date picker with blocked dates" do
    html =
      render_component(&SuperStayWeb.DateRangePicker.date_range_picker/1,
        id: "booking-dates",
        start_name: "booking[start_date]",
        end_name: "booking[end_date]",
        start_value: "2026-10-03",
        end_value: "2026-10-10",
        blocked_dates: ["2026-10-05", "2026-10-06"]
      )

    assert html =~ "id=\"booking-dates\""
    assert html =~ "name=\"booking[start_date]\""
    assert html =~ "name=\"booking[end_date]\""
    assert html =~ "data-blocked-dates="
    assert html =~ "2026-10-05"
    assert html =~ "2026-10-06"
    assert html =~ "Kies je reisperiode"
  end

  test "renders validation errors for the selected date range" do
    html =
      render_component(&SuperStayWeb.DateRangePicker.date_range_picker/1,
        id: "booking-dates",
        start_name: "booking[start_date]",
        end_name: "booking[end_date]",
        errors: ["is al geboekt voor deze accommodatie"]
      )

    assert html =~ "is al geboekt voor deze accommodatie"
  end
end
