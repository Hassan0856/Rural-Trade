-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE,
    village TEXT NOT NULL,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create listings table
CREATE TABLE listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('rent', 'lend', 'sell', 'exchange')),
    photo_url TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'completed')),
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create requests table
CREATE TABLE requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX idx_listings_owner_id ON listings(owner_id);
CREATE INDEX idx_listings_status ON listings(status);
CREATE INDEX idx_listings_type ON listings(type);
CREATE INDEX idx_listings_category ON listings(category);
CREATE INDEX idx_listings_location ON listings(location_lat, location_lng);
CREATE INDEX idx_requests_listing_id ON requests(listing_id);
CREATE INDEX idx_requests_requester_id ON requests(requester_id);
CREATE INDEX idx_requests_status ON requests(status);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
-- Users can read their own profile
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);

-- Users can insert their own profile (on signup)
CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- RLS Policies for listings table
-- Everyone can read all listings
CREATE POLICY "Anyone can view all listings"
    ON listings FOR SELECT
    USING (true);

-- Users can insert their own listings
CREATE POLICY "Users can create own listings"
    ON listings FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- Users can update their own listings
CREATE POLICY "Users can update own listings"
    ON listings FOR UPDATE
    USING (auth.uid() = owner_id);

-- Users can delete their own listings
CREATE POLICY "Users can delete own listings"
    ON listings FOR DELETE
    USING (auth.uid() = owner_id);

-- RLS Policies for requests table
-- Users can read requests where they are the requester or the listing owner
CREATE POLICY "Users can view own requests"
    ON requests FOR SELECT
    USING (
        auth.uid() = requester_id OR
        auth.uid() IN (
            SELECT owner_id FROM listings WHERE listings.id = requests.listing_id
        )
    );

-- Users can create requests for listings (as requester)
CREATE POLICY "Users can create requests"
    ON requests FOR INSERT
    WITH CHECK (auth.uid() = requester_id);

-- Requesters can update their own requests
CREATE POLICY "Requesters can update own requests"
    ON requests FOR UPDATE
    USING (auth.uid() = requester_id);

-- Listing owners can update requests on their listings
CREATE POLICY "Listing owners can update requests"
    ON requests FOR UPDATE
    USING (
        auth.uid() IN (
            SELECT owner_id FROM listings WHERE listings.id = requests.listing_id
        )
    );

-- Requesters can delete their own requests
CREATE POLICY "Requesters can delete own requests"
    ON requests FOR DELETE
    USING (auth.uid() = requester_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to auto-update updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_listings_updated_at
    BEFORE UPDATE ON listings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_requests_updated_at
    BEFORE UPDATE ON requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
