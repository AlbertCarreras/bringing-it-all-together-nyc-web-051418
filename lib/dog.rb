require 'pry'

class Dog
  attr_accessor :name, :breed, :id

  def initialize(hash)
    @id = nil
    @name = hash[:name]
    @breed = hash[:breed]
  end

  def self.create_table
    sql = <<-SQL
    CREATE TABLE IF NOT EXISTS dogs (
      id INTEGER PRIMARY KEY,
      name TEXT,
      breed TEXT
    );
    SQL

    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<-SQL
    DROP TABLE dogs
    SQL

    DB[:conn].execute(sql)
  end

  def self.new_from_db(row)
    new_hash = { name: row[1], breed: row[2] }
    new_dog = Dog.new(new_hash)
    new_dog.id = row[0]
    new_dog
  end

  def save
    if self.id
      self.update
    else
      sql = <<-SQL
      INSERT INTO dogs (name, breed)
      VALUES (?, ?);
      SQL

      sql_last_id = <<-SQL
      SELECT last_insert_rowid() FROM dogs;
      SQL

      DB[:conn].execute(sql, @name, @breed)

      @id = DB[:conn].execute(sql_last_id)[0][0]
    end
    self
  end

  def self.create(hash)
    new(hash).save
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ?
      LIMIT 1;
    SQL
    searched_dog = DB[:conn].execute(sql, name)[0]
    self.new_from_db(searched_dog)
  end

  def self.find_by_id(id)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE id = ?
      LIMIT 1;
    SQL
    searched_dog = DB[:conn].execute(sql, id)[0]
    self.new_from_db(searched_dog)
  end

  def self.find_or_create_by(hash)
    sql = <<-SQL
    SELECT * FROM dogs
    WHERE name = ? AND breed = ?;
    SQL
    dog = DB[:conn].execute(sql, hash[:name], hash[:breed])

    if dog.empty? # does not exist yet
      return self.create(hash)
    else # it already exists
      return self.new_from_db(dog[0])
    end
  end

  def update
    sql = <<-SQL
      UPDATE dogs
      SET name = ?, breed = ?
      WHERE id = ?;
    SQL

    DB[:conn].execute(sql, @name, @breed, @id)
  end
end
