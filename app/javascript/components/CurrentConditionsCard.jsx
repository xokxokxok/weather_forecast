import { Card, Col, Row, Typography } from "antd"
import {
  CloudOutlined,
  EyeOutlined,
  FireOutlined,
  ThunderboltOutlined,
  DashboardOutlined
} from "@ant-design/icons"
import { formatTemperature, weatherIconUri } from "../utils/weather"

function StatTile({ icon, label, value }) {
  return (
    <div className="stat-tile">
      <span className="stat-label">{icon} {label}</span>
      <span className="stat-value">{value}</span>
    </div>
  )
}

export default function CurrentConditionsCard({ conditions }) {
  const description = conditions.weather_condition?.description?.text
  const temperature = formatTemperature(conditions.temperature)
  const feelsLike = formatTemperature(conditions.feels_like_temperature)
  const windSpeed = conditions.wind?.speed
  const humidity = conditions.relative_humidity
  const iconSrc = weatherIconUri(conditions.weather_condition)

  return (
    <Card
      className="surface-card"
      title={
        <Typography.Text strong style={{ fontSize: 16 }}>
          <ThunderboltOutlined style={{ marginRight: 8, color: "#0b6bcb" }} />
          Current Conditions
        </Typography.Text>
      }
    >
      <Row gutter={[24, 24]} align="middle">
        <Col xs={24} md={10}>
          <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
            {iconSrc && <img src={iconSrc} alt="" className="weather-icon" />}
            <div>
              <Typography.Title level={1} className="current-temp">
                {temperature || "--"}
              </Typography.Title>
              <Typography.Text style={{ fontSize: 18, color: "#34435a" }}>
                {description || "No description available"}
              </Typography.Text>
            </div>
          </div>
        </Col>

        <Col xs={24} md={14}>
          <Row gutter={[12, 12]}>
            {feelsLike && (
              <Col xs={12} sm={8}>
                <StatTile icon={<FireOutlined />} label="Feels like" value={feelsLike} />
              </Col>
            )}
            {humidity != null && (
              <Col xs={12} sm={8}>
                <StatTile icon={<CloudOutlined />} label="Humidity" value={`${humidity}%`} />
              </Col>
            )}
            {windSpeed && (
              <Col xs={12} sm={8}>
                <StatTile
                  icon={<DashboardOutlined />}
                  label="Wind"
                  value={`${windSpeed.value} ${windSpeed.unit?.replace(/_/g, " ").toLowerCase()}`}
                />
              </Col>
            )}
            {conditions.uv_index != null && (
              <Col xs={12} sm={8}>
                <StatTile icon={<EyeOutlined />} label="UV Index" value={conditions.uv_index} />
              </Col>
            )}
            {conditions.cloud_cover != null && (
              <Col xs={12} sm={8}>
                <StatTile icon={<CloudOutlined />} label="Cloud cover" value={`${conditions.cloud_cover}%`} />
              </Col>
            )}
          </Row>
        </Col>
      </Row>
    </Card>
  )
}
