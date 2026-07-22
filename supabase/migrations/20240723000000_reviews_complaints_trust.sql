-- Add trust_score and badge_level columns to users table
ALTER TABLE users 
ADD COLUMN trust_score FLOAT DEFAULT 5.0,
ADD COLUMN badge_level TEXT DEFAULT 'Newcomer';

-- Create reviews table
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reviewee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    request_id UUID NOT NULL REFERENCES requests(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT reviewer_not_reviewee CHECK (reviewer_id != reviewee_id),
    CONSTRAINT unique_review_per_request UNIQUE (request_id, reviewer_id)
);

-- Create complaints table
CREATE TABLE complaints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL REFERENCES requests(id) ON DELETE CASCADE,
    complainant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    respondent_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN ('damaged', 'stolen', 'no-show', 'other')),
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT complainant_not_respondent CHECK (complainant_id != respondent_id)
);

-- Create indexes for reviews and complaints
CREATE INDEX idx_reviews_reviewer_id ON reviews(reviewer_id);
CREATE INDEX idx_reviews_reviewee_id ON reviews(reviewee_id);
CREATE INDEX idx_reviews_request_id ON reviews(request_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_complaints_request_id ON complaints(request_id);
CREATE INDEX idx_complaints_complainant_id ON complaints(complainant_id);
CREATE INDEX idx_complaints_respondent_id ON complaints(respondent_id);
CREATE INDEX idx_complaints_status ON complaints(status);

-- Enable Row Level Security for new tables
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;

-- RLS Policies for reviews table
-- Everyone can view reviews
CREATE POLICY "Anyone can view reviews"
    ON reviews FOR SELECT
    USING (true);

-- Users can create reviews only for completed requests they participated in
CREATE POLICY "Users can create reviews for completed requests"
    ON reviews FOR INSERT
    WITH CHECK (
        auth.uid() = reviewer_id AND
        EXISTS (
            SELECT 1 FROM requests 
            WHERE requests.id = request_id 
            AND requests.status = 'completed'
            AND (
                requests.requester_id = auth.uid() OR
                requests.listing_id IN (
                    SELECT id FROM listings WHERE owner_id = auth.uid()
                )
            )
        )
    );

-- Users can update their own reviews
CREATE POLICY "Users can update own reviews"
    ON reviews FOR UPDATE
    USING (auth.uid() = reviewer_id);

-- Users can delete their own reviews
CREATE POLICY "Users can delete own reviews"
    ON reviews FOR DELETE
    USING (auth.uid() = reviewer_id);

-- RLS Policies for complaints table
-- Everyone can view complaints
CREATE POLICY "Anyone can view complaints"
    ON complaints FOR SELECT
    USING (true);

-- Users can create complaints only for requests they participated in
CREATE POLICY "Users can create complaints for participated requests"
    ON complaints FOR INSERT
    WITH CHECK (
        auth.uid() = complainant_id AND
        EXISTS (
            SELECT 1 FROM requests 
            WHERE requests.id = request_id 
            AND (
                requests.requester_id = auth.uid() OR
                requests.listing_id IN (
                    SELECT id FROM listings WHERE owner_id = auth.uid()
                )
            )
        )
    );

-- Complainants can update their own complaints
CREATE POLICY "Complainants can update own complaints"
    ON complaints FOR UPDATE
    USING (auth.uid() = complainant_id);

-- Complainants can delete their own complaints
CREATE POLICY "Complainants can delete own complaints"
    ON complaints FOR DELETE
    USING (auth.uid() = complainant_id);

-- Function to recalculate trust_score and badge_level for a user
CREATE OR REPLACE FUNCTION recalculate_user_trust(user_id UUID)
RETURNS VOID AS $$
DECLARE
    avg_rating FLOAT;
    complaint_count INTEGER;
    new_trust_score FLOAT;
    new_badge_level TEXT;
BEGIN
    -- Calculate average rating received
    SELECT COALESCE(AVG(rating), 5.0) INTO avg_rating
    FROM reviews
    WHERE reviewee_id = user_id;

    -- Count complaints against the user
    SELECT COUNT(*) INTO complaint_count
    FROM complaints
    WHERE respondent_id = user_id AND status != 'dismissed';

    -- Calculate trust score: starts at 5.0, decreases by 0.5 per complaint, based on avg rating
    new_trust_score := (avg_rating * 0.7) + (5.0 - (complaint_count * 0.5)) * 0.3;
    
    -- Ensure trust score stays between 0 and 5
    new_trust_score := GREATEST(LEAST(new_trust_score, 5.0), 0.0);

    -- Determine badge level based on trust score
    IF new_trust_score >= 4.5 THEN
        new_badge_level := 'Trusted Villager';
    ELSIF new_trust_score >= 4.0 THEN
        new_badge_level := 'Reliable';
    ELSIF new_trust_score >= 3.5 THEN
        new_badge_level := 'Established';
    ELSIF new_trust_score >= 3.0 THEN
        new_badge_level := 'Member';
    ELSIF new_trust_score >= 2.0 THEN
        new_badge_level := 'Newcomer';
    ELSE
        new_badge_level := 'Caution';
    END IF;

    -- Update the user's trust score and badge level
    UPDATE users
    SET trust_score = new_trust_score,
        badge_level = new_badge_level
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger to recalculate trust score when a review is inserted
CREATE TRIGGER recalculate_trust_on_review_insert
    AFTER INSERT ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION recalculate_user_trust(NEW.reviewee_id);

-- Trigger to recalculate trust score when a review is updated
CREATE TRIGGER recalculate_trust_on_review_update
    AFTER UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION recalculate_user_trust(NEW.reviewee_id);

-- Trigger to recalculate trust score when a review is deleted
CREATE TRIGGER recalculate_trust_on_review_delete
    AFTER DELETE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION recalculate_user_trust(OLD.reviewee_id);

-- Trigger to recalculate trust score when a complaint is inserted
CREATE TRIGGER recalculate_trust_on_complaint_insert
    AFTER INSERT ON complaints
    FOR EACH ROW
    EXECUTE FUNCTION recalculate_user_trust(NEW.respondent_id);

-- Trigger to recalculate trust score when a complaint is updated
CREATE TRIGGER recalculate_trust_on_complaint_update
    AFTER UPDATE ON complaints
    FOR EACH ROW
    WHEN (OLD.status != NEW.status)
    EXECUTE FUNCTION recalculate_user_trust(NEW.respondent_id);

-- Trigger to recalculate trust score when a complaint is deleted
CREATE TRIGGER recalculate_trust_on_complaint_delete
    AFTER DELETE ON complaints
    FOR EACH ROW
    EXECUTE FUNCTION recalculate_user_trust(OLD.respondent_id);

-- Add updated_at trigger for reviews
CREATE TRIGGER update_reviews_updated_at
    BEFORE UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add updated_at trigger for complaints
CREATE TRIGGER update_complaints_updated_at
    BEFORE UPDATE ON complaints
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
