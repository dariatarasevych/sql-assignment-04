import uuid
import psycopg2
from psycopg2 import Error


HOST = 'localhost' # put your credentials here
USER = 'postgres' # put your credentials here
PASSWORD = '1' # put your credentials here
DATABASE = 'stores' # put your credentials here
PORT = '5432' # put your credentials here


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


def execute_query(connection, query, data):
    """Execute a single query."""
    try:
        with connection.cursor() as cursor:
            cursor.execute(query, data)
        connection.commit()
        print("Query executed successfully")
    except Error as e:
        connection.rollback()
        print(f"The error '{e}' occurred")


def insert_data():
    connection = create_connection()
    if connection is None:
        return

    students_query = """
    INSERT INTO students (id, first_name, last_name, email, phone, course, educational_degree, speciality, active)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    ON CONFLICT (id) DO NOTHING
    """
    students_data = [
        (str(uuid.uuid4()), "John", "Doe", "john.doe@example.com", "1234567890", 1, "Bachelor", "Computer Science", True),
        (str(uuid.uuid4()), "Jane", "Smith", "jane.smith@example.com", "0987654321", 2, "Master", "Mathematics", True),
    ]
    for data in students_data:
        execute_query(connection, students_query, data)

    rooms_query = """
    INSERT INTO rooms (id, building, floor, number, display_name, seats_number)
    VALUES (%s, %s, %s, %s, %s, %s)
    ON CONFLICT (id) DO NOTHING
    """
    rooms_data = [
        (str(uuid.uuid4()), "Building A", 1, 101, "Room 101", 30),
        (str(uuid.uuid4()), "Building B", 2, 202, "Room 202", 50),
    ]
    for data in rooms_data:
        execute_query(connection, rooms_query, data)

    courses_query = """
    INSERT INTO courses (id, course_display_short_name, course_display_full_name, course_description, lectures_num, practices_num)
    VALUES (%s, %s, %s, %s, %s, %s)
    ON CONFLICT (id) DO NOTHING
    """
    courses_data = [
        (str(uuid.uuid4()), "CS101", "Introduction to Computer Science", "Basic concepts of computer science", 30, 15),
        (str(uuid.uuid4()), "MATH201", "Advanced Mathematics", "In-depth study of advanced mathematical concepts", 25, 10),
    ]
    for data in courses_data:
        execute_query(connection, courses_query, data)

    instructors_query = """
    INSERT INTO instructors (id, first_name, last_name, email, phone, active)
    VALUES (%s, %s, %s, %s, %s, %s)
    ON CONFLICT (id) DO NOTHING
    """
    instructors_data = [
        (str(uuid.uuid4()), "Alice", "Johnson", "alice.johnson@example.com", "1122334455", True),
        (str(uuid.uuid4()), "Bob", "Williams", "bob.williams@example.com", "5544332211", True),
    ]
    for data in instructors_data:
        execute_query(connection, instructors_query, data)

    lessons_schedule_query = """
    INSERT INTO lessons_schedule (id, start_time, end_time)
    VALUES (%s, %s, %s)
    ON CONFLICT (id) DO NOTHING
    """
    lessons_schedule_data = [(1, "08:00:00", "09:00:00"), (2, "09:00:00", "10:00:00")]
    for data in lessons_schedule_data:
        execute_query(connection, lessons_schedule_query, data)

    instructors_courses_query = """
    INSERT INTO instructors_courses (instructor_id, course_id)
    VALUES (%s, %s)
    ON CONFLICT (instructor_id, course_id) DO NOTHING
    """
    instructors_courses_data = [(instructors_data[0][0], courses_data[0][0]), (instructors_data[1][0], courses_data[1][0])]
    for data in instructors_courses_data:
        execute_query(connection, instructors_courses_query, data)

    students_course_groups_query = """
    INSERT INTO students_course_groups (id, course_id)
    VALUES (%s, %s)
    ON CONFLICT (id) DO NOTHING
    """
    students_course_groups_data = [(str(uuid.uuid4()), courses_data[0][0]), (str(uuid.uuid4()), courses_data[1][0])]
    for data in students_course_groups_data:
        execute_query(connection, students_course_groups_query, data)

    students_course_group_students_query = """
    INSERT INTO students_course_group_students (student_id, group_id)
    VALUES (%s, %s)
    ON CONFLICT (student_id, group_id) DO NOTHING
    """
    students_course_group_students_data = [
        (students_data[0][0], students_course_groups_data[0][0]),
        (students_data[1][0], students_course_groups_data[1][0]),
    ]
    for data in students_course_group_students_data:
        execute_query(connection, students_course_group_students_query, data)

    schedule_query = """
    INSERT INTO schedule (id, course_id, instructor_id, students_course_group_id, week_day, lesson_schedule_id, room_id)
    VALUES (%s, %s, %s, %s, %s, %s, %s)
    ON CONFLICT (id) DO NOTHING
    """
    schedule_data = [
        (1, courses_data[0][0], instructors_data[0][0], students_course_groups_data[0][0], "Monday", 1, rooms_data[0][0]),
        (2, courses_data[1][0], instructors_data[1][0], students_course_groups_data[1][0], "Tuesday", 2, rooms_data[1][0]),
    ]
    for data in schedule_data:
        execute_query(connection, schedule_query, data)

    connection.close()


if __name__ == "__main__":
    insert_data()
