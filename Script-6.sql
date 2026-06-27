CREATE TABLE IF NOT EXISTS users(
	user_id VARCHAR(36) PRIMARY KEY,
	first_name VARCHAR(200) NOT NULL,
    last_name VARCHAR(200) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS profiles(
	user_id varchar(36) PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE, --FOREIGN KEY
	profile_picture_url varchar(500),
	bio text,
	wallet decimal(10, 2) NOT NULL DEFAULT 0.00 CHECK (wallet >= 0)
);

CREATE TABLE IF NOT EXISTS games_creators(
	creator_id varchar(36) PRIMARY KEY,
	first_name VARCHAR(200) NOT NULL,
    last_name VARCHAR(200) NOT NULL,
    country varchar(100),
    email VARCHAR(200) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS games(
	game_id varchar(36) PRIMARY KEY,
	creator_id varchar(36) NOT NULL REFERENCES games_creators(creator_id) ON DELETE RESTRICT,
	game_title varchar(200) NOT NULL,
	description text,
	price decimal(10, 2) NOT NULL CHECK(price > 0),
	release_date date,
	rating NUMERIC(3, 2) DEFAULT 0.00	
);

CREATE TABLE IF NOT EXISTS genres(
	genre_id serial PRIMARY KEY,
	name varchar(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS game_genres(
	game_id varchar(36) NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
	genre_id int NOT NULL REFERENCES genres(genre_id) ON DELETE CASCADE,
	PRIMARY KEY (game_id, genre_id)
);

CREATE TABLE IF NOT EXISTS orders(
	order_id varchar(36) PRIMARY KEY,
	user_id varchar(36) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
	order_date timestamp DEFAULT current_timestamp,
	total_price decimal(10, 2) NOT NULL CHECK(total_price >= 0),
	status varchar(36) DEFAULT 'completed' CHECK (status IN('pending', 'completed', 'failed', 'refunded'))
);

CREATE TABLE IF NOT EXISTS order_items(
	order_id varchar(36) NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
	game_id varchar(36) NOT NULL REFERENCES games(game_id) ON DELETE RESTRICT,
	price_at_purchace decimal(10, 2) NOT NULL CHECK (price_at_purchace >= 0),
	PRIMARY KEY (order_id, game_id)
);

CREATE TABLE IF NOT EXISTS reviews(
	review_id varchar(36) PRIMARY KEY,
	user_id varchar(36) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
	game_id varchar(36) NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
	review_text text,
	is_recommended boolean NOT NULL ,
	created_at timestamp DEFAULT current_timestamp,
	CONSTRAINT unique_user_game_review UNIQUE (user_id, game_id)
);

CREATE TABLE IF NOT EXISTS user_achievements(
	user_id varchar(36) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
	game_id varchar(36) NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
	playtime_hours int DEFAULT 0 CHECK (playtime_hours >= 0),
	achievements_unlocked int DEFAULT 0 CHECK (achievements_unlocked >= 0),
	last_played timestamp DEFAULT current_timestamp,
	PRIMARY KEY (user_id, game_id)
);
















