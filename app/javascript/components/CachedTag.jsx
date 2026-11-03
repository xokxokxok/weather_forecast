import { Tag } from "antd"
import { DatabaseOutlined } from "@ant-design/icons"

// Shown on the right side of a card title when the card data came from the server cache
export default function CachedTag({ cached }) {
  if (!cached) return null

  return (
    <Tag color="blue" icon={<DatabaseOutlined />} className="cached-tag">
      Loaded from cache
    </Tag>
  )
}
