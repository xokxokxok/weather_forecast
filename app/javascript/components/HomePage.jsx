import { useCallback, useEffect, useRef, useState } from "react"
import { Alert, AutoComplete, Button, Card, Empty, Form, Spin, Typography } from "antd"
import { SearchOutlined } from "@ant-design/icons"
import CurrentConditionsCard from "./CurrentConditionsCard"
import ForecastDaysCard from "./ForecastDaysCard"
import PlaceDetailsCard from "./PlaceDetailsCard"

const DEBOUNCE_MS = 1000

function generateSessionToken() {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID()
  }

  // Fallback for non-secure contexts (crypto.randomUUID requires HTTPS or localhost)
  const bytes = crypto.getRandomValues(new Uint8Array(16))
  bytes[6] = (bytes[6] & 0x0f) | 0x40
  bytes[8] = (bytes[8] & 0x3f) | 0x80
  const hex = Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join("")

  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`
}

// The API returns locations as { place_id, address }. AutoComplete writes the option value into
// the input, so the address becomes the value and the place id travels alongside it.
function toAutoCompleteOptions(locations) {
  return (locations || []).map((location) => ({
    key: location.place_id,
    value: location.address,
    label: location.address,
    placeId: location.place_id
  }))
}

export default function HomePage() {
  const [query, setQuery] = useState("")
  const [options, setOptions] = useState([])
  const [loading, setLoading] = useState(false)
  const [placeDetails, setPlaceDetails] = useState(null)
  const [currentConditions, setCurrentConditions] = useState(null)
  const [forecastDays, setForecastDays] = useState(null)
  const [detailsLoading, setDetailsLoading] = useState(false)
  const [weatherLoading, setWeatherLoading] = useState(false)
  const [error, setError] = useState(null)

  const sessionTokenRef = useRef(null)
  const debounceRef = useRef(null)
  const selectedRef = useRef(null)
  const busyRef = useRef(false)

  useEffect(() => {
    sessionTokenRef.current = generateSessionToken()

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current)
    }
  }, [])

  const renewSessionToken = () => {
    sessionTokenRef.current = generateSessionToken()
  }

  const cancelPendingSearch = () => {
    if (debounceRef.current) {
      clearTimeout(debounceRef.current)
      debounceRef.current = null
    }
  }

  const fetchLocations = useCallback(async (query, sessionToken) => {
    const params = new URLSearchParams()
    params.set("q[input]", query)
    params.set("q[session_token]", sessionToken)

    const response = await fetch(`/api/v1/locations?${params}`)
    const data = await response.json()

    if (!response.ok) throw new Error(data.error || "Failed to fetch locations")

    return data
  }, [])

  // nearby_zip_codes is sent as nearby_zip_codes[]=A&nearby_zip_codes[]=B so Rails parses it as an array.
  // An empty list sends nothing.
  const fetchWeather = useCallback(async (latitude, longitude, zipCode, nearbyZipCodes = []) => {
    const params = new URLSearchParams({ latitude, longitude })
    if (zipCode) params.set("zip_code", zipCode)
    nearbyZipCodes.filter(Boolean).forEach((code) => params.append("nearby_zip_codes[]", code))

    const [currentResponse, forecastResponse] = await Promise.all([
      fetch(`/api/v1/weather_conditions/current?${params}`),
      fetch(`/api/v1/weather_conditions?${params}`)
    ])

    const currentData = await currentResponse.json()
    const forecastData = await forecastResponse.json()

    if (!currentResponse.ok) {
      throw new Error(currentData.error || "Failed to fetch current conditions")
    }

    if (!forecastResponse.ok) {
      throw new Error(forecastData.error || "Failed to fetch forecast")
    }

    return {
      currentConditions: currentData,
      forecastDays: forecastData
    }
  }, [])

  const handleSearch = (value) => {
    cancelPendingSearch()

    if (!value?.trim()) {
      setOptions([])
      setError(null)
      return
    }

    debounceRef.current = setTimeout(async () => {
      debounceRef.current = null
      setLoading(true)
      setError(null)

      try {
        const data = await fetchLocations(value, sessionTokenRef.current)
        if (!busyRef.current) setOptions(toAutoCompleteOptions(data.locations))
      } catch (err) {
        setOptions([])
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }, DEBOUNCE_MS)
  }

  // resolvePlaceId(sessionToken) returns the place id to load. The place details request ends the
  // autocomplete session, so the session token is renewed after every attempt.
  const loadPlace = async (resolvePlaceId) => {
    if (busyRef.current) return
    busyRef.current = true

    cancelPendingSearch()
    setOptions([])
    setLoading(false)

    const sessionToken = sessionTokenRef.current

    setDetailsLoading(true)
    setWeatherLoading(true)
    setError(null)
    setCurrentConditions(null)
    setForecastDays(null)

    try {
      let response
      try {
        const placeId = await resolvePlaceId(sessionToken)

        const params = new URLSearchParams()
        params.set("q[session_token]", sessionToken)

        response = await fetch(`/api/v1/locations/${encodeURIComponent(placeId)}?${params}`)
      } finally {
        renewSessionToken()
      }

      const data = await response.json()

      if (!response.ok) throw new Error(data.error || "Failed to fetch place details")

      setPlaceDetails(data)

      const { latitude, longitude } = data.location || {}
      const zipCode = data.zip_code
      const nearbyZipCodes = Array.isArray(data.nearby_zip_codes) ? data.nearby_zip_codes : []

      if (latitude != null && longitude != null) {
        try {
          const weather = await fetchWeather(latitude, longitude, zipCode, nearbyZipCodes)
          setCurrentConditions(weather.currentConditions)
          setForecastDays(weather.forecastDays)
        } catch (err) {
          setError(err.message)
        }
      }
    } catch (err) {
      setPlaceDetails(null)
      setError(err.message)
    } finally {
      setDetailsLoading(false)
      setWeatherLoading(false)
      busyRef.current = false
    }
  }

  const handleChange = (value) => {
    setQuery(value ?? "")

    if (selectedRef.current && selectedRef.current.label !== value) {
      selectedRef.current = null
    }
  }

  // Selecting a suggestion only fills the input; the search runs when the form is submitted.
  const handleSelect = (value, option) => {
    cancelPendingSearch()
    selectedRef.current = { label: value, placeId: option.placeId }
    setQuery(value)
    setOptions([])
    setError(null)
  }

  // Free text: use the selected suggestion when the text still matches it, otherwise use the
  // first autocomplete suggestion for the typed text.
  const handleSubmit = () => {
    const text = query.trim()

    if (!text) {
      setError("Enter an address or zip code")
      return
    }

    const selected = selectedRef.current

    loadPlace(async (sessionToken) => {
      if (selected && selected.label === text) return selected.placeId

      const data = await fetchLocations(text, sessionToken)
      const first = data.locations?.[0]

      if (!first) throw new Error(`No location found for "${text}"`)

      selectedRef.current = { label: text, placeId: first.place_id }
      return first.place_id
    })
  }

  const handleClear = () => {
    cancelPendingSearch()
    setQuery("")
    setOptions([])
    setPlaceDetails(null)
    setCurrentConditions(null)
    setForecastDays(null)
    setError(null)
    selectedRef.current = null
    renewSessionToken()
  }

  const busy = detailsLoading || weatherLoading
  const hasResults = placeDetails || currentConditions || forecastDays

  return (
    <>
      <div className="page-hero">
        <Typography.Title level={2} className="page-hero-title">
          Find weather anywhere
        </Typography.Title>
        <Typography.Paragraph className="page-hero-subtitle">
          Search an address or zip code to view local conditions and a 10-day forecast.
        </Typography.Paragraph>
      </div>

      <Card
        className="surface-card search-card"
        title={
          <Typography.Text strong style={{ fontSize: 16 }}>
            <SearchOutlined style={{ marginRight: 8, color: "#0b6bcb" }} />
            Search by Address
          </Typography.Text>
        }
      >
        <Form layout="vertical" onFinish={handleSubmit}>
          <Form.Item label={false} style={{ marginBottom: error ? 16 : 0 }}>
            <div className="search-row">
              <AutoComplete
                className="search-input"
                allowClear
                size="large"
                value={query}
                placeholder="Type an address or zip code and press Search..."
                notFoundContent={loading ? <Spin size="small" /> : null}
                options={options}
                onSearch={handleSearch}
                onChange={handleChange}
                onSelect={handleSelect}
                onClear={handleClear}
                disabled={busy}
              />
              <Button
                className="search-button"
                type="primary"
                size="large"
                htmlType="submit"
                icon={<SearchOutlined />}
                loading={busy}
              >
                Search
              </Button>
            </div>
          </Form.Item>
        </Form>

        {error && (
          <Alert type="error" message={error} showIcon style={{ marginTop: 16 }} />
        )}
      </Card>

      {busy && (
        <div className="loading-panel">
          <Spin size="large" tip={weatherLoading ? "Loading weather data..." : "Loading location..."} />
        </div>
      )}

      {!busy && !hasResults && (
        <Card className="surface-card" style={{ marginTop: 24 }}>
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description="Search for a location to see details, current conditions, and forecast."
          />
        </Card>
      )}

      {!busy && hasResults && (
        <div className="results-section">
          <div className="results-grid">
            {placeDetails && <PlaceDetailsCard place={placeDetails} />}
            {currentConditions && <CurrentConditionsCard conditions={currentConditions} />}
            {forecastDays && <ForecastDaysCard forecast={forecastDays} />}
          </div>
        </div>
      )}
    </>
  )
}
