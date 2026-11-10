from psycopg import Connection


def check_database(connection: Connection) -> None:
    connection.execute("SELECT 1").fetchone()
