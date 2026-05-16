import mysql.connector

# MySQL Connection
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="#JJeusebio678213",
    database="flutterdb"
)

# Check connection
if db.is_connected():
    print("Connected to MySQL")

# Create cursor
cursor = db.cursor()