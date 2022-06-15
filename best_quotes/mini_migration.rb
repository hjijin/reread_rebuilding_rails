require "sqlite3"
# require "rulers/sqlite_model"

conn = SQLite3::Database.new "test.db"
conn.execute <<SQL
  create table my_table (id INTEGER PRIMARY KEY, posted INTEGER, title VARCHAR(30), body VARCHAR(32000));#{' '}
SQL
