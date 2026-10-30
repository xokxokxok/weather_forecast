import { Layout, Menu } from "antd"
import { CloudOutlined, HomeOutlined } from "@ant-design/icons"

const { Header, Content, Footer } = Layout

const menuItems = [
  {
    key: "home",
    icon: <HomeOutlined />,
    label: "Home"
  }
]

export default function AppLayout({ children, selectedKey = "home" }) {
  return (
    <Layout className="app-shell">
      <Header className="app-header">
        <div style={{ display: "flex", alignItems: "center", maxWidth: 1080, margin: "0 auto", width: "100%" }}>
          <div className="app-brand">
            <div className="app-brand-mark">
              <CloudOutlined />
            </div>
            Weather Forecast
          </div>
          <Menu
            theme="dark"
            mode="horizontal"
            selectedKeys={[selectedKey]}
            items={menuItems}
            style={{ flex: 1, minWidth: 0, borderBottom: "none", background: "transparent" }}
          />
        </div>
      </Header>

      <Content className="app-content">{children}</Content>

      <Footer style={{ textAlign: "center", background: "transparent", color: "#63738a" }}>
        Powered by Google Places & Weather APIs
      </Footer>
    </Layout>
  )
}
