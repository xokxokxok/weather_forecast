import { Card, Table, Typography } from "antd"
import { CalendarOutlined } from "@ant-design/icons"
import { formatDate, formatTemperature, weatherIconUri } from "../utils/weather"

export default function ForecastDaysCard({ forecast }) {
  const columns = [
    {
      title: "Date",
      dataIndex: "display_date",
      key: "date",
      render: (displayDate) => (
        <div>
          <Typography.Text strong>{formatDate(displayDate, { weekday: "long" })}</Typography.Text>
          <br />
          <Typography.Text type="secondary">{formatDate(displayDate)}</Typography.Text>
        </div>
      )
    },
    {
      title: "Condition",
      key: "condition",
      render: (_, record) => {
        const condition = record.daytime_forecast?.weather_condition
        const iconSrc = weatherIconUri(condition)

        return (
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            {iconSrc && <img src={iconSrc} alt="" className="forecast-icon" />}
            <span>{condition?.description?.text || "-"}</span>
          </div>
        )
      }
    },
    {
      title: "Low",
      key: "min",
      render: (_, record) => (
        <Typography.Text type="secondary">{formatTemperature(record.min_temperature)}</Typography.Text>
      )
    },
    {
      title: "High",
      key: "max",
      render: (_, record) => (
        <Typography.Text strong>{formatTemperature(record.max_temperature)}</Typography.Text>
      )
    }
  ]

  return (
    <Card
      className="surface-card full-width"
      title={
        <Typography.Text strong style={{ fontSize: 16 }}>
          <CalendarOutlined style={{ marginRight: 8, color: "#0b6bcb" }} />
          10-Day Forecast
        </Typography.Text>
      }
    >
      <Table
        rowKey={(record) => `${record.display_date?.year}-${record.display_date?.month}-${record.display_date?.day}`}
        columns={columns}
        dataSource={forecast.forecast_days || []}
        pagination={false}
        size="middle"
        rowClassName={(_, index) => (index % 2 === 0 ? "forecast-row-even" : "forecast-row-odd")}
      />
    </Card>
  )
}
