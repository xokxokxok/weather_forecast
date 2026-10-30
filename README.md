# Weather Forecast

Search for an address and see the current weather and a 10-day forecast.

Built with Rails 8.1, PostgreSQL and React (Ant Design). Addresses come from the Google Places API and weather data from the Google Weather API. Forecasts are cached by zip code for 30 minutes.

## Setup

Requires Docker and Node.js.

Add your Google API keys to the Rails credentials:

```bash
docker compose run --rm -e EDITOR=nano web bin/rails credentials:edit
```

```yaml
GOOGLE_PLACE_API_KEY: your-key
GOOGLE_WEATHER_API_KEY: your-key
```

Build the frontend:

```bash
npm install
npm run build
```

Start the app:

```bash
docker compose up --build
```

Open http://localhost:3100.

Use `npm run build:watch` to rebuild the frontend while editing.
