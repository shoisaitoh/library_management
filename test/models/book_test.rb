require 'test_helper'

class BookTest < ActiveSupport::TestCase
  def setup
    @test_data_file = Rails.root.join('test', 'fixtures', "book_model_test_#{SecureRandom.hex(8)}.json")
    @original_data_file = JsonDataStore::DATA_FILE
    JsonDataStore.const_set(:DATA_FILE, @test_data_file)
    
    # テストデータの準備
    @test_data = {
      'books' => [
        {
          'id' => 1,
          'title' => 'テスト書籍1',
          'author' => 'テスト著者1',
          'finished_date' => '2025-01-01',
          'publisher' => 'テスト出版社',
          'isbn' => '1234567890123',
          'price' => 1000,
          'rating' => 8
        }
      ]
    }
    
    FileUtils.mkdir_p(File.dirname(@test_data_file))
    JsonDataStore.write_data(@test_data)

    @valid_attributes = {
      title: '有効な書籍名',
      author: '有効な著者名',
      finished_date: '2025-01-01',
      publisher: '有効な出版社',
      isbn: '1234567890123',
      price: 1500,
      rating: 9
    }
  end

  def teardown
    File.delete(@test_data_file) if File.exist?(@test_data_file)
    JsonDataStore.const_set(:DATA_FILE, @original_data_file)
  end

  test "valid book should be valid" do
    book = Book.new(@valid_attributes)
    assert book.valid?
  end

  test "should require title" do
    book = Book.new(@valid_attributes.except(:title))
    assert_not book.valid?
    assert_includes book.errors[:title], "can't be blank"
  end

  test "should require author" do
    book = Book.new(@valid_attributes.except(:author))
    assert_not book.valid?
    assert_includes book.errors[:author], "can't be blank"
  end

  test "should require finished_date" do
    book = Book.new(@valid_attributes.except(:finished_date))
    assert_not book.valid?
    assert_includes book.errors[:finished_date], "can't be blank"
  end

  test "title should not be too long" do
    book = Book.new(@valid_attributes.merge(title: 'a' * 201))
    assert_not book.valid?
    assert_includes book.errors[:title], "is too long (maximum is 200 characters)"
  end

  test "author should not be too long" do
    book = Book.new(@valid_attributes.merge(author: 'a' * 101))
    assert_not book.valid?
    assert_includes book.errors[:author], "is too long (maximum is 100 characters)"
  end

  test "publisher should not be too long" do
    book = Book.new(@valid_attributes.merge(publisher: 'a' * 101))
    assert_not book.valid?
    assert_includes book.errors[:publisher], "is too long (maximum is 100 characters)"
  end

  test "isbn should not be too long" do
    book = Book.new(@valid_attributes.merge(isbn: '1' * 14))
    assert_not book.valid?
    assert_includes book.errors[:isbn], "is too long (maximum is 13 characters)"
  end

  test "price should be non-negative" do
    book = Book.new(@valid_attributes.merge(price: -1))
    assert_not book.valid?
    assert_includes book.errors[:price], "must be greater than or equal to 0"
  end

  test "rating should be between 1 and 10" do
    book = Book.new(@valid_attributes.merge(rating: 0))
    assert_not book.valid?
    assert_includes book.errors[:rating], "must be in 1..10"

    book = Book.new(@valid_attributes.merge(rating: 11))
    assert_not book.valid?
    assert_includes book.errors[:rating], "must be in 1..10"
  end

  test "optional fields can be blank" do
    book = Book.new({
      title: 'タイトル',
      author: '著者',
      finished_date: '2025-01-01'
    })
    assert book.valid?
  end

  test "Book.all returns all books" do
    books = Book.all
    assert_equal 1, books.length
    assert_instance_of Book, books.first
    assert_equal 'テスト書籍1', books.first.title
  end

  test "Book.find returns specific book" do
    book = Book.find(1)
    assert_not_nil book
    assert_instance_of Book, book
    assert_equal 'テスト書籍1', book.title
    assert_equal 1, book.id
  end

  test "Book.find returns nil for non-existent id" do
    book = Book.find(999)
    assert_nil book
  end

  test "save creates new book with valid attributes" do
    book = Book.new(@valid_attributes)
    assert book.save
    assert_not_nil book.id
    # IDが自動生成されることを確認（具体的な値ではなく存在を確認）

    # データが実際に保存されているかチェック
    saved_book = Book.find(book.id)
    assert_not_nil saved_book
    assert_equal '有効な書籍名', saved_book.title
  end

  test "save fails with invalid attributes" do
    book = Book.new(@valid_attributes.except(:title))
    assert_not book.save
  end

  test "save updates existing book" do
    book = Book.find(1)
    return skip "Book not found" unless book
    
    book.title = '更新されたタイトル'
    assert book.save

    # データが更新されているかチェック
    updated_book = Book.find(1)
    assert_equal '更新されたタイトル', updated_book.title
  end

  test "update updates book with valid attributes" do
    book = Book.find(1)
    result = book.update({ title: '更新されたタイトル', author: '更新された著者' })
    assert result

    # データが更新されているかチェック
    updated_book = Book.find(1)
    assert_equal '更新されたタイトル', updated_book.title
    assert_equal '更新された著者', updated_book.author
  end

  test "update fails with invalid attributes" do
    book = Book.find(1)
    result = book.update({ title: '', author: '著者' })
    assert_not result
  end

  test "destroy removes book from data store" do
    book = Book.find(1)
    result = book.destroy
    assert result

    # 削除されているかチェック
    deleted_book = Book.find(1)
    assert_nil deleted_book
  end

  test "persisted? returns true for saved book" do
    book = Book.find(1)
    assert book.persisted?
  end

  test "persisted? returns false for new book" do
    book = Book.new(@valid_attributes)
    assert_not book.persisted?
  end

  test "to_param returns id as string" do
    book = Book.find(1)
    assert_equal '1', book.to_param
  end
end