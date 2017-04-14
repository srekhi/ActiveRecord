require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    p params
    where_keys = params.keys.map { |key| "#{key}= ?" }.join("AND ")
    p where_keys
    where_vals = params.values
    p where_vals
    obj_params = DBConnection.execute(<<-SQL, *where_vals)
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      #{where_keys}
    SQL
    found_obj = parse_all(obj_params)
  end
end

class SQLObject
  extend Searchable
end
