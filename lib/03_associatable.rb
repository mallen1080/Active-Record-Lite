require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || (name.to_s + "_id").to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.downcase.capitalize
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] ||
      (self_class_name + "_id").downcase.singularize.to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] ||
      name.to_s.downcase.singularize.capitalize
  end
end

module Associatable

  def belongs_to(name, options = {})
    options_obj = BelongsToOptions.new(name, options)
    @options = {}
    @options[name] = options_obj

    define_method(name) do
      klass = options_obj.send(:model_class)
      primary = options_obj.send(:primary_key)
      klass.where(primary => self.id).first
    end
  end

  def has_many(name, options = {})
    self_class_name = self.to_s
    options_obj = HasManyOptions.new(name, self_class_name, options)

    define_method(name) do
      klass = options_obj.send(:model_class)
      foreign = options_obj.send(:foreign_key)
      klass.where(foreign => self.id)
    end
  end

  def assoc_options
    @options ||= {}
  end
end

class SQLObject
  extend Associatable
end
