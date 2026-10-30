import React from "react"
import { createRoot } from "react-dom/client"
import { ConfigProvider } from "antd"
import AppLayout from "./components/AppLayout"
import HomePage from "./components/HomePage"
import { theme } from "./theme"

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("home-root")
  if (!container) return

  createRoot(container).render(
    <ConfigProvider theme={theme}>
      <AppLayout selectedKey="home">
        <HomePage />
      </AppLayout>
    </ConfigProvider>
  )
})
