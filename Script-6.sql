-- 1. users: stores user account/user data
-- Relationships: 1:1 with profiles, 1:Many with orders, reviews, and user_achievements
CREATE TABLE IF NOT EXISTS users(
	user_id VARCHAR(36) PRIMARY KEY,
	first_name VARCHAR(200) NOT NULL,
    last_name VARCHAR(200) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 2. profiles: Stores user profile details and wallet balance
-- Relationships: 1:1 with users
CREATE TABLE IF NOT EXISTS profiles(
	user_id varchar(36) PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE, --FOREIGN KEY
	profile_picture_url varchar(500),
	bio text,
	wallet decimal(10, 2) NOT NULL DEFAULT 0.00 CHECK (wallet >= 0)
);


-- 3. games_creators: Stores game developers data
-- Relationships: 1:Many with games
CREATE TABLE IF NOT EXISTS games_creators(
	creator_id varchar(36) PRIMARY KEY,
	first_name VARCHAR(200) NOT NULL,
    last_name VARCHAR(200) NOT NULL,
    country varchar(100),
    email VARCHAR(200) NOT NULL UNIQUE
);


-- 4. games: Stores the main catalog of games and prices
-- Relationships: Many:1 with games_creators, Many:Many with genres and orders
CREATE TABLE IF NOT EXISTS games(
	game_id varchar(36) PRIMARY KEY,
	creator_id varchar(36) NOT NULL REFERENCES games_creators(creator_id) ON DELETE RESTRICT,
	game_title varchar(200) NOT NULL,
	description text,
	price decimal(10, 2) NOT NULL CHECK(price > 0),
	release_date date,
	rating NUMERIC(3, 2) DEFAULT 0.00	
);


-- 5. video game genres
-- Relationships: Many:Many with games via game_genres
CREATE TABLE IF NOT EXISTS genres(
	genre_id serial PRIMARY KEY,
	name varchar(50) NOT NULL UNIQUE
);


-- 6. Junction table handling the Many:Many relationship between games and genres
CREATE TABLE IF NOT EXISTS game_genres(
	game_id varchar(36) NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
	genre_id int NOT NULL REFERENCES genres(genre_id) ON DELETE CASCADE,
	PRIMARY KEY (game_id, genre_id)
);


-- 7. Stores transaction/order data
-- Relationships: Many:1 with users, Many:Many with games via order_items
CREATE TABLE IF NOT EXISTS orders(
	order_id varchar(36) PRIMARY KEY,
	user_id varchar(36) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
	order_date timestamp DEFAULT current_timestamp,
	total_price decimal(10, 2) NOT NULL CHECK(total_price >= 0),
	status varchar(36) DEFAULT 'completed' CHECK (status IN('pending', 'completed', 'failed', 'refunded'))
);


-- 8. Junction table handling the Many:Many relationship between orders and games
CREATE TABLE IF NOT EXISTS order_items(
	order_id varchar(36) NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
	game_id varchar(36) NOT NULL REFERENCES games(game_id) ON DELETE RESTRICT,
	price_at_purchace decimal(10, 2) NOT NULL CHECK (price_at_purchace >= 0),
	PRIMARY KEY (order_id, game_id)
);


-- 9. Stores user feedback
-- Relationships: table with unique constraint (1 user : 1 game review)
CREATE TABLE IF NOT EXISTS reviews(
	review_id varchar(36) PRIMARY KEY,
	user_id varchar(36) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
	game_id varchar(36) NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
	review_text text,
	is_recommended boolean NOT NULL ,
	created_at timestamp DEFAULT current_timestamp,
	CONSTRAINT unique_user_game_review UNIQUE (user_id, game_id)
);


--10. Tracks playtime hours, number of achievments
-- Relationships: Junction table linking users and games (Many:Many)
CREATE TABLE IF NOT EXISTS user_achievements(
	user_id varchar(36) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
	game_id varchar(36) NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
	playtime_hours int DEFAULT 0 CHECK (playtime_hours >= 0),
	achievements_unlocked int DEFAULT 0 CHECK (achievements_unlocked >= 0),
	last_played timestamp DEFAULT current_timestamp,
	PRIMARY KEY (user_id, game_id)
);


--SQL query top 5 most expensive purchases
--where price > $45 and ststus = completed

EXPLAIN ANALYZE
SELECT 
    g.game_title,
    o.order_date,
    oi.price_at_purchace
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN games g ON oi.game_id = g.game_id
WHERE o.status = 'completed' AND oi.price_at_purchace > 45.00
ORDER BY oi.price_at_purchace DESC
LIMIT 5;

--Data base will be filtering prices (price_at_purchace > 45.00) through whole table (489 822 rows) using Seq Scan.
--This takes so much time. That is why I created inde on order_items(price_at_purchace).

CREATE INDEX IF NOT EXISTS idx_order_items_price ON order_items(price_at_purchace);








