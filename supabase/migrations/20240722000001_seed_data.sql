-- Seed data for Village Exchange demo

-- Insert sample users
INSERT INTO users (id, name, phone, village, location_lat, location_lng) VALUES
('00000000-0000-0000-0000-000000000001', 'John Kamau', '+254712345678', 'Nairobi West', -1.286389, 36.817223),
('00000000-0000-0000-0000-000000000002', 'Mary Wanjiku', '+254712345679', 'Nairobi East', -1.292069, 36.821945),
('00000000-0000-0000-0000-000000000003', 'Peter Omondi', '+254712345680', 'Kibera', -1.315000, 36.800000),
('00000000-0000-0000-0000-000000000004', 'Grace Achieng', '+254712345681', 'Langata', -1.333333, 36.816667),
('00000000-0000-0000-0000-000000000005', 'David Kimani', '+254712345682', 'Westlands', -1.266667, 36.816667),
('00000000-0000-0000-0000-000000000006', 'Sarah Muthoni', '+254712345683', 'Karen', -1.316667, 36.800000),
('00000000-0000-0000-0000-000000000007', 'James Otieno', '+254712345684', 'Dagoretti', -1.300000, 36.783333),
('00000000-0000-0000-0000-000000000008', 'Elizabeth Njeri', '+254712345685', 'Kawangware', -1.283333, 36.783333)
ON CONFLICT (id) DO NOTHING;

-- Insert 25 sample listings
INSERT INTO listings (owner_id, title, description, category, type, photo_url, status, location_lat, location_lng) VALUES
-- Tractors (5 listings)
('00000000-0000-0000-0000-000000000001', 'Massey Ferguson 375 Tractor', 'Well-maintained 75HP tractor, good for plowing and harvesting. Available for daily or weekly rent.', 'tractor', 'rent', NULL, 'active', -1.286389, 36.817223),
('00000000-0000-0000-0000-000000000002', 'John Deere 5050 Tractor', '50HP tractor in excellent condition. Comes with plow attachment. Perfect for small to medium farms.', 'tractor', 'lend', NULL, 'active', -1.292069, 36.821945),
('00000000-0000-0000-0000-000000000003', 'Ford 5000 Tractor', 'Old but reliable tractor. Great for basic farming operations. Available for exchange with other farm equipment.', 'tractor', 'exchange', NULL, 'active', -1.315000, 36.800000),
('00000000-0000-0000-0000-000000000004', 'Kubota B2401 Tractor', 'Compact 24HP tractor, ideal for small farms and gardens. Includes mower deck.', 'tractor', 'rent', NULL, 'active', -1.333333, 36.816667),
('00000000-0000-0000-0000-000000000005', 'Mahindra 575 DI Tractor', '45HP tractor, fuel efficient and powerful. Available for sale or rent.', 'tractor', 'sell', NULL, 'active', -1.266667, 36.816667),

-- Water Pumps (5 listings)
('00000000-0000-0000-0000-000000000001', 'Diesel Water Pump 5HP', 'Heavy-duty diesel water pump for irrigation. Can pump up to 500L/min. Rent by the day.', 'water_pump', 'rent', NULL, 'active', -1.286389, 36.817223),
('00000000-0000-0000-0000-000000000006', 'Electric Water Pump 2HP', 'Electric water pump for domestic and small farm use. Energy efficient.', 'water_pump', 'sell', NULL, 'active', -1.316667, 36.800000),
('00000000-0000-0000-0000-000000000003', 'Solar Water Pump System', 'Complete solar water pump setup with panels. Perfect for off-grid irrigation.', 'water_pump', 'sell', NULL, 'active', -1.315000, 36.800000),
('00000000-0000-0000-0000-000000000007', 'Petrol Water Pump 3HP', 'Portable petrol water pump, easy to move around the farm. Good condition.', 'water_pump', 'lend', NULL, 'active', -1.300000, 36.783333),
('00000000-0000-0000-0000-000000000002', 'Submersible Borehole Pump', 'Deep well submersible pump, 100m capacity. Includes control panel.', 'water_pump', 'sell', NULL, 'active', -1.292069, 36.821945),

-- Generators (5 listings)
('00000000-0000-0000-0000-000000000004', 'Petrol Generator 5kVA', 'Reliable petrol generator for home and small business backup. Low hours.', 'generator', 'rent', NULL, 'active', -1.333333, 36.816667),
('00000000-0000-0000-0000-000000000005', 'Diesel Generator 10kVA', 'Industrial diesel generator, silent type. Suitable for farm operations.', 'generator', 'sell', NULL, 'active', -1.266667, 36.816667),
('00000000-0000-0000-0000-000000000008', 'Portable Inverter Generator 2kVA', 'Clean power generator for sensitive electronics. Very quiet operation.', 'generator', 'lend', NULL, 'active', -1.283333, 36.783333),
('00000000-0000-0000-0000-000000000001', 'Solar Generator System', 'Portable solar generator with battery storage. Eco-friendly power solution.', 'generator', 'sell', NULL, 'active', -1.286389, 36.817223),
('00000000-0000-0000-0000-000000000006', 'Dual Fuel Generator 8kVA', 'Runs on both petrol and LPG. Versatile power solution for farms.', 'generator', 'exchange', NULL, 'active', -1.316667, 36.800000),

-- Tools (5 listings)
('00000000-0000-0000-0000-000000000007', 'Complete Tool Kit Set', 'Professional tool kit with wrenches, hammers, screwdrivers, and more. 50+ pieces.', 'tools', 'lend', NULL, 'active', -1.300000, 36.783333),
('00000000-0000-0000-0000-000000000003', 'Welding Machine Set', 'Arc welding machine with helmet, gloves, and electrodes. 200A capacity.', 'tools', 'rent', NULL, 'active', -1.315000, 36.800000),
('00000000-0000-0000-0000-000000000002', 'Power Drill Kit', 'Cordless power drill with 2 batteries and charger. 18V.', 'tools', 'sell', NULL, 'active', -1.292069, 36.821945),
('00000000-0000-0000-0000-000000000008', 'Chainsaw 18 inch', 'Gas chainsaw for cutting wood and clearing land. Includes safety gear.', 'tools', 'lend', NULL, 'active', -1.283333, 36.783333),
('00000000-0000-0000-0000-000000000004', 'Angle Grinder Set', 'Angle grinder with cutting and grinding discs. 1000W.', 'tools', 'sell', NULL, 'active', -1.333333, 36.816667),

-- Produce (5 listings)
('00000000-0000-0000-0000-000000000005', 'Fresh Tomatoes - 100kg', 'Ripe tomatoes from local farm. Organic, no pesticides. Available for immediate sale.', 'produce', 'sell', NULL, 'active', -1.266667, 36.816667),
('00000000-0000-0000-0000-000000000006', 'Maize - 50 bags', 'High-quality maize harvest, dried and ready for storage or milling.', 'produce', 'sell', NULL, 'active', -1.316667, 36.800000),
('00000000-0000-0000-0000-000000000001', 'Organic Vegetables Box', 'Mixed seasonal vegetables (kale, spinach, carrots,). Weekly subscription available.', 'produce', 'sell', NULL, 'active', -1.286389, 36.817223),
('00000000-0000-0000-0000-000000000007', 'Fresh Eggs - 500 trays', 'Free-range chicken eggs. Large size, excellent quality.', 'produce', 'sell', NULL, 'active', -1.300000, 36.783333),
('00000000-0000-0000-0000-000000000008', 'Milk - 200 liters daily', 'Fresh cow milk available daily. Can deliver within 5km radius.', 'produce', 'sell', NULL, 'active', -1.283333, 36.783333)
ON CONFLICT DO NOTHING;

-- Get listing IDs for requests
DO $$
DECLARE
    listing_ids UUID[];
    user_ids UUID[];
BEGIN
    SELECT ARRAY_AGG(id) INTO listing_ids FROM listings LIMIT 10;
    SELECT ARRAY_AGG(id) INTO user_ids FROM users WHERE id NOT IN (
        SELECT owner_id FROM listings LIMIT 5
    ) LIMIT 5;
    
    -- Insert 10 sample requests
    INSERT INTO requests (listing_id, requester_id, status) VALUES
        (listing_ids[1], user_ids[1], 'pending'),
        (listing_ids[2], user_ids[2], 'accepted'),
        (listing_ids[3], user_ids[3], 'completed'),
        (listing_ids[4], user_ids[1], 'pending'),
        (listing_ids[5], user_ids[4], 'rejected'),
        (listing_ids[6], user_ids[2], 'pending'),
        (listing_ids[7], user_ids[5], 'accepted'),
        (listing_ids[8], user_ids[3], 'pending'),
        (listing_ids[9], user_ids[1], 'completed'),
        (listing_ids[10], user_ids[4], 'pending')
    ON CONFLICT DO NOTHING;
END $$;

-- Insert sample reviews for completed requests
DO $$
DECLARE
    request_ids UUID[];
    user_ids UUID[];
BEGIN
    SELECT ARRAY_AGG(id) INTO request_ids FROM requests WHERE status = 'completed' LIMIT 5;
    SELECT ARRAY_AGG(id) INTO user_ids FROM users LIMIT 8;
    
    -- Insert sample reviews
    INSERT INTO reviews (request_id, reviewer_id, reviewee_id, rating, comment) VALUES
        (request_ids[1], user_ids[3], user_ids[1], 5, 'Excellent service! The tractor was in perfect condition and very helpful for my harvest.'),
        (request_ids[2], user_ids[1], user_ids[4], 4, 'Good experience overall. The generator worked well, though delivery was slightly delayed.'),
        (request_ids[1], user_ids[1], user_ids[3], 5, 'Very reliable requester. On time and took good care of the equipment.'),
        (request_ids[2], user_ids[4], user_ids[1], 4, 'Great communication throughout the process. Would trade again.'),
        (request_ids[3], user_ids[2], user_ids[5], 3, 'Decent experience. The tools were functional but could have been cleaner.')
    ON CONFLICT DO NOTHING;
END $$;

-- Insert sample complaints
DO $$
DECLARE
    request_ids UUID[];
    user_ids UUID[];
BEGIN
    SELECT ARRAY_AGG(id) INTO request_ids FROM requests WHERE status = 'completed' LIMIT 5;
    SELECT ARRAY_AGG(id) INTO user_ids FROM users LIMIT 8;
    
    -- Insert sample complaints
    INSERT INTO complaints (request_id, reporter_id, category, description, status) VALUES
        (request_ids[1], user_ids[3], 'damaged', 'The water pump had a minor leak that was not mentioned. Still usable but needs repair.', 'resolved'),
        (request_ids[2], user_ids[1], 'no-show', 'The other party did not show up at the agreed time. Had to reschedule twice.', 'investigating')
    ON CONFLICT DO NOTHING;
END $$;
