-- =====================================================================
-- VILLAGE EXCHANGE — CONSOLIDATED SCHEMA
-- Replaces FILE 1 + FILE 3 + FILE 4 (which conflicted with each other).
-- Run this FIRST, then 02_seed.sql.
--
-- WARNING: this drops and recreates all app tables. Demo data only.
-- =====================================================================

-- ---------- 0. Clean slate ----------
DROP TABLE IF EXISTS complaints CASCADE;
DROP TABLE IF EXISTS reviews    CASCADE;
DROP TABLE IF EXISTS requests   CASCADE;
DROP TABLE IF EXISTS listings   CASCADE;
DROP TABLE IF EXISTS users      CASCADE;

DROP FUNCTION IF EXISTS recalculate_user_trust(UUID)     CASCADE;
DROP FUNCTION IF EXISTS trg_review_trust()               CASCADE;
DROP FUNCTION IF EXISTS trg_complaint_trust()            CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column()       CASCADE;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ---------- 1. Shared helper: updated_at ----------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ---------- 2. Tables ----------

-- NOTE ON AUTH: users.id is NOT foreign-keyed to auth.users, so seed data
-- can be inserted freely. For real phone-OTP signup, the app MUST insert
-- the profile row with id = auth.uid(), otherwise every RLS policy below
-- will silently deny access.
CREATE TABLE users (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name         TEXT NOT NULL,
    phone        TEXT NOT NULL UNIQUE,
    village      TEXT NOT NULL,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    trust_score  FLOAT DEFAULT 5.0,
    badge_level  TEXT  DEFAULT 'New trader',
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    updated_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE listings (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title        TEXT NOT NULL,
    description  TEXT,
    category     TEXT NOT NULL,
    type         TEXT NOT NULL CHECK (type IN ('rent','lend','sell','exchange')),
    photo_url    TEXT,
    status       TEXT NOT NULL DEFAULT 'active'
                 CHECK (status IN ('active','inactive','completed')),
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    updated_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE requests (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id   UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status       TEXT NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','accepted','rejected','completed')),
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    updated_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reviews (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id  UUID NOT NULL REFERENCES requests(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reviewee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating      INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT reviewer_not_reviewee      CHECK (reviewer_id <> reviewee_id),
    CONSTRAINT unique_review_per_request  UNIQUE (request_id, reviewer_id)
);

CREATE TABLE complaints (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id     UUID NOT NULL REFERENCES requests(id) ON DELETE CASCADE,
    complainant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    respondent_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category       TEXT NOT NULL
                   CHECK (category IN ('damaged','stolen','no-show','other')),
    description    TEXT,
    status         TEXT NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending','investigating','resolved','dismissed')),
    created_at     TIMESTAMPTZ DEFAULT NOW(),
    updated_at     TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT complainant_not_respondent CHECK (complainant_id <> respondent_id)
);


-- ---------- 3. Indexes ----------
CREATE INDEX idx_listings_owner_id   ON listings(owner_id);
CREATE INDEX idx_listings_status     ON listings(status);
CREATE INDEX idx_listings_type       ON listings(type);
CREATE INDEX idx_listings_category   ON listings(category);
CREATE INDEX idx_listings_location   ON listings(location_lat, location_lng);

CREATE INDEX idx_requests_listing_id   ON requests(listing_id);
CREATE INDEX idx_requests_requester_id ON requests(requester_id);
CREATE INDEX idx_requests_status       ON requests(status);

CREATE INDEX idx_reviews_reviewer_id ON reviews(reviewer_id);
CREATE INDEX idx_reviews_reviewee_id ON reviews(reviewee_id);
CREATE INDEX idx_reviews_request_id  ON reviews(request_id);

CREATE INDEX idx_complaints_request_id     ON complaints(request_id);
CREATE INDEX idx_complaints_complainant_id ON complaints(complainant_id);
CREATE INDEX idx_complaints_respondent_id  ON complaints(respondent_id);
CREATE INDEX idx_complaints_status         ON complaints(status);


-- ---------- 4. Trust score engine ----------

-- Pure calculator. Takes a user id, recomputes and stores their score/badge.
CREATE OR REPLACE FUNCTION recalculate_user_trust(target_user_id UUID)
RETURNS VOID AS $$
DECLARE
    avg_rating      FLOAT;
    review_count    INTEGER;
    complaint_count INTEGER;
    new_score       FLOAT;
    new_badge       TEXT;
BEGIN
    SELECT COALESCE(AVG(rating), 5.0), COUNT(*)
      INTO avg_rating, review_count
      FROM reviews
     WHERE reviewee_id = target_user_id;

    SELECT COUNT(*)
      INTO complaint_count
      FROM complaints
     WHERE respondent_id = target_user_id
       AND status <> 'dismissed';

    -- 70% weight on rating, 30% on a complaint-penalised baseline
    new_score := (avg_rating * 0.7) + ((5.0 - (complaint_count * 0.5)) * 0.3);
    new_score := GREATEST(LEAST(new_score, 5.0), 0.0);

    -- Badge names match the frontend spec: Verified / New trader / Flagged
    IF review_count = 0 AND complaint_count = 0 THEN
        new_badge := 'New trader';
    ELSIF complaint_count >= 2 OR new_score < 3.0 THEN
        new_badge := 'Flagged';
    ELSIF new_score >= 4.0 THEN
        new_badge := 'Verified';
    ELSE
        new_badge := 'Member';
    END IF;

    UPDATE users
       SET trust_score = new_score,
           badge_level = new_badge
     WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger wrappers. A trigger function takes NO arguments and must return
-- TRIGGER — it reads NEW/OLD from the trigger context itself. This is the
-- part Cascade got wrong.
CREATE OR REPLACE FUNCTION trg_review_trust()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM recalculate_user_trust(OLD.reviewee_id);
        RETURN OLD;
    END IF;

    PERFORM recalculate_user_trust(NEW.reviewee_id);

    IF TG_OP = 'UPDATE' AND OLD.reviewee_id IS DISTINCT FROM NEW.reviewee_id THEN
        PERFORM recalculate_user_trust(OLD.reviewee_id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trg_complaint_trust()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM recalculate_user_trust(OLD.respondent_id);
        RETURN OLD;
    END IF;

    PERFORM recalculate_user_trust(NEW.respondent_id);

    IF TG_OP = 'UPDATE' AND OLD.respondent_id IS DISTINCT FROM NEW.respondent_id THEN
        PERFORM recalculate_user_trust(OLD.respondent_id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ---------- 5. Triggers ----------
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_listings_updated_at
    BEFORE UPDATE ON listings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_requests_updated_at
    BEFORE UPDATE ON requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at
    BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_complaints_updated_at
    BEFORE UPDATE ON complaints
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER reviews_trust_recalc
    AFTER INSERT OR UPDATE OR DELETE ON reviews
    FOR EACH ROW EXECUTE FUNCTION trg_review_trust();

CREATE TRIGGER complaints_trust_recalc
    AFTER INSERT OR UPDATE OR DELETE ON complaints
    FOR EACH ROW EXECUTE FUNCTION trg_complaint_trust();


-- ---------- 6. Row Level Security ----------
ALTER TABLE users      ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings   ENABLE ROW LEVEL SECURITY;
ALTER TABLE requests   ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews    ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;

-- users: public profiles are readable (needed for owner name, rating,
-- and the verification badge on Browse / Resource Detail). Write is self-only.
CREATE POLICY "Anyone can view profiles"
    ON users FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE USING (auth.uid() = id);

-- listings: world-readable, owner-writable
CREATE POLICY "Anyone can view listings"
    ON listings FOR SELECT USING (true);
CREATE POLICY "Users can create own listings"
    ON listings FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Users can update own listings"
    ON listings FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Users can delete own listings"
    ON listings FOR DELETE USING (auth.uid() = owner_id);

-- requests: visible to the requester and the listing owner
CREATE POLICY "Participants can view requests"
    ON requests FOR SELECT
    USING (
        auth.uid() = requester_id
        OR EXISTS (
            SELECT 1 FROM listings l
             WHERE l.id = requests.listing_id AND l.owner_id = auth.uid()
        )
    );
CREATE POLICY "Users can create requests"
    ON requests FOR INSERT WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "Participants can update requests"
    ON requests FOR UPDATE
    USING (
        auth.uid() = requester_id
        OR EXISTS (
            SELECT 1 FROM listings l
             WHERE l.id = requests.listing_id AND l.owner_id = auth.uid()
        )
    );
CREATE POLICY "Requesters can delete own requests"
    ON requests FOR DELETE USING (auth.uid() = requester_id);

-- reviews: public read (they drive the star rating shown to everyone),
-- insert only by a participant of a COMPLETED request, one per request.
CREATE POLICY "Anyone can view reviews"
    ON reviews FOR SELECT USING (true);
CREATE POLICY "Participants can review completed requests"
    ON reviews FOR INSERT
    WITH CHECK (
        auth.uid() = reviewer_id
        AND reviewer_id <> reviewee_id
        AND EXISTS (
            SELECT 1
              FROM requests r
              JOIN listings l ON l.id = r.listing_id
             WHERE r.id = reviews.request_id
               AND r.status = 'completed'
               AND (r.requester_id = auth.uid() OR l.owner_id = auth.uid())
        )
    );
CREATE POLICY "Users can update own reviews"
    ON reviews FOR UPDATE USING (auth.uid() = reviewer_id);
CREATE POLICY "Users can delete own reviews"
    ON reviews FOR DELETE USING (auth.uid() = reviewer_id);

-- complaints: private to the two parties involved (NOT public — a public
-- complaints feed would be defamation-by-default in a village app).
CREATE POLICY "Parties can view complaints"
    ON complaints FOR SELECT
    USING (auth.uid() = complainant_id OR auth.uid() = respondent_id);
CREATE POLICY "Participants can file complaints"
    ON complaints FOR INSERT
    WITH CHECK (
        auth.uid() = complainant_id
        AND complainant_id <> respondent_id
        AND EXISTS (
            SELECT 1
              FROM requests r
              JOIN listings l ON l.id = r.listing_id
             WHERE r.id = complaints.request_id
               AND (r.requester_id = auth.uid() OR l.owner_id = auth.uid())
        )
    );
CREATE POLICY "Complainants can update own complaints"
    ON complaints FOR UPDATE USING (auth.uid() = complainant_id);
CREATE POLICY "Complainants can delete own complaints"
    ON complaints FOR DELETE USING (auth.uid() = complainant_id);