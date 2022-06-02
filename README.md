# Arkham Horror LCG

![Screenshot](./docs/img/screenshot.png)

The goal of this project is to implement a web version of Arkham Horror with as
many of the rules implemented as possible.

## Warning

This is very much a work in progress. Things may break at any time, but if they do,
please file a bug.

## I just want to try this out on my computer

You will need to install [Docker][docker].

Afterwards you can run:

```
docker-compose up
```

And launch http://localhost:3000

## Features

* Multiplayer up to 4 players
* Multiplayer solitaire
* Deck import from ArkhamDB

## Finished Content

### Player Cards

* All player cards up to the Carcosa deluxe box

### Campaigns

* Night of the Zealot
  * Return to Night of the Zealot
* The Dunwich Legacy
* The Path To Carcosa (2/8)

### Side Stories

* The Curse of the Rougarou
* Carnevale of Horrors

## Local dev

### Dependencies

* Stack for GHC
* Node
* Postgresql
* Nginx (for local development)
* Sqitch (optional: for migrations)

### Local Setup

#### Running via Docker

The image is setup to use an external database passed via the `DATABASE_URL` environment variable. Follow the steps below to setup the database and then run the following commands

```
docker build -t arkham .
docker run -t -i -e PORT=3000 -e DATABASE_URL="postgres://docker:docker@host.docker.internal:5432/arkham-horror-backend" -p 3000:3000 arkham
```


#### Backend

Run `stack setup` in the `backend` directory, then run `stack build --fast` (note: this will still take a long time)

#### Frontend

Run `npm install` in the `frontend` directory

#### Database
Create the local database:

```
createdb arkham-horror-backend
cd migrations
sqitch deploy db:pg:arkham-horror-backend
```

If you do not have sqitch you can `cat migrations/deploy/*` to see the create
table statements and run them manually, you will want to specifically run the
`users` and `arkham_games` create table statements first.

### Running the server

* start the backend with `cd backend && make api.watch`
* start the frontend with `cd frontend && PORT=8081 npm run serve`
* start the ngingx server with ``nginx -c `pwd`/local.nginxconf``

## Copyright Disclaimer

The Card Game, both literal and graphical, is copyrighted by Fantasy Flight Games. This application and the corresponding website is not produced, endorsed, supported, or affiliated with Fantasy Flight Games.

[docker]: https://www.docker.com/
