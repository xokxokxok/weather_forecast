import { Card, Descriptions, Tag, Typography } from "antd"
import { EnvironmentOutlined, GlobalOutlined, TagOutlined } from "@ant-design/icons"

export default function PlaceDetailsCard({ place }) {
  const displayName = place.display_name?.text
  const location = place.location

  return (
    <Card
      className="surface-card full-width"
      title={
        <Typography.Text strong style={{ fontSize: 16 }}>
          <EnvironmentOutlined style={{ marginRight: 8, color: "#0b6bcb" }} />
          Selected Location
        </Typography.Text>
      }
    >
      <Descriptions column={{ xs: 1, sm: 2 }} size="middle">
        {displayName && (
          <Descriptions.Item label="Name">{displayName}</Descriptions.Item>
        )}
        {place.formatted_address && (
          <Descriptions.Item label="Address">{place.formatted_address}</Descriptions.Item>
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
            {place.types.slice(0, 4).map((type) => (
              <Tag key={type} icon={<TagOutlined />} style={{ marginBottom: 4 }}>
                {type.replaceAll("_", " ")}
              </Tag>
            ))}
          </Descriptions.Item>
        )}
      </Descriptions>

      {place.short_formatted_address && (
        <Typography.Paragraph type="secondary" style={{ marginBottom: 0, marginTop: 16 }}>
          <GlobalOutlined style={{ marginRight: 8 }} />
          {place.short_formatted_address}
        </Typography.Paragraph>
      )}
    </Card>
  )
}
