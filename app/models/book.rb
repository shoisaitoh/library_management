class Book
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :id, :integer
  attribute :title, :string
  attribute :author, :string
  attribute :finished_date, :string
  attribute :publisher, :string
  attribute :isbn, :string
  attribute :price, :integer
  attribute :rating, :integer

  validates :title, presence: true, length: { maximum: 200 }
  validates :author, presence: true, length: { maximum: 100 }
  validates :finished_date, presence: true
  validates :publisher, length: { maximum: 100 }
  validates :isbn, length: { maximum: 13 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :rating, numericality: { in: 1..10 }, allow_blank: true

  def self.all
    JsonDataStore.all_books.map do |book_data|
      new(book_data)
    end
  end

  def self.find(id)
    book_data = JsonDataStore.find_book(id)
    return nil unless book_data

    new(book_data)
  end

  def save
    return false unless valid?

    book_data = attributes.compact
    
    if id.present?
      JsonDataStore.update_book(id, book_data)
    else
      saved_data = JsonDataStore.add_book(book_data)
      self.id = saved_data['id']
    end
    
    true
  rescue => e
    Rails.logger.error "Book save error: #{e.message}"
    false
  end

  def update(attributes)
    assign_attributes(attributes)
    return false unless valid?

    book_data = self.attributes.compact
    JsonDataStore.update_book(id, book_data)
    true
  rescue => e
    Rails.logger.error "Book update error: #{e.message}"
    false
  end

  def destroy
    return false unless id.present?

    JsonDataStore.delete_book(id)
  rescue => e
    Rails.logger.error "Book destroy error: #{e.message}"
    false
  end

  def persisted?
    id.present?
  end

  def to_param
    id.to_s
  end
end