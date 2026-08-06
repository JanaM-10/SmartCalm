-- ============================================================
-- SmartCalm Supabase Schema v2
-- Run this in your Supabase SQL editor
-- ============================================================

-- ── 1. USERS ─────────────────────────────────────────────────
CREATE TABLE users (
    id              UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name            TEXT NOT NULL,
    device_id       TEXT,
    alerts_enabled          BOOLEAN DEFAULT true,
    wearable_feedback       BOOLEAN DEFAULT true,
    preferred_calm_sound    TEXT DEFAULT 'Rain',
    preferred_calm_actions  TEXT[] DEFAULT ARRAY['Breathing', 'Sound'],
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ── 2. STRESS READINGS ───────────────────────────────────────
CREATE TABLE stress_readings (
    id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id       UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    device_id     TEXT NOT NULL,
    timestamp     TIMESTAMPTZ NOT NULL,
    stress_level  TEXT NOT NULL CHECK (stress_level IN ('Calm', 'Mild', 'High')),
    stress_code   INTEGER NOT NULL CHECK (stress_code IN (0, 1, 2)),
    confidence    FLOAT NOT NULL,
    prob_calm     FLOAT NOT NULL,
    prob_mild     FLOAT NOT NULL,
    prob_high     FLOAT NOT NULL,
    heart_rate    FLOAT,
    skin_temp     FLOAT,
    skin_response FLOAT,
    movement      FLOAT,
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- ── 3. CALM SESSIONS ─────────────────────────────────────────
CREATE TABLE calm_sessions (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    reading_id      UUID REFERENCES stress_readings(id) ON DELETE SET NULL,
    stress_level    TEXT NOT NULL CHECK (stress_level IN ('Calm', 'Mild', 'High')),
    activity_type   TEXT NOT NULL,
    activity_name   TEXT,
    duration_seconds INTEGER DEFAULT 0,
    completed       BOOLEAN DEFAULT false,
    started_at      TIMESTAMPTZ DEFAULT now(),
    ended_at        TIMESTAMPTZ
);

-- ── 4. JOURNAL ENTRIES ───────────────────────────────────────
CREATE TABLE journal_entries (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id     UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    reading_id  UUID REFERENCES stress_readings(id) ON DELETE SET NULL,
    stress_level TEXT CHECK (stress_level IN ('Calm', 'Mild', 'High')),
    content     TEXT NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── INDEXES ──────────────────────────────────────────────────
CREATE INDEX idx_stress_readings_user_id    ON stress_readings(user_id);
CREATE INDEX idx_stress_readings_timestamp  ON stress_readings(timestamp DESC);
CREATE INDEX idx_calm_sessions_user_id      ON calm_sessions(user_id);
CREATE INDEX idx_calm_sessions_started_at   ON calm_sessions(started_at DESC);
CREATE INDEX idx_journal_entries_user_id    ON journal_entries(user_id);
CREATE INDEX idx_journal_entries_created_at ON journal_entries(created_at DESC);

-- ── ROW LEVEL SECURITY ───────────────────────────────────────
ALTER TABLE users           ENABLE ROW LEVEL SECURITY;
ALTER TABLE stress_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE calm_sessions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own profile"    ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile"  ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users insert own profile"  ON users FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users read own readings"   ON stress_readings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Service role insert readings" ON stress_readings FOR INSERT WITH CHECK (true);

CREATE POLICY "Users read own calm sessions"   ON calm_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own calm sessions" ON calm_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own calm sessions" ON calm_sessions FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users read own journal"   ON journal_entries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own journal" ON journal_entries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own journal" ON journal_entries FOR DELETE USING (auth.uid() = user_id);

-- ── AUTO-UPDATE updated_at ────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
