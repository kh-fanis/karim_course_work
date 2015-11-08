# encoding: utf-8
require "active_record"
require "sqlite3"
require "logger"
require "yaml"

ActiveRecord::Base.logger = Logger.new('debug.log')
configuration = YAML::load(IO.read('config/database.yml'))
ActiveRecord::Base.establish_connection(configuration['development'])

class Item < ActiveRecord::Base
  belongs_to :category

  validates :name,        :length => { :in => 5..255,  :message => "Имя долно быть больше 5 и меньше 255 символов!" }
  validates :description, :length => { :minimum => 10, :message => "Описание должно быть больше 10 символов!" }
  validates :barcode,     :length => { :in => 1..255,  :message => "Введите штрих код!" }

  validates_numericality_of :price, :message => "Цена должна быть числом!"

  validates_presence_of :category_id, :message => "Выберите категорию!"
end

class Category < ActiveRecord::Base
  has_many :items

  validates :name, :length => { :in => 5..255, :message => "Имя долно быть больше 5 и меньше 255 символов!" }

  validates_uniqueness_of :name, :message => "Такая категория уже существует"
end