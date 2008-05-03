gem 'do_mysql', '=0.9.0'
require 'do_mysql'

module DataMapper
  module Adapters

    # Options:
    # host, user, password, database (path), socket(uri query string), port
    class MysqlAdapter < DataObjectsAdapter

      # TypeMap for MySql databases.
      #
      # ==== Returns
      # DataMapper::TypeMap:: default TypeMap for MySql databases.
      def self.type_map
        @type_map ||= TypeMap.new(super) do |tm|
          tm.map(Fixnum).to('INT').with(:size => 11)
          tm.map(TrueClass).to('TINYINT').with(:size => 1)  # TODO: map this to a BIT or CHAR(0) field?
          tm.map(Object).to('TEXT')
        end
      end

      def create_table_statement(model)
        "#{super} ENGINE = InnoDB CHARACTER SET utf8 COLLATE utf8_unicode_ci"
      end
      
      def exists?(table_name)
        query_table(table_name).size > 0
      end

      def recreate_database
        drop_database
        create_database
      end
      
      def drop_database
        DataMapper.logger.info "Dropping #{db_name}"
        execute "DROP DATABASE #{db_name}"
      end
      
      def create_database
        DataMapper.logger.info "Creating #{db_name}"
        execute "CREATE DATABASE #{db_name}"
        execute "USE #{db_name}"        
      end

      def db_name
        @uri.path.split('/').last
      end

      def query_table(table_name)
        query("SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='#{db_name}' AND TABLE_NAME='#{table_name}'")
      end

      private

      def property_schema_statement(schema)
        statement = super
        statement << " AUTO_INCREMENT" if schema[:serial?]
        statement
      end

      def quote_table_name(table_name)
        "`#{table_name}`"
      end

      def quote_column_name(column_name)
        "`#{column_name}`"
      end

      def rewrite_uri(uri, options)
        new_uri = uri.dup
        new_uri.host = options[:host] || uri.host
        new_uri.user = options[:user] || uri.user
        new_uri.password = options[:password] || uri.password
        new_uri.path = (options[:database] && "/" << options[:database]) || uri.path
        new_uri.port = options[:port] || uri.port
        new_uri.query = (options[:socket] && "socket=#{options[:socket]}") || uri.query

        new_uri
      end

    end # class MysqlAdapter
  end # module Adapters
end # module DataMapper
