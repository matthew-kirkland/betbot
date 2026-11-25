-- Bookmakers
CREATE TABLE bookmakers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL UNIQUE,
    base_url        TEXT NOT NULL
);

-- Sports
CREATE TABLE sports (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL UNIQUE
);

-- Competitions
CREATE TABLE competitions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sport_id        UUID NOT NULL REFERENCES sports(id),
    name            TEXT NOT NULL,
    UNIQUE (sport_id, name)
);

-- Teams
CREATE TABLE teams (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL
);

-- Team aliases: solves fuzzy matching a team name e.g "Man Utd", "Manchester United FC"
CREATE TABLE team_aliases (
    bookmaker_id    UUID NOT NULL REFERENCES bookmakers(id),
    alias           TEXT NOT NULL,
    team_id         UUID NOT NULL REFERENCES teams(id),
    PRIMARY KEY (bookmaker_id, alias)
);

-- Events: canonical records of each game that will happen
CREATE TABLE events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id  UUID NOT NULL REFERENCES competitions(id),
    home_team_id    UUID NOT NULL REFERENCES teams(id),
    away_team_id    UUID NOT NULL REFERENCES teams(id),
    start_time      TIMESTAMPTZ NOT NULL,
    UNIQUE (home_team_id, away_team_id, start_time)
);

-- Bookmaker events: contains references to an event for particular bookmakers
CREATE TABLE bookmaker_events (
    bookmaker_id    UUID NOT NULL REFERENCES bookmakers(id),
    external_id     TEXT NOT NULL,
    event_id        UUID REFERENCES events(id) ON DELETE CASCADE,
    raw_home_name   TEXT NOT NULL,
    raw_away_name   TEXT NOT NULL,
    raw_competition TEXT,
    url             TEXT,
    start_time      TIMESTAMPTZ NOT NULL
);
CREATE INDEX bookmaker_events_event_idx ON bookmaker_events (event_id);
CREATE INDEX bookmaker_events_start_time_idx ON bookmaker_events (start_time);

-- Markets: type of outcome you can bet on
CREATE TABLE markets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id        UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    type            TEXT NOT NULL CHECK (type IN ('h2h')),
    UNIQUE (event_id, type)
);

-- Current odds: the current best odds for an event
CREATE TABLE current_odds (
    market_id       UUID NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    bookmaker_id    UUID NOT NULL REFERENCES bookmakers(id),
    outcome         TEXT NOT NULL CHECK (outcome IN ('home', 'draw', 'away')),
    price           NUMERIC(8,3) NOT NULL CHECK (price > 1),
    fetched_at      TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (market_id, bookmaker_id, outcome)
);

-- Odds history: records of all odds scraped for upcoming events
CREATE TABLE odds_history (
    market_id       UUID NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    bookmaker_id    UUID NOT NULL REFERENCES bookmakers(id),
    outcome         TEXT NOT NULL CHECK (outcome IN ('home', 'draw', 'away')),
    price           NUMERIC(8,3) NOT NULL,
    fetched_at      TIMESTAMPTZ NOT NULL
);
CREATE INDEX odds_history_lookup_idx ON odds_history (market_id, bookmaker_id, outcome, fetched_at);
