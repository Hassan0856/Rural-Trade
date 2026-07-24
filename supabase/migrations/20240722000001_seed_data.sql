-- =====================================================================
-- VILLAGE EXCHANGE — SEED DATA
-- Replaces FILE 2. Run AFTER 01_schema.sql.
--
-- All IDs are hardcoded and deterministic, so there are no ARRAY_AGG /
-- LIMIT tricks that can silently produce NULLs. Re-runnable.
--
-- Locations are Telangana villages around Hyderabad, matching the
-- Telugu/Hindi voice-input story in the pitch.
-- =====================================================================

-- ---------- Users ----------
INSERT INTO users (id, name, phone, village, location_lat, location_lng) VALUES
('00000000-0000-0000-0000-000000000001','Ravi Kumar',    '+919812345001','Shamirpet',      17.63000000, 78.56000000),
('00000000-0000-0000-0000-000000000002','Lakshmi Devi',  '+919812345002','Medchal',        17.63000000, 78.48000000),
('00000000-0000-0000-0000-000000000003','Venkat Reddy',  '+919812345003','Ghatkesar',      17.45000000, 78.68000000),
('00000000-0000-0000-0000-000000000004','Padma Rani',    '+919812345004','Chevella',       17.31000000, 78.14000000),
('00000000-0000-0000-0000-000000000005','Suresh Goud',   '+919812345005','Shankarpally',   17.43000000, 78.17000000),
('00000000-0000-0000-0000-000000000006','Anitha Rao',    '+919812345006','Vikarabad',      17.34000000, 77.90000000),
('00000000-0000-0000-0000-000000000007','Mallesh Yadav', '+919812345007','Moinabad',       17.32000000, 78.22000000),
('00000000-0000-0000-0000-000000000008','Sunitha Bai',   '+919812345008','Ibrahimpatnam',  17.25000000, 78.64000000)
ON CONFLICT (id) DO NOTHING;


-- ---------- Listings (25) ----------
INSERT INTO listings (id, owner_id, title, description, category, type, status, location_lat, location_lng) VALUES
-- Tractors
('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','Massey Ferguson 375 Tractor','Well-maintained 75HP tractor, good for plowing and harvesting. Daily or weekly rent.','tractor','rent','active',17.63000000,78.56000000),
('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002','John Deere 5050 Tractor','50HP tractor in excellent condition. Comes with plough attachment.','tractor','lend','active',17.63000000,78.48000000),
('10000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000003','Ford 5000 Tractor','Old but reliable. Available for exchange against other farm equipment.','tractor','exchange','active',17.45000000,78.68000000),
('10000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000004','Kubota B2401 Tractor','Compact 24HP tractor, ideal for small plots. Includes mower deck.','tractor','rent','active',17.31000000,78.14000000),
('10000000-0000-0000-0000-000000000005','00000000-0000-0000-0000-000000000005','Mahindra 575 DI Tractor','45HP, fuel efficient and powerful. Available for sale.','tractor','sell','active',17.43000000,78.17000000),
-- Water pumps
('10000000-0000-0000-0000-000000000006','00000000-0000-0000-0000-000000000001','Diesel Water Pump 5HP','Heavy-duty irrigation pump, up to 500L/min. Rent by the day.','water_pump','rent','active',17.63000000,78.56000000),
('10000000-0000-0000-0000-000000000007','00000000-0000-0000-0000-000000000006','Electric Water Pump 2HP','For domestic and small farm use. Energy efficient.','water_pump','sell','active',17.34000000,77.90000000),
('10000000-0000-0000-0000-000000000008','00000000-0000-0000-0000-000000000003','Solar Water Pump System','Complete solar pump setup with panels. Off-grid irrigation.','water_pump','sell','active',17.45000000,78.68000000),
('10000000-0000-0000-0000-000000000009','00000000-0000-0000-0000-000000000007','Petrol Water Pump 3HP','Portable, easy to move around the field. Good condition.','water_pump','lend','active',17.32000000,78.22000000),
('10000000-0000-0000-0000-000000000010','00000000-0000-0000-0000-000000000002','Submersible Borehole Pump','Deep borewell pump, 100m capacity. Includes control panel.','water_pump','sell','active',17.63000000,78.48000000),
-- Generators
('10000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000004','Petrol Generator 5kVA','Reliable backup power for home and small business. Low hours.','generator','rent','active',17.31000000,78.14000000),
('10000000-0000-0000-0000-000000000012','00000000-0000-0000-0000-000000000005','Diesel Generator 10kVA','Silent-type industrial generator, suitable for farm operations.','generator','sell','active',17.43000000,78.17000000),
('10000000-0000-0000-0000-000000000013','00000000-0000-0000-0000-000000000008','Portable Inverter Generator 2kVA','Clean power for sensitive electronics. Very quiet.','generator','lend','active',17.25000000,78.64000000),
('10000000-0000-0000-0000-000000000014','00000000-0000-0000-0000-000000000001','Solar Generator System','Portable solar generator with battery storage.','generator','sell','active',17.63000000,78.56000000),
('10000000-0000-0000-0000-000000000015','00000000-0000-0000-0000-000000000006','Dual Fuel Generator 8kVA','Runs on both petrol and LPG. Versatile farm power.','generator','exchange','active',17.34000000,77.90000000),
-- Tools
('10000000-0000-0000-0000-000000000016','00000000-0000-0000-0000-000000000007','Complete Tool Kit Set','50+ piece kit: spanners, hammers, screwdrivers and more.','tools','lend','active',17.32000000,78.22000000),
('10000000-0000-0000-0000-000000000017','00000000-0000-0000-0000-000000000003','Welding Machine Set','Arc welder with helmet, gloves and electrodes. 200A.','tools','rent','active',17.45000000,78.68000000),
('10000000-0000-0000-0000-000000000018','00000000-0000-0000-0000-000000000002','Power Drill Kit','Cordless drill with 2 batteries and charger. 18V.','tools','sell','active',17.63000000,78.48000000),
('10000000-0000-0000-0000-000000000019','00000000-0000-0000-0000-000000000008','Chainsaw 18 inch','Petrol chainsaw for cutting wood and clearing land. Safety gear included.','tools','lend','active',17.25000000,78.64000000),
('10000000-0000-0000-0000-000000000020','00000000-0000-0000-0000-000000000004','Angle Grinder Set','Grinder with cutting and grinding discs. 1000W.','tools','sell','active',17.31000000,78.14000000),
-- Produce
('10000000-0000-0000-0000-000000000021','00000000-0000-0000-0000-000000000005','Fresh Tomatoes - 100kg','Ripe tomatoes from local farm. No pesticides. Immediate sale.','produce','sell','active',17.43000000,78.17000000),
('10000000-0000-0000-0000-000000000022','00000000-0000-0000-0000-000000000006','Paddy - 50 bags','Good quality paddy, dried and ready for storage or milling.','produce','sell','active',17.34000000,77.90000000),
('10000000-0000-0000-0000-000000000023','00000000-0000-0000-0000-000000000001','Mixed Vegetables Box','Seasonal vegetables (brinjal, spinach, carrots). Weekly supply available.','produce','sell','active',17.63000000,78.56000000),
('10000000-0000-0000-0000-000000000024','00000000-0000-0000-0000-000000000007','Fresh Eggs - 500 trays','Free-range eggs, large size, excellent quality.','produce','sell','active',17.32000000,78.22000000),
('10000000-0000-0000-0000-000000000025','00000000-0000-0000-0000-000000000008','Buffalo Milk - 200 litres daily','Fresh milk available daily. Delivery within 5km.','produce','sell','active',17.25000000,78.64000000)
ON CONFLICT (id) DO NOTHING;


-- ---------- Requests (10) ----------
-- Requester is never the listing owner.
INSERT INTO requests (id, listing_id, requester_id, status) VALUES
('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000003','completed'),
('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000001','completed'),
('20000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000017','00000000-0000-0000-0000-000000000002','completed'),
('20000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000006','00000000-0000-0000-0000-000000000007','completed'),
('20000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000005','accepted'),
('20000000-0000-0000-0000-000000000006','10000000-0000-0000-0000-000000000013','00000000-0000-0000-0000-000000000004','accepted'),
('20000000-0000-0000-0000-000000000007','10000000-0000-0000-0000-000000000021','00000000-0000-0000-0000-000000000002','pending'),
('20000000-0000-0000-0000-000000000008','10000000-0000-0000-0000-000000000009','00000000-0000-0000-0000-000000000006','pending'),
('20000000-0000-0000-0000-000000000009','10000000-0000-0000-0000-000000000019','00000000-0000-0000-0000-000000000003','pending'),
('20000000-0000-0000-0000-000000000010','10000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000001','rejected')
ON CONFLICT (id) DO NOTHING;


-- ---------- Reviews (only on completed requests) ----------
-- Each row satisfies UNIQUE(request_id, reviewer_id) and reviewer <> reviewee.
INSERT INTO reviews (request_id, reviewer_id, reviewee_id, rating, comment) VALUES
-- Request 1: owner Ravi (u1) <-> requester Venkat (u3)
('20000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001',5,'Tractor was in perfect condition and a big help during harvest.'),
('20000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000003',4,'Returned on time and took reasonable care of the machine.'),
-- Request 2: owner Padma (u4) <-> requester Ravi (u1)
('20000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000004',4,'Generator worked well, though pickup was slightly delayed.'),
('20000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000001',4,'Good communication throughout. Would trade again.'),
-- Request 3: owner Venkat (u3) <-> requester Lakshmi (u2)
('20000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000003',3,'Welding set was functional but could have been cleaner.'),
-- Request 4: owner Ravi (u1) <-> requester Mallesh (u7)
('20000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000007',2,'Pump was returned late and with a damaged seal.')
ON CONFLICT (request_id, reviewer_id) DO NOTHING;


-- ---------- Complaints ----------
INSERT INTO complaints (request_id, complainant_id, respondent_id, category, description, status) VALUES
('20000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000007','damaged','Water pump came back with a leaking seal that needs repair.','resolved'),
('20000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000003','no-show','Did not turn up at the agreed time. Had to reschedule twice.','investigating')
ON CONFLICT DO NOTHING;


-- ---------- Verify: badge spread for the demo ----------
-- Expected after the triggers fire:
--   Ravi Kumar     ~4.65  Verified
--   Padma Rani     ~4.30  Verified
--   Venkat Reddy   ~3.80  Member
--   Mallesh Yadav  ~2.75  Flagged
--   everyone else   5.00  New trader
SELECT name, village, ROUND(trust_score::numeric, 2) AS trust_score, badge_level
FROM users
ORDER BY trust_score DESC;