from sqlalchemy import create_engine, text

def create_database_if_not_exists(mysql_root_url, db_name):
    engine = create_engine(mysql_root_url, execution_options={"autocommit": True})
    with engine.connect() as conn:
        conn.execute(text(f"CREATE DATABASE IF NOT EXISTS `{db_name}`"))

def run_sql_script(mysql_root_url, db_name, sql_file_path):
    
    create_database_if_not_exists(mysql_root_url, db_name)
    
    engine = create_engine(
        mysql_root_url + db_name,
        execution_options={"autocommit": True}
    )

    with open(sql_file_path, "r") as f:
        sql_script = f.read()

    cleaned_script = []
    for line in sql_script.splitlines():
        if line.strip().upper().startswith("DELIMITER"):
            continue
        cleaned_script.append(line)
    cleaned_script = "\n".join(cleaned_script)

    statements = cleaned_script.split(";")

    with engine.connect() as conn:
        for stmt in statements:
            stmt = stmt.strip()
            if stmt:
                conn.execute(text(stmt))
