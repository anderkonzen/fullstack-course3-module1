require 'mongo'
require 'json'
require 'pp'
require 'byebug'
Mongo::Logger.logger.level = ::Logger::INFO
#Mongo::Logger.logger.level = ::Logger::DEBUG

class Solution
  MONGO_URL='mongodb://localhost:27017'
  MONGO_DATABASE='test'
  RACE_COLLECTION='race1'

  # helper function to obtain connection to server and set connection to use specific DB
  # set environment variables MONGO_URL and MONGO_DATABASE to alternate values if not
  # using the default.
  def self.mongo_client
    url=ENV['MONGO_URL'] ||= MONGO_URL
    database=ENV['MONGO_DATABASE'] ||= MONGO_DATABASE
    db = Mongo::Client.new(url)
    @@db=db.use(database)
  end

  # helper method to obtain collection used to make race results. set environment
  # variable RACE_COLLECTION to alternate value if not using the default.
  def self.collection
    collection=ENV['RACE_COLLECTION'] ||= RACE_COLLECTION
    return mongo_client[collection]
  end

  # helper method that will load a file and return a parsed JSON document as a hash
  def self.load_hash(file_path)
    file=File.read(file_path)
    JSON.parse(file)
  end

  # initialization method to get reference to the collection for instance methods to use
  def initialize
    @coll=self.class.collection
  end

  #
  # Lecture 1: Create
  #

  def clear_collection
    self.class.collection.delete_many
  end

  def load_collection(file_path)
    data = Solution.load_hash(file_path)
    self.class.collection.insert_many(data)
  end

  def insert(race_result)
    self.class.collection.insert_one(race_result)
  end

  #
  # Lecture 2: Find By Prototype
  #

  def all(prototype={})
    self.class.collection.find(prototype)
  end

  def find_by_name(fname, lname)
    self.class.collection.find({first_name: fname, last_name: lname}).projection(first_name: true, last_name: true, number: true, _id: false)
  end

  #
  # Lecture 3: Paging
  #

  def find_group_results(group, offset, limit)
    self.class.collection.find({group: group}).skip(offset).limit(limit).sort({secs: 1}).projection(_id: false, group: false)
  end

  #
  # Lecture 4: Find By Criteria
  #

  def find_between(min, max)
    self.class.collection.find({ secs: { :$gt => min, :$lt => max } })
  end

  def find_by_letter(letter, offset, limit)
    self.class.collection.find({last_name: {:$regex => "^#{letter.upcase}.+"}}).sort({last_name: 1}).skip(offset).limit(limit)
  end

  #
  # Lecture 5: Updates
  #

  def update_racer(racer)
    self.class.collection.find(_id: racer[:_id]).replace_one(racer)
  end

  def add_time(number, secs)
    self.class.collection.find(number: number).update_one({:$inc => {secs: secs}})
  end

end

s=Solution.new
race1=Solution.collection
