import { useCallback, useEffect, useRef, useState } from "react"
import { Alert, Card, Empty, Form, Select, Spin, Typography } from "antd"
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

function extractPostalCode(place) {
  const component = (place.address_components || []).find((entry) =>
    (entry.types || []).includes("postal_code")
  )

  return component?.short_text || component?.long_text
}

export default function HomePage() {
  const [options, setOptions] = useState([])
  const [loading, setLoading] = useState(false)
  const [placeDetails, setPlaceDetails] = useState(null)
  const [currentConditions, setCurrentConditions] = useState(null)
  const [forecastDays, setForecastDays] = useState(null)
  const [detailsLoading, setDetailsLoading] = useState(false)
  const [weatherLoading, setWeatherLoading] = useState(false)
  const [fromCache, setFromCache] = useState(false)
  const [error, setError] = useState(null)

  const sessionTokenRef = useRef(null)
  const debounceRef = useRef(null)

  useEffect(() => {
    sessionTokenRef.current = generateSessionToken()

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current)
    }
  }, [])

  const renewSessionToken = () => {
    sessionTokenRef.current = generateSessionToken()
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

  const fetchWeather = useCallback(async (latitude, longitude, zipCode) => {
    const params = new URLSearchParams({ latitude, longitude })
    if (zipCode) params.set("zip_code", zipCode)

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
      forecastDays: forecastData,
      fromCache: Boolean(currentData.cached || forecastData.cached)
    }
  }, [])

  const handleSearch = (value) => {
    if (debounceRef.current) clearTimeout(debounceRef.current)

    if (!value?.trim()) {
      setOptions([])
      setError(null)
      return
    }

    debounceRef.current = setTimeout(async () => {
      setLoading(true)
      setError(null)

      try {
        const data = await fetchLocations(value, sessionTokenRef.current)
        setOptions(data.options)
      } catch (err) {
        setOptions([])
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }, DEBOUNCE_MS)
  }

  const handleSelect = async (placeId) => {
    const sessionToken = sessionTokenRef.current

    setDetailsLoading(true)
    setWeatherLoading(true)
    setError(null)
    setCurrentConditions(null)
    setForecastDays(null)
    setFromCache(false)

    try {
      const params = new URLSearchParams()
      params.set("q[session_token]", sessionToken)

      let response
      try {
        response = await fetch(`/api/v1/locations/${encodeURIComponent(placeId)}?${params}`)
      } finally {
        // The place details request ends the autocomplete session, so start a new one afterwards
        renewSessionToken()
      }

      const data = await response.json()

      if (!response.ok) throw new Error(data.error || "Failed to fetch place details")

      setPlaceDetails(data)

      const { latitude, longitude } = data.location || {}
      const zipCode = extractPostalCode(data)

      if (latitude != null && longitude != null) {
        try {
          const weather = await fetchWeather(latitude, longitude, zipCode)
          setCurrentConditions(weather.currentConditions)
          setForecastDays(weather.forecastDays)
          setFromCache(weather.fromCache)
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
    }
  }

  const handleClear = () => {
    setOptions([])
    setPlaceDetails(null)
    setCurrentConditions(null)
    setForecastDays(null)
    setFromCache(false)
    setError(null)
    renewSessionToken()
  }

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
            Search by zipcode/address
          </Typography.Text>
        }
      >
        <Form layout="vertical">
          <Form.Item label={false} name="address" style={{ marginBottom: error ? 16 : 0 }}>
            <Select
              showSearch
              allowClear
              size="large"
              placeholder="Start typing an address or zip code..."
              filterOption={false}
              notFoundContent={loading ? <Spin size="small" /> : null}
              options={options}
              onSearch={handleSearch}
              onSelect={handleSelect}
              onClear={handleClear}
              loading={loading}
            />
          </Form.Item>
        </Form>

        {error && (
          <Alert type="error" message={error} showIcon style={{ marginTop: 16 }} />
        )}
      </Card>

      {(detailsLoading || weatherLoading) && (
        <div className="loading-panel">
          <Spin size="large" tip={weatherLoading ? "Loading weather data..." : "Loading location..."} />
        </div>
      )}

      {!detailsLoading && !weatherLoading && !hasResults && (
        <Card className="surface-card" style={{ marginTop: 24 }}>
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description="Search for a location to see details, current conditions, and forecast."
          />
        </Card>
      )}

      {!detailsLoading && !weatherLoading && hasResults && (
        <div className="results-section">
          {fromCache && (
            <Alert type="info" message="Loaded from cache" showIcon style={{ marginBottom: 16 }} />
          )}
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
