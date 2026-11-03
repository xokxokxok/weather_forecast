import { Card, Table, Typography } from "antd"
import { CalendarOutlined } from "@ant-design/icons"
import { formatDate, formatTemperature, weatherIconUri } from "../utils/weather"
import CachedTag from "./CachedTag"

export default function ForecastDaysCard({ forecast }) {
  const columns = [
    {
      title: "Date",
      dataIndex: "date",
      key: "date",
      render: (date) => (
        <div>
          <Typography.Text strong>{formatDate(date, { weekday: "long" })}</Typography.Text>
          <br />
          <Typography.Text type="secondary">{formatDate(date)}</Typography.Text>
        </div>
      )
    },
    {
      title: "Condition",
      key: "condition",
      render: (_, record) => {
        const iconSrc = weatherIconUri(record.icon_base_uri)

        return (
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            {iconSrc && <img src={iconSrc} alt="" className="forecast-icon" />}
            <span>{record.description || "-"}</span>
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
        <div className="card-title">
          <Typography.Text strong style={{ fontSize: 16 }}>
            <CalendarOutlined style={{ marginRight: 8, color: "#0b6bcb" }} />
            10-Day Forecast
          </Typography.Text>
          <CachedTag cached={forecast.cached} />
        </div>
      }
    >
      <Table
        rowKey={(record) => `${record.date?.year}-${record.date?.month}-${record.date?.day}`}
        columns={columns}
        dataSource={forecast.days || []}
        pagination={false}
        size="middle"
        rowClassName={(_, index) => (index % 2 === 0 ? "forecast-row-even" : "forecast-row-odd")}
      />
    </Card>
  )
}
