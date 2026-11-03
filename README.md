# Weather Forecast

A Ruby on Rails application that takes an address and shows the current weather conditions and a 10-day forecast for it. Weather data is cached by zip code for 30 minutes, and every result shows when it was loaded from the cache.

- [1. The assignment](#1-the-assignment)
- [2. Introduction](#2-introduction)
- [3. Overview](#3-overview)
- [4. Problems found and open questions](#4-problems-found-and-open-questions)
- [5. Decisions](#5-decisions)
- [6. Proposed solution](#6-proposed-solution)
- [7. Google Maps Platform pricing](#7-google-maps-platform-pricing)
- [8. Getting started](#8-getting-started)

## 1. The assignment

Requirements:

- Must be done in Ruby on Rails
- Accept an address as input
- Retrieve forecast data for the given zip code. This should include, at minimum, the current temperature (Bonus points - Retrieve high/low and/or extended forecast)
- Display the requested forecast details to the user
- Cache the forecast details for 30 minutes for all subsequent requests by zip codes.
- Display an indicator if the result is pulled from cache.

Assumptions:

- This project is open to interpretation
- Functionality is a priority over form
- If you get stuck, complete as much as you can

Submission:

- Use a public source code repository (GitHub, etc) to store your code
- Send us the link to your completed code

## 2. Introduction

The user types an address (or a zip code, a park, a store, any place) and gets:

- the place that was found (name, formatted address, coordinates and types);
- the current conditions (temperature, feels like, humidity, wind, UV index, cloud cover);
- a 10-day forecast with the high and low temperature of each day;
- a "Loaded from cache" tag on each weather card whose data came from the cache.

All the data comes from Google Maps Platform APIs: Places API (New), Geocoding API (v4) and Weather API.

## 3. Overview

This is a technical assessment, not a real product. There is no real business context behind it, so the decisions along the way were based on what I assumed the need could be. They are not necessarily the best path, and there are parts of the code that could be optimized. The goal was to do what is needed to meet the assignment.

The problem is presented in a simple, straightforward way, but it allows many possible solutions. After thinking through several of them, I decided to use the Google APIs, and with that choice some parts of the assignment may not make as much sense as they would with another approach (the zip code cache, for example, see below). It is possible that the problem ended up being mischaracterized in some way.

If this were a real problem, a concrete difficulty of a company in a real situation, it would be much easier to understand the need and to choose a better path.

## 4. Problems found and open questions

- **What is the zip code cache meant to achieve?** The assignment asks to cache the forecast by zip code for 30 minutes, but it does not say why. The reason was left open.
- **Not every place has a zip code.** The Places API is very broad: an autocomplete result can be a formal address, but also a park, a store, a landmark or any point of interest. Usually there is some address, even a generic one, and when there is no formal address it is basically the name of the place. Many of these results have no zip code, so using only the Places API to get a zip code for the weather cache would not work in every case.
- **Why cache at all?** The usual reason for caching is saving money. Looking at the prices (section 7), the Places API is the most expensive part of the flow, so caching it would probably bring more savings. But a Places cache could not live too long (years), because addresses change, and a long-lived cache would belong in a database rather than in Redis. The Weather API, on the other hand, is very cheap: with the 5 endpoints used here, I did not see a real need to cache the weather, other than request speed.
- **Which strategy fits?** Without a real use case, and after considering many possible solutions, it was hard to define a strategy that would be adequate for the real use of this application, which I do not know.

## 5. Decisions

1. **Google APIs.** The assignment does not suggest any API. I chose the Google Places API for the addresses and, after researching weather APIs, the Google Weather API for the weather. The Geocoding API was added later to solve the zip code problem.
2. **Autocomplete, but free text is accepted.** The Places autocomplete is used to suggest places while the user types (debounced by 1 second). The user can pick a suggestion, but can also submit the text without picking one. Picking a suggestion only fills the field; the search runs when the user clicks **Search** or presses Enter.
3. **Place details by `place_id`.** Every search ends in a `place_id`: the one from the picked suggestion or, for free text, the one from the first autocomplete suggestion for that text. The place details are fetched with it, and those details start the weather part.
4. **Geocoding fallback for the zip code.** The place details usually include a zip code. When they don't (a park, for example), the Geocoding API is used to find the nearest formal addresses that have one: a reverse geocode of the place coordinates filtered by `types=postal_code`.
5. **5 km radius.** From what I observed in the Weather API data, below 5 km there is rarely any microclimate variation; from 5 km on, small variations start to show up (in the order of 0.01 degree), and between 5 and 10 km the variation is still very small. So the zip codes within 5 km are kept, sorted nearest first. If none is within 5 km, the nearest one is used. The nearest becomes `zip_code`, and the others are returned as `nearby_zip_codes`. It is not a perfect rule; it is the solution I proposed, given that there was no guideline to follow.
6. **The zip code is only a cache key.** The Weather API works only with latitude and longitude. The zip code is used only as the Redis cache key. With a list of zip codes, any of them can be used, because they are all near the region: the lookup tries `zip_code` first and then each of the `nearby_zip_codes`, and uses the first one already in the cache; if none is cached, the result is stored under `zip_code`. This greedy approach (always prefer the nearest) covers at least most cases.
7. **Two Weather API endpoints.** `currentConditions:lookup` gives the most detailed data (current conditions). `forecast/days:lookup` gives a daily summary for the next days, like a calendar.
8. **Cache in Redis.** I understood that the proposal was built around Redis, so all caches use Redis (`Rails.cache`):
   - Weather: 30 minutes, as required.
   - Places details and Geocoding: 1 day.

   In my opinion, these caches would bring, at most, a small saving for a medium or large system, plus faster requests. They would also help contain uncontrolled requests, or an attack meant to generate API costs, although that is not the context of this application.
9. **One generic client, three subclasses.** The three Google clients (Places, Geocoding and Weather) are very similar, so there is a generic `Google::BaseClient` with all the HTTP, caching and error handling code, and each client only defines its base URL, cache lifetime, API key name, service name and error class.
10. **API classes with the parser inside.** The API classes (the classes that use the clients) have no common base, and each one parses the Google response into a small hash inside the class itself. I would normally extract a base class and separate parsers, but the code is small and will probably not be extended, so keeping it inside was simpler and did not hurt the code quality. The trade-off: this was not built to swap clients. With a separate parser class, the client and the parser could be swapped together while keeping the same response for the rest of the project.

    I am not in favor of parsing inside the API class in general. In a real project, an API like Google's is usually used in many places and returns a lot of coupled data in one request, so a fixed parser keeps needing changes (which field is returned, where, converted to what); keeping the API format is often better. Here the scope is small, and the parse makes the data simpler to read and to use in the front-end. It is a reasonable simplification for small projects, but not advisable for large ones. The project being small is an assumption, since it is not a real project.
11. **Front-end generated with AI.** The goal was to evaluate the Ruby on Rails part, so the front-end (React + Ant Design) was basically written by AI; I changed very little, fixing and checking some parts. In the rest of the code I took more care to write it myself, to keep it cleaner, since AI usually does not deliver very clean code.
12. **Errors handled in the controller.** Errors are handled in the controllers so that every failure is answered as a regular JSON response with an HTTP error code and a message (`{ "error": "..." }`), instead of an unhandled exception. The message and the status depend on where the error happened: an error in the client (Google returned an error, a timeout, the API key is missing) keeps the client message and status, while an error in the API class (for example, a response that could not be parsed) gets a message prefixed with the API class and the operation. See [Error handling](#error-handling).
13. **Tests with RSpec, VCR cassettes and stubs.** All the tests are written in RSpec. Part of the requests to Google are real responses recorded with VCR cassettes and replayed in the following runs. For some cases (mainly the error cases), I stubbed the request instead, because it was much more practical than recording a real response.

## 6. Proposed solution

### Flow

```
Browser                         Rails API (app/controllers/api/v1)           Google
-------                         ----------------------------------           ------
type text  ───────────────────▶ GET /api/v1/locations                ──────▶ Places   places:autocomplete
(optional, debounced)            (suggestions)

click Search ─────────────────▶ GET /api/v1/locations/:place_id      ──────▶ Places   places/{place_id} (details)
                                 └─ no zip code in the details?       ──────▶ Geocoding geocode/location (types=postal_code)
                                    → zip_code + nearby_zip_codes

with lat/lng + zip codes ─────▶ GET /api/v1/weather_conditions/current ────▶ Weather  currentConditions:lookup
                          ─────▶ GET /api/v1/weather_conditions          ────▶ Weather  forecast/days:lookup (10 days)
```

When the user submits free text without picking a suggestion, the front-end first calls `GET /api/v1/locations` with that text and uses the first suggestion. The autocomplete calls and the place details call share one session token, which is renewed after every search.

### Application API

| Request | Params | Returns |
|---|---|---|
| `GET /api/v1/locations` | `q[input]`, `q[session_token]` | `{ session_token, locations: [{ place_id, address }] }` |
| `GET /api/v1/locations/:place_id` | `q[session_token]` (required) | `{ place_id, name, address, short_address, zip_code, location: { latitude, longitude }, types }`, plus `nearby_zip_codes` when the Geocoding fallback was used |
| `GET /api/v1/weather_conditions/current` | `latitude`, `longitude`, `zip_code` (required), `nearby_zip_codes[]` (optional) | `{ description, icon_base_uri, temperature, feels_like_temperature, relative_humidity, uv_index, cloud_cover, wind_speed, cached }` |
| `GET /api/v1/weather_conditions` | same as above | `{ days: [{ date, description, icon_base_uri, min_temperature, max_temperature }], cached }` |


### Google endpoints and cache

| Client | Endpoint | Cache key | Cache lifetime |
|---|---|---|---|
| `Google::PlaceClient` | `POST places.googleapis.com/v1/places:autocomplete` | none | none |
| `Google::PlaceClient` | `GET places.googleapis.com/v1/places/{place_id}` | `places/{place_id}` | 1 day |
| `Google::GeocodingClient` | `GET geocode.googleapis.com/v4/geocode/location` | `geocoding_nearby_zip_codes_{address}` | 1 day |
| `Google::WeatherClient` | `GET weather.googleapis.com/v1/currentConditions:lookup` | `weather_current_conditions_{zip_code}` | 30 minutes |
| `Google::WeatherClient` | `GET weather.googleapis.com/v1/forecast/days:lookup` | `weather_forecast_days_{zip_code}` | 30 minutes |

Every client response carries `cached: true` when it came from the cache and `cached: false` otherwise. The front-end shows the "Loaded from cache" tag on each card whose data has `cached: true`. The place details response does not include `cached` yet, so the tag currently shows only on the Current Conditions and 10-Day Forecast cards.

### Code layout

```
lib/google/
  base_client.rb       generic HTTP client: Faraday, timeouts, Rails.cache, `cached` flag, error handling
  base_error.rb        Google::BaseError, an error with an HTTP status
  place_client.rb      Places API (New) client
  geocoding_client.rb  Geocoding API (v4) client
  weather_client.rb    Weather API client
  place_api.rb         autocomplete_address, place_details (+ parsers)
  geocoding_api.rb     nearby_zip_codes (+ distance filter and parser)
  weather_api.rb       current_conditions, forecast_days (+ cache key selection and parsers)
app/controllers/api/v1/
  locations_controller.rb           index (autocomplete), show (details + Geocoding fallback)
  weather_conditions_controller.rb  show (current conditions), index (forecast)
app/javascript/                     React + Ant Design front-end, bundled with esbuild
spec/                               RSpec tests (clients, APIs and request specs) with VCR cassettes
```

### Error handling

Every error is answered as JSON, `{ "error": "<message>" }`, with an HTTP status:

- The controllers validate the required params and answer `400` themselves.
- The clients (`Google::PlaceClient`, `Google::GeocodingClient`, `Google::WeatherClient`) raise their own `Error`, a `Google::BaseError` that carries an HTTP status.
- The API classes (`Google::PlaceApi`, `Google::GeocodingApi`, `Google::WeatherApi`) wrap any error in their own `Error`. When the error comes from the client, they keep the client message and status; otherwise (for example, a parser error) they prefix the message with the API class and the operation.
- `Api::ApplicationController` rescues `Google::PlaceApi::Error`, `Google::GeocodingApi::Error` and `Google::WeatherApi::Error` and renders the message with the error status.

| Where | Case | HTTP status | Message example |
|---|---|---|---|
| Controller | Missing `session_token` (locations) | 400 | `place_id and session_token are required` |
| Controller | Missing `zip_code` (weather) | 400 | `at least one of zip_code or nearby_zip_codes is required` |
| Controller | Missing `latitude` or `longitude` (weather) | 400 | `latitude and longitude are required` |
| Client | API key missing from the credentials | 500 | `GOOGLE_PLACE_API_KEY not found in credentials` |
| Client | Google returned an error (4xx/5xx) | 502 | `Google Place Client Error code: 500` |
| Client | Google rate limit (429) | 429 | `Google Weather Client Error code: 429` |
| Client | Read or connection timeout | 504 | `Google Weather Client read timeout` / `... connection timeout` |
| Client | Google unreachable | 503 | `Google Geocoding Client is unreachable` |
| Client | Response is not valid JSON, or not a JSON object | 502 | `Google Place Client returned an invalid response` |
| API class | Response could not be parsed | 200 (see below) | `Google::PlaceApi place details error: <original error>` |

Known limitation: errors raised inside the API classes (such as a parser error) have no HTTP status, so the error JSON is currently returned with status `200`. This was checked with a request against a stubbed Place Details response without `addressComponents`.

## 7. Google Maps Platform pricing

Prices from the official price list, consulted on November 2, 2026 ([Google Maps Platform pricing](https://developers.google.com/maps/billing-and-pricing/pricing)). First paid tier, in USD per 1,000 billable events.

| API | SKU | Free per month | Price per 1,000 | Used here |
|---|---|---|---|---|
| Places | Autocomplete Requests | 10,000 | $2.83 | `places:autocomplete` |
| Places | Autocomplete Session Usage | unlimited | not charged | autocomplete calls of a session completed with Place Details |
| Places | Place Details Essentials | 10,000 | $5.00 | `places/{place_id}` (Essentials or Pro, see note) |
| Places | Place Details Pro | 5,000 | $17.00 | `places/{place_id}` (Essentials or Pro, see note) |
| Geocoding | Geocoding | 10,000 | $5.00 | `geocode/location` |
| Weather | Weather Usage | 10,000 | $0.15 | `currentConditions:lookup`, `forecast/days:lookup` |

Weather Usage volume tiers: 10,001 to 100,000: $0.15; 100,001 to 500,000: $0.12; 500,001 to 1,000,000: $0.09; 1,000,001 to 5,000,000: $0.06; above 5,000,000: $0.038. Each successful Weather API request is one billable event ([Environment SKU details](https://developers.google.com/maps/billing-and-pricing/sku-details/environment)).

Notes:

- Autocomplete requests are free when the session ends with a Place Details request using the same session token; an abandoned session is charged per autocomplete request ([How the Places API is billed](https://developers.google.com/maps/documentation/places/web-service/usage-and-billing/)).
- Place Details is charged at the highest SKU required by the fields in the field mask. I did not verify which SKU the field mask used here falls into.

## 8. Getting started

All commands run from the project root, in any terminal with Docker available (Windows PowerShell or a WSL2 terminal, for example). Ruby and Node.js are not needed on the host: both run inside the `web` container.

### Requirements

- Docker with Docker Compose
- A Google Cloud API key with **Places API (New)**, **Geocoding API** and **Weather API** enabled (the same key can be used for the three)

### 1. API keys (Rails credentials)

The keys are stored in the encrypted Rails credentials. `config/master.key` is not in the repository, so without it the committed `config/credentials.yml.enc` cannot be read. In that case, delete `config/credentials.yml.enc` and create new credentials:

```bash
docker compose run --rm -e EDITOR=nano web bin/rails credentials:edit
```

Add the keys:

```yaml
GOOGLE_PLACE_API_KEY: your-key
GOOGLE_GEOCODING_API_KEY: your-key
GOOGLE_WEATHER_API_KEY: your-key
```

### 2. Build and start the containers

```bash
docker compose up --build
```

This starts three services:

| Service | Image | Host port |
|---|---|---|
| `db` | PostgreSQL 17 | 5433 |
| `redis` | Redis 7 (cache) | not published |
| `web` | Rails 8.1 on Ruby 3.3.11 | 3100 |

When `web` starts the Rails server, `bin/docker-entrypoint` runs `bin/rails db:prepare`, `npm install`, `npm run build`, and keeps `npm run build:watch` running, so the front-end is rebuilt on every change.

Open http://localhost:3100.

### 3. Run the tests

All the tests are written in RSpec. Part of the Google requests use VCR cassettes (real responses, recorded once and replayed), and some use WebMock stubs, which were more practical for those cases. The first time, prepare the test database:

```bash
docker compose exec -e RAILS_ENV=test web bin/rails db:prepare
```

Run the suite:

```bash
docker compose exec -e RAILS_ENV=test web bundle exec rspec
```

`RAILS_ENV=test` is required because `docker-compose.yml` sets `RAILS_ENV=development` for the `web` service.

What is covered:

- `spec/lib/google/*_client_spec.rb`: success cases for each client and, through shared examples, every error branch (missing API key, rejected key, 429, 5xx, read and connection timeouts, unreachable host, invalid JSON, non-object JSON) and the `cached` flag.
- `spec/lib/google/*_api_spec.rb`: for each endpoint, the success case, a Google error and a parser error.
- `spec/requests/api/v1/*_spec.rb`: both controllers, including the Geocoding fallback (place with zip code, place without zip code, Places failure, Geocoding failure) and missing required params.

The success cases replay real Google responses recorded with VCR in `spec/fixtures/vcr_cassettes/`. The API keys are replaced by placeholders before recording (`spec/support/vcr.rb`), and the error cases use WebMock stubs. To record a cassette again, delete its file and run the spec with valid API keys in the credentials.

### 4. RuboCop

The project uses `rubocop-rails-omakase`, with one change in `.rubocop.yml`: single quotes by default (double quotes only when needed, such as interpolation), also applied to `spec/`.

```bash
docker compose exec web bin/rubocop          # check
docker compose exec web bin/rubocop -a       # autocorrect safe offenses
```

### 5. Other useful commands

```bash
# Clear the cache (Redis database 0, used by Rails.cache in development)
docker compose exec redis redis-cli -n 0 FLUSHDB
# or, through Rails
docker compose exec web bin/rails runner "Rails.cache.clear"

# Rails console
docker compose exec web bin/rails console

# Follow the Rails log
docker compose logs -f web

# Security checks (also run by the CI)
docker compose exec web bin/brakeman --no-pager
docker compose exec web bin/bundler-audit

# Stop the containers
docker compose down
```

If the containers are not running, replace `exec` with `run --rm` (for example, `docker compose run --rm web bin/rubocop`).

### 6. Running the specs from RubyMine (optional)

Add a Docker Compose remote interpreter (Settings › Languages & Frameworks › Ruby SDK and Gems › Add › Remote Interpreter or Version Manager › Docker Compose, service `web`). In Run › Edit Configurations › Edit configuration templates › RSpec, set the docker-compose mode to `exec` (with the default `up`, running a spec stops the `web` container) and add the environment variable `RAILS_ENV=test`.
