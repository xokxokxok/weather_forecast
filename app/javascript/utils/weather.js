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

export function weatherIconUri(condition) {
  const uri = condition?.icon_base_uri
  if (!uri) return null

  return `${uri}.svg`
}
