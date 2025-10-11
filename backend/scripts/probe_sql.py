import json
import pyodbc

CANDIDATE_DRIVERS = [
    "ODBC Driver 17 for SQL Server",
    "ODBC Driver 18 for SQL Server",
]
CANDIDATE_SERVERS = [
    r".\\SQLEXPRESS",
    r"(local)\\SQLEXPRESS",
    r"localhost\\SQLEXPRESS",
    r"127.0.0.1\\SQLEXPRESS",
    r"(localdb)\\MSSQLLocalDB",
]
CANDIDATE_PROTOCOLS = [
    "tcp",
    "np",
]

results = []

for driver in CANDIDATE_DRIVERS:
    for srv in CANDIDATE_SERVERS:
        for proto in CANDIDATE_PROTOCOLS:
            server = srv
            if proto == "np":
                # Named pipes path varies; default pipe names for local instances
                if "SQLEXPRESS" in srv:
                    server = r"np:\\.\pipe\MSSQL$SQLEXPRESS\sql\query"
                elif "MSSQLLocalDB" in srv:
                    server = r"np:\\.\pipe\LOCALDB#\tsql\query"
                else:
                    server = r"np:\\.\pipe\sql\query"
            conn_str = f"DRIVER={{{driver}}};SERVER={server};DATABASE=master;Trusted_Connection=yes;"
            entry = {"driver": driver, "server": server, "protocol": proto}
            try:
                conn = pyodbc.connect(conn_str, timeout=3)
                cur = conn.cursor()
                cur.execute("SELECT name FROM sys.databases ORDER BY name;")
                dbs = [row[0] for row in cur.fetchall()]
                entry["status"] = "ok"
                entry["databases"] = dbs
            except Exception as e:
                entry["status"] = "error"
                entry["error"] = str(e)
            finally:
                try:
                    cur.close()
                    conn.close()
                except Exception:
                    pass
            results.append(entry)

print(json.dumps(results, indent=2))
