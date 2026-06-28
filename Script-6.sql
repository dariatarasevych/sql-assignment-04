------------------------------------------
-- Basic requirements
-- there is relationships description too
------------------------------------------


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


------------------------------------------
-- Additional points 
------------------------------------------

-- 1. Create at least 3 different users for different purposes

CREATE ROLE administrator LOGIN PASSWORD 'Admin123';
CREATE ROLE analyst LOGIN PASSWORD 'Analyst123';
CREATE ROLE developer LOGIN PASSWORD 'Developer123';

GRANT CONNECT ON DATABASE gaming_platform TO administrator, analyst, developer; --everyone can connect to this database
GRANT USAGE ON SCHEMA public TO administrator, analyst, developer; --use schema in this database

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO administrator; -- admin can do everything
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analyst; -- analyst can only select something to analyse
GRANT SELECT, INSERT, UPDATE ON games, games_creators, genres, game_genres TO developer; -- developer has access to games, games_creators, genres, game_genres 
																						 -- to add/update/select their game info


-- 2. Create at least 1 view
-- This view shows catalog that displays essential game details like title, price, release date, and rating
-- It automatically combines the creator's full name and aggregates all of the game's genres into a single, comma-separated list (string_agg() - підказав AI)

CREATE OR REPLACE VIEW gaming_platform_view AS
SELECT
	g.game_id,
	g.game_title,
	g.price,
	g.release_date,
	g.rating,
	(gc.first_name || ' ' || gc.last_name) AS developer_name,
	string_agg(gen.name, ', ') AS game_genres
FROM games g
JOIN games_creators gc ON g.creator_id = gc.creator_id
LEFT JOIN game_genres gg ON g.game_id = gg.game_id
LEFT JOIN genres gen ON gg.genre_id = gen.genre_id
GROUP BY g.game_id, g.game_title, g.price, g.release_date, g.rating, gc.first_name, gc.last_name;


SELECT * FROM gaming_platform_view LIMIT 100;
	

-- 3. Create at least 1 stored procedure
-- THis procedure add money to users wallet, you can see changes in table 'profiles'

CREATE PROCEDURE add_money_to_wallet(
	p_user_id varchar(36),
	p_sum_to_add decimal(10, 2)
)
AS $$
BEGIN 
	if p_sum_to_add <= 0 then
		raise exception 'Sum cannot be less then 0';
	end if;
	
	update profiles
	set wallet = wallet + p_sum_to_add
	where user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

CALL add_money_to_wallet('a6a4a148-b938-440f-8cd6-f01bd55de392', 50); --$11.49

SELECT * FROM profiles WHERE user_id = 'a6a4a148-b938-440f-8cd6-f01bd55de392'; --$61.49


-- 4. Create at least 1 trigger or function 
--This trigger executes immediately after a row is added to order_items (user made a purchase), 
--automatically inserting a new record into user_achievements with 0 hours and 0 achievements for this game

CREATE OR REPLACE FUNCTION trigger_update_achievments()
RETURNS TRIGGER AS $$
DECLARE 
	v_user_id varchar(36);
BEGIN
	--Через order_id дізнається user_id, бо в order_items немає user_id
	select user_id into v_user_id
	from orders 
	where order_id = new.order_id;

	insert into user_achievements(user_id, game_id, playtime_hours, achievements_unlocked)
	values(v_user_id, game_id, 0, 0);
	return null;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER after_game_purchase
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION trigger_update_achievments();







