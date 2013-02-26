require 'tiny_tds'

module Labrador
  class Mssql
    extend Configuration
    include RelationalStore
    include ViewHelper

    attr_accessor :host, :port, :database, :socket, :session

    DEFAULT_PORT = 1433

    def initialize(params = {})
      @host     = params[:host]
      @port     = params[:port] || DEFAULT_PORT
      @database = params[:database]
      @user     = params[:user]
      password  = params[:password]

      @session  = ::TinyTds::Client.new(host: @host, :username => @user, password: password, database: @database, port: @port)
    end

    def collections
      names = []
      session.execute("SELECT name FROM sys.tables ORDER BY name ASC").each{|row| names << row['name'] }

      names
    end

    # Parse msyql-ruby Mysql::Result into array of key value records.
    def parse_results(results)
      results.collect do |row|
        record = {}
        row.each_with_index{|val, i| record[results.fields[i].name] = val }

        record
      end
    end

    def find(collection_name, options = {})
      order_by     = options[:order_by] || primary_key_for(collection_name)
      limit        = (options[:limit] || 200).to_i
      skip         = (options[:skip] || 0).to_i
      direction    = options[:direction] || 'ASC'
      where_clause = options[:conditions]

      results = []
      resp = session.execute("
        ;WITH Results_CTE AS
        (
          SELECT *,
          ROW_NUMBER() #{"OVER (ORDER BY #{order_by} #{direction})"} AS RowNum
          FROM #{collection_name}
          #{"WHERE #{where_clause}" if where_clause}
        )
        SELECT *
        FROM Results_CTE
        WHERE RowNum > #{skip}
        AND RowNum <= #{skip} + #{limit}
      ")
      resp.each{|row| results << row.reject{|k| k == 'RowNum'} }
      resp.do

      results
    end

    def create(collection_name, data = {})
      primary_key_name = primary_key_for(collection_name)
      values = data.collect{|key, val| "'#{session.escape(val.to_s)}'" }.join(", ")
      fields = data.collect{|key, val| key.to_s }.join(", ")
      resp = session.execute("
        INSERT INTO #{collection_name}
        (#{ fields })
        VALUES (#{ values })
      ")
      resp.do
      resp
    end

    def update(collection_name, id, data = {})
      primary_key_name = primary_key_for(collection_name)
      prepared_key_values = data.collect{|key, val| "#{key}='#{session.escape(val)}'" }.join(","
      query = "
        UPDATE #{collection_name}
        SET #{ prepared_key_values }
        WHERE #{primary_key_name}=#{id}
      "
      resp = session.execute(query)
      resp.do
      resp
    end

    def delete(collection_name, id)
      primary_key_name = primary_key_for(collection_name)
      resp = session.execute("DELETE FROM #{collection_name} WHERE #{primary_key_name}=#{id}")
      resp.do
      resp
    end

    def schema(collection_name)
      # parse_results(session.execute("DESCRIBE #{collection_name}"))
      resp = session.execute("
        SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME='#{collection_name}')
      ")
      resp.do
      resp
    end

    def primary_key_for(collection_name)
      query = "
        SELECT column_name
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        WHERE OBJECTPROPERTY(OBJECT_ID(constraint_name), 'IsPrimaryKey') = 1
        AND table_name = '#{collection_name}'"
      result = session.execute(query)
      primary_key = result && result.first['column_name']
      result.do
      primary_key
    end

    def connected?
      session.active? rescue false
    end

    def close
      session.close
    end

    def id
      "mssql"
    end

    def name
      I18n.t('adapters.sqlserver.title')
    end

    def as_json(options = nil)
      {
        id: self.id,
        name: self.name
      }
    end
  end
end
