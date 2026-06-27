import uuid
import random
from datetime import datetime, timedelta
import psycopg2
from psycopg2 import Error
from faker import Faker


HOST = 'localhost'
USER = 'postgres'
PASSWORD = 'Sdx12411'
DATABASE = 'gaming_platform'
PORT = '5432'

fake = Faker()


def create_connection():
    """Create a PostgreSQL database connection."""
    try:
        connection = psycopg2.connect(
            host=HOST,
            port=PORT,
            user=USER,
            password=PASSWORD,
            dbname=DATABASE,
        )
        print("Connection to PostgreSQL DB successful")
        return connection
    except Error as e:
        print(f"The error '{e}' occurred")
        return None


def insert_data():
    connection = create_connection()
    if connection is None:
        return

    # Відкриваємо єдиний cursor для ефективного заповнення великої кількості даних
    cursor = connection.cursor()

    try:
        # 1. ГЕНЕРАЦІЯ ЖАНРІВ (Genres)
        print("Inserting genres...")
        genres_query = """
        INSERT INTO genres (name)
        VALUES (%s)
        ON CONFLICT (name) DO NOTHING
        RETURNING genre_id
        """
        genres_list = ['Action', 'RPG', 'Shooter', 'Strategy', 'Indie', 'Adventure', 'Simulation', 'Horror']
        genre_ids = []

        for name in genres_list:
            cursor.execute(genres_query, (name,))
            # Зберігаємо ID згенерованих жанрів

        connection.commit()
        cursor.execute("SELECT genre_id FROM genres;")
        genre_ids = [row[0] for row in cursor.fetchall()]

        # 2. ГЕНЕРАЦІЯ КОРИСТУВАЧІВ ТА ПРОФІЛІВ (Users & Profiles)
        print("Inserting users and profiles...")
        users_query = """
        INSERT INTO users (user_id, first_name, last_name, email, password)
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (user_id) DO NOTHING
        """
        profiles_query = """
        INSERT INTO profiles (user_id, profile_picture_url, bio, wallet)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (user_id) DO NOTHING
        """

        user_ids = [str(uuid.uuid4()) for _ in range(1000)]  # Створимо 1000 геймерів

        for uid in user_ids:
            f_name = fake.first_name()
            l_name = fake.last_name()
            email = f"{f_name.lower()}.{l_name.lower()}.{random.randint(1, 999)}@{fake.free_email_domain()}"
            password = fake.password(length=10)

            # Вставка користувача
            cursor.execute(users_query, (uid, f_name, l_name, email, password))

            # Вставка 1:1 профілю
            bio = fake.sentence()
            wallet = round(random.uniform(0.0, 100.0), 2)
            cursor.execute(profiles_query, (uid, None, bio, wallet))
        connection.commit()

        # 3. ГЕНЕРАЦІЯ РОЗРОБНИКІВ (Games Creators)
        print("Inserting games creators...")
        creators_query = """
        INSERT INTO games_creators (creator_id, first_name, last_name, country, email)
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (creator_id) DO NOTHING
        """
        creator_ids = [str(uuid.uuid4()) for _ in range(100)]  # 100 розробників/студій

        for cid in creator_ids:
            cf_name = fake.first_name()
            cl_name = fake.last_name()
            c_email = f"contact@{cf_name.lower()}{cl_name.lower()}.com"
            cursor.execute(creators_query, (cid, cf_name, cl_name, fake.country(), c_email))
        connection.commit()

        # 4. ГЕНЕРАЦІЯ ІГОР ТА ЇХ ЖАНРІВ (Games & Game Genres)
        print("Inserting games and linking genres...")
        games_query = """
        INSERT INTO games (game_id, creator_id, game_title, description, price, release_date, rating)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (game_id) DO NOTHING
        """
        game_genres_query = """
        INSERT INTO game_genres (game_id, genre_id)
        VALUES (%s, %s)
        ON CONFLICT (game_id, genre_id) DO NOTHING
        """
        game_ids = [str(uuid.uuid4()) for _ in range(500)]  # 500 ігор у каталозі магазину

        for gid in game_ids:
            title = fake.catch_phrase()
            desc = fake.paragraph(nb_sentences=2)
            price = round(random.uniform(4.99, 59.99), 2)
            release_date = fake.date_between(start_date='-5y', end_date='today')
            rating = round(random.uniform(1.0, 5.0), 2)
            cid = random.choice(creator_ids)

            # Додаємо саму гру
            cursor.execute(games_query, (gid, cid, title, desc, price, release_date, rating))

            # Прив'язуємо Many:Many випадкові жанри (1 або 2 жанри для кожної гри)
            chosen_genres = random.sample(genre_ids, random.randint(1, 2))
            for g_id in chosen_genres:
                cursor.execute(game_genres_query, (gid, g_id))
        connection.commit()

        # 5. ГЕНЕРАЦІЯ ЗАМОВЛЕНЬ ТА ЕЛЕМЕНТІВ (Orders & Order Items)
        # ГЕНЕРУЄМО 500 000+ РЯДКІВ ДЛЯ ОПТИМІЗАЦІЇ ІНДЕКСІВ
        print("Generating 500,000+ order items (this may take 1-2 minutes)...")
        orders_query = """
        INSERT INTO orders (order_id, user_id, order_date, total_price, status)
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (order_id) DO NOTHING
        """
        order_items_query = """
        INSERT INTO order_items (order_id, game_id, price_at_purchace)
        VALUES (%s, %s, %s)
        ON CONFLICT (order_id, game_id) DO NOTHING
        """

        num_orders = 140000  # Кожне замовлення містить 3-4 гри, разом вийде понад 500к рядків

        for i in range(num_orders):
            o_id = str(uuid.uuid4())
            u_id = random.choice(user_ids)
            o_date = fake.date_time_between(start_date='-3y', end_date='now')
            status = random.choice(['completed', 'completed', 'completed', 'refunded', 'failed'])

            # Вибираємо випадкові ігри для кошика замовлення
            games_in_order = random.sample(game_ids, random.randint(3, 4))

            # Рахуємо total_price для чека замовлення
            total_price = 0
            order_items_data = []

            for g_id in games_in_order:
                price_at_purchase = round(random.uniform(4.99, 59.99), 2)
                total_price += price_at_purchase
                order_items_data.append((g_id, price_at_purchase))

            # Спершу створюємо головний чек в orders
            cursor.execute(orders_query, (o_id, u_id, o_date, round(total_price, 2), status))

            # Потім наповнюємо його позиціями в order_items
            for g_id, item_price in order_items_data:
                cursor.execute(order_items_query, (o_id, g_id, item_price))

            # Щоб не перевантажувати пам'ять, зберігаємо дані кожні 20 000 замовлень
            if i % 20000 == 0 and i > 0:
                connection.commit()
                print(f"Progress: inserted {i} orders...")

        connection.commit()

        # 6. ГЕНЕРАЦІЯ ВІДГУКІВ ТА ІГРОВОГО ПРОГРЕСУ (Reviews & User Achievements)
        print("Inserting reviews and player achievements...")
        reviews_query = """
        INSERT INTO reviews (review_id, user_id, game_id, review_text, is_recommended)
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (user_id, game_id) DO NOTHING
        """
        achievements_query = """
        INSERT INTO user_achievements (user_id, game_id, playtime_hours, achievements_unlocked)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (user_id, game_id) DO NOTHING
        """

        # Згенеруємо 5000 випадкових зв'язків для ігрової активності та фідбеку
        for _ in range(5000):
            u_id = random.choice(user_ids)
            g_id = random.choice(game_ids)

            # Відгуки
            r_id = str(uuid.uuid4())
            review_text = fake.sentence(nb_words=8)
            is_rec = random.choice([True, True, False])
            cursor.execute(reviews_query, (r_id, u_id, g_id, review_text, is_rec))

            # Ігрові досягнення
            playtime = random.randint(1, 450)
            ach_unlocked = random.randint(0, 50)
            cursor.execute(achievements_query, (u_id, g_id, playtime, ach_unlocked))

        connection.commit()
        print("All data generated successfully!")

        # Фінальна перевірка кількості записів
        cursor.execute("SELECT COUNT(*) FROM order_items;")
        print(f"Total rows inside 'order_items': {cursor.fetchone()[0]}")

    except Error as e:
        connection.rollback()
        print(f"An error occurred: {e}")
    finally:
        cursor.close()
        connection.close()


if __name__ == "__main__":
    insert_data()