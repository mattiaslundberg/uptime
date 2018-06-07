# Uptime

Check if website is up and notifies by text if down.

Checking logic is in `/backend/`. Phoenix API and Elm frontend is in `uptime_gui`.

## Running web application

1. `cd uptime_gui`
2. Setup postgres server (username: phoenix, password: phoenix)
3. `mix deps.get` to install dependencies
4. `mix ecto.create` to create database
5. `mix phx.server` to run server
6. Visit http://localhost:4000

## Running tests

1. `cd uptime_gui` or `cd backend` tests separated per mix application
2. `mix test.watch` to start tests that reruns on code changes
