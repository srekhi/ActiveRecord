require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    cols = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    @columns = cols.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |header|
      define_method(header) { attributes[header]  }
      define_method("#{header}=") { |set_to_val| attributes[header] = set_to_val } #we define setter methods on each instance of classs
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name #thismethod will be inherited to child classes, the state of ivar will not.
  end

  def self.table_name
    @table_name ||= "#{self}".tableize
  end

  def self.all
    # hash_of_objects = DBConnection.execute(<<-SQL, table_name)
    #   SELECT
    #     *
    #   FROM
    #     #{table_name}
    # SQL
    hash_of_objects = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    parse_all(hash_of_objects)
  end

  def self.parse_all(results)
    #results is raw hash objects where key is the column name and values are col values
    #results.each do |attribute, value|
    created_objects = []
    results.each do |object_attributes|
      created_objects << self.new(object_attributes)
    end
    created_objects
  end

  def self.find(id)
    object_attributes = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
      LIMIT
        1
    SQL
    found_obj = self.parse_all(object_attributes).first
  end

  def initialize(params = {})
    #p params
    params.each do |attribute, value|
      raise "unknown attribute '#{attribute}'" unless self.class.columns.include?(attribute.to_sym)
      #attribute = value
      send("#{attribute}=", value)
    end

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    #return an array of values for each attribute
    values = []
    parent.columns.map do |attribute|
      values << send("#{attribute}")
    end
    values
  end

  def insert
    cols = self.class.columns.drop(1)
    col_names = cols.join(",")
    attr_vals = cols.map { |attr_name| send("#{attr_name}") }
    question_marks = (["?"] * cols.length).join(",")
    DBConnection.execute(<<-SQL, *attr_vals)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    keys = self.class.columns.drop(1).map { |attr_name| "#{attr_name} = ?"}.join(", ")
    attr_vals = self.class.columns.drop(1).map { |attr_name| "#{send(attr_name)}" }
    DBConnection.execute(<<-SQL, *attr_vals, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{keys}
      WHERE
        id = ?
      SQL
  end

  def save
    self.id.nil? ? insert : update
  end

  private
  def parent
    self.class
  end
end
