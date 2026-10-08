// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/super_stay"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const DateRangePicker = {
  mounted() {
    const root = this.el
    const monthLabel = root.querySelector("[data-picker-month]")
    const daysContainer = root.querySelector("[data-picker-days]")
    const startInput = root.querySelector("input[name='" + root.dataset.startName + "']")
    const endInput = root.querySelector("input[name='" + root.dataset.endName + "']")
    const blockedDates = JSON.parse(root.dataset.blockedDates || "[]")

    let currentMonth = new Date()
    let selectedStart = root.dataset.startValue ? new Date(root.dataset.startValue) : null
    let selectedEnd = root.dataset.endValue ? new Date(root.dataset.endValue) : null

    const formatDate = date => date.toISOString().slice(0, 10)

    const isBlocked = date => blockedDates.includes(formatDate(date))
    const isSameDay = (a, b) => a && b && formatDate(a) === formatDate(b)
    const isInRange = date =>
      selectedStart && selectedEnd && date >= selectedStart && date <= selectedEnd

    const render = () => {
      const monthDate = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1)
      const firstDay = new Date(monthDate)
      firstDay.setDate(1)
      const monthStart = new Date(firstDay)
      monthStart.setDate(1 - ((firstDay.getDay() + 6) % 7))
      monthLabel.textContent = new Intl.DateTimeFormat("nl-NL", {
        month: "long",
        year: "numeric",
      }).format(monthDate)

      daysContainer.replaceChildren()
      for (let index = 0; index < 42; index += 1) {
        const day = new Date(monthStart)
        day.setDate(monthStart.getDate() + index)

        const button = document.createElement("button")
        button.type = "button"
        button.className = [
          "date-picker-day",
          day.getMonth() !== monthDate.getMonth() ? "date-picker-day--muted" : "",
          isSameDay(day, selectedStart) || isSameDay(day, selectedEnd) ? "date-picker-day--selected" : "",
          isInRange(day) ? "date-picker-day--range" : "",
          isBlocked(day) ? "date-picker-day--blocked" : "",
          day < new Date(new Date().setHours(0, 0, 0, 0)) ? "date-picker-day--past" : "",
        ].filter(Boolean).join(" ")
        button.disabled = isBlocked(day) || day < new Date(new Date().setHours(0, 0, 0, 0))
        button.textContent = day.getDate()
        button.dataset.date = formatDate(day)
        button.addEventListener("click", () => this.selectDate(day, button))
        daysContainer.appendChild(button)
      }
    }

    this.selectDate = (date, button) => {
      if (button.disabled) return

      const day = formatDate(date)
      if (!selectedStart || (selectedStart && selectedEnd)) {
        selectedStart = date
        selectedEnd = null
        startInput.value = day
        endInput.value = ""
      } else if (date < selectedStart) {
        selectedEnd = selectedStart
        selectedStart = date
        startInput.value = day
        endInput.value = formatDate(selectedEnd)
      } else {
        selectedEnd = date
        endInput.value = day
      }

      startInput.dispatchEvent(new Event("input", {bubbles: true}))
      endInput.dispatchEvent(new Event("input", {bubbles: true}))
      render()
    }

    root.querySelector("[data-picker-action='prev-month']").addEventListener("click", () => {
      currentMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1, 1)
      render()
    })
    root.querySelector("[data-picker-action='next-month']").addEventListener("click", () => {
      currentMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1)
      render()
    })

    render()
  },
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, DateRangePicker},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

