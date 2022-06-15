require "sqlite3"
require "rulers/util"

DB = SQLite3::Database.new "test.db"

module Rulers
  module Model
    class SQLite
      def self.table
        Rulers.to_underscore name
      end

      def self.schema
        return @schema if @schema

        @schema = {}
        DB.table_info(table) do |row|
          @schema[row["name"]] = row["type"]
        end

        @schema
      end

      def initialize(data = nil)
        @hash = data
      end

      def self.to_sql(val)
        case val
        when Numeric
          val.to_s
        when String
          "'#{val}'"
        when NilClass
          "''"
        else
          raise "Can't change #{val.class} to SQL!"
        end
      end

      def self.create(values)
        values.delete "id"
        keys = schema.keys - ["id"]
        vals = keys.map do |key|
          values[key] ? to_sql(values[key]) : "null"
        end

        DB.execute <<~SQL
          INSERT INTO #{table} (#{keys.join ","}) 
          VALUES (#{vals.join ","});
        SQL

        data = Hash[keys.zip vals]
        sql = "SELECT last_insert_rowid();"
        data["id"] = DB.execute(sql)[0][0]
        self.new data
      end

      def self.count
        DB.execute(<<-SQL)[0][0]
          SELECT COUNT(*) FROM #{table}
        SQL
      end

      def self.find(id)
        row = DB.execute(<<-SQL)[0]
          SELECT #{schema.keys.join ","} 
          FROM #{table} where id = #{id};
        SQL

        data = Hash[schema.keys.zip row]
        self.new data
      end

      def self.find_by(option)
        return false if option.nil?

        options = option.map{|k, v| "#{k} = '#{v}'"}.join(" AND ")
        row = DB.execute(<<-SQL)[0]
          SELECT #{schema.keys.join ","} 
          FROM #{table} where #{options};
        SQL

        return [] if row.nil?
        data = Hash[schema.keys.zip row]
        self.new data
      end

      def [](name)
        @hash[name.to_s]
      end

      def []=(name, value)
        @hash[name.to_s] = value
      end

      def save!
        unless @hash["id"]
          self.class.create
          return true
        end
        @hash.each {|k, v| p k, v}

        fields = @hash.map do |k, v|
          "#{k}=#{self.class.to_sql(v)}"
        end.join ","

        p fields

        DB.execute <<-SQL
          UPDATE #{self.class.table}
          SET #{fields}
          WHERE id = #{@hash["id"]}
        SQL

        true
      end

      def save
        self.save! rescue false
      end

    end
  end
end