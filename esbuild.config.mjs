import esbuild from "esbuild"

const watch = process.argv.includes("--watch")

const config = {
  entryPoints: ["app/javascript/home.jsx"],
  bundle: true,
  sourcemap: true,
  format: "esm",
  outdir: "app/assets/builds",
  loader: { ".js": "jsx", ".jsx": "jsx" },
  jsx: "automatic",
  logLevel: "info"
}

if (watch) {
  const context = await esbuild.context(config)
  await context.watch()
  console.log("Watching for changes...")
} else {
  await esbuild.build(config)
}
