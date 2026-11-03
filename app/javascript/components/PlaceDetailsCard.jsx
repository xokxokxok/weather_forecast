import { Card, Descriptions, Tag, Typography } from "antd"
import { EnvironmentOutlined, GlobalOutlined, TagOutlined } from "@ant-design/icons"
import CachedTag from "./CachedTag"

export default function PlaceDetailsCard({ place }) {
  const location = place.location

  return (
    <Card
      className="surface-card full-width"
      title={
        <div className="card-title">
          <Typography.Text strong style={{ fontSize: 16 }}>
            <EnvironmentOutlined style={{ marginRight: 8, color: "#0b6bcb" }} />
            Searched Location
          </Typography.Text>
          <CachedTag cached={place.cached} />
        </div>
      }
    >
      <Descriptions column={{ xs: 1, sm: 2 }} size="middle">
        {place.name && (
          <Descriptions.Item label="Name">{place.name}</Descriptions.Item>
        )}
        {place.address && (
          <Descriptions.Item label="Address">{place.address}</Descriptions.Item>
        )}
        {location && (
          <Descriptions.Item label="Coordinates">
            <Typography.Text code>
              {location.latitude?.toFixed(6)}, {location.longitude?.toFixed(6)}
            </Typography.Text>
          </Descriptions.Item>
        )}
        {place.types?.length > 0 && (
          <Descriptions.Item label="Types">
            <div className="place-types">
              {place.types.slice(0, 4).map((type) => (
                <Tag key={type} icon={<TagOutlined />}>
                  {type.replaceAll("_", " ")}
                </Tag>
              ))}
            </div>
          </Descriptions.Item>
        )}
      </Descriptions>

      {place.short_address && (
        <Typography.Paragraph type="secondary" style={{ marginBottom: 0, marginTop: 16 }}>
          <GlobalOutlined style={{ marginRight: 8 }} />
          {place.short_address}
        </Typography.Paragraph>
      )}
    </Card>
  )
}
