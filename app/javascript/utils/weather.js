export function formatTemperature(temperature) {
  if (!temperature) return null

  const unit = temperature.unit === "CELSIUS" ? "°C" : "°F"
  return `${Math.round(temperature.degrees)}${unit}`
}

export function formatDate(displayDate, options = { weekday: "short", month: "short", day: "numeric" }) {
  if (!displayDate) return "-"

  const { year, month, day } = displayDate
  return new Date(year, month - 1, day).toLocaleDateString(undefined, options)
}

export function weatherIconUri(iconBaseUri) {
  if (!iconBaseUri) return null

  return `${iconBaseUri}.svg`
}
