defmodule SuperStayWeb.DateRangePicker do
  use Phoenix.Component

  @doc """
  Herbruikbare datepicker voor een start-/einddatum-bereik.

  De geschatte datums worden in hidden inputs geplaatst, zodat de bestaande
  LiveView-formulieren zonder extra server-side mapping werken.
  """
  attr :id, :string, required: true
  attr :start_name, :string, required: true
  attr :end_name, :string, required: true
  attr :start_value, :string, default: nil
  attr :end_value, :string, default: nil
  attr :blocked_dates, :list, default: []
  attr :errors, :list, default: []
  attr :label, :string, default: "Kies je reisperiode"
  attr :class, :string, default: ""

  def date_range_picker(assigns) do
    assigns =
      assign(assigns, :blocked_dates_json, Jason.encode!(assigns.blocked_dates))

    ~H"""
    <div
      id={@id}
      class={["date-range-picker", @class]}
      phx-hook="DateRangePicker"
      phx-update="ignore"
      data-start-name={@start_name}
      data-end-name={@end_name}
      data-start-value={@start_value}
      data-end-value={@end_value}
      data-blocked-dates={@blocked_dates_json}
    >
      <input type="hidden" name={@start_name} value={@start_value} />
      <input type="hidden" name={@end_name} value={@end_value} />

      <div class="rounded-2xl border border-base-300 bg-base-100 shadow-sm">
        <div class="flex items-center justify-between border-b border-base-300 px-4 py-3">
          <div>
            <p class="text-sm font-bold text-base-content">{@label}</p>
            <p class="text-xs text-base-content/60">
              Klik op twee datums om een verblijf te selecteren
            </p>
          </div>
          <div class="flex items-center gap-1">
            <button
              type="button"
              class="btn btn-square btn-ghost btn-sm"
              data-picker-action="prev-month"
              aria-label="Vorige maand"
            >
              <span aria-hidden="true">←</span>
            </button>
            <button
              type="button"
              class="btn btn-square btn-ghost btn-sm"
              data-picker-action="next-month"
              aria-label="Volgende maand"
            >
              <span aria-hidden="true">→</span>
            </button>
          </div>
        </div>

        <div class="p-3">
          <div class="mb-2 text-center text-sm font-bold text-base-content" data-picker-month></div>
          <div class="grid grid-cols-7 text-center text-[11px] font-semibold uppercase tracking-wide text-base-content/50">
            <span>Ma</span>
            <span>Di</span>
            <span>Wo</span>
            <span>Do</span>
            <span>Vr</span>
            <span>Za</span>
            <span>Zo</span>
          </div>
          <div class="mt-2 grid grid-cols-7 gap-1" data-picker-days></div>
        </div>

        <div class="flex flex-wrap items-center gap-3 border-t border-base-300 px-4 py-3 text-xs">
          <span class="flex items-center gap-2"><span class="size-3 rounded-sm border border-base-300 bg-base-100"></span>Geselecteerd</span>
          <span class="flex items-center gap-2"><span class="size-3 rounded-sm bg-primary"></span>Bereik</span>
          <span class="flex items-center gap-2"><span class="size-3 rounded-sm bg-base-300"></span>Geblokkeerd</span>
        </div>

        <%= if @errors != [] do %>
          <div class="border-t border-error/30 bg-error/5 px-4 py-3 text-sm text-error">
            {Enum.map_join(@errors, ", ", &to_string/1)}
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
