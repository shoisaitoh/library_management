require 'test_helper'

class JsonDataStoreTest < ActiveSupport::TestCase
  def setup
    @test_data_file = Rails.root.join('test', 'fixtures', "test_books_#{SecureRandom.hex(8)}.json")
    @original_data_file = JsonDataStore::DATA_FILE
    
    # テスト用のデータファイルパスに変更
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
        },
        {
          'id' => 2,
          'title' => 'テスト書籍2',
          'author' => 'テスト著者2',
          'finished_date' => '2025-01-02',
          'publisher' => 'テスト出版社2',
          'isbn' => '1234567890124',
          'price' => 1500,
          'rating' => 9
        }
      ]
    }
    
    # テスト用ディレクトリの作成
    FileUtils.mkdir_p(File.dirname(@test_data_file))
    JsonDataStore.write_data(@test_data)
  end

  def teardown
    # テストファイルの削除
    begin
      File.delete(@test_data_file) if File.exist?(@test_data_file)
    rescue Errno::ENOENT
      # ファイルが存在しない場合は無視
    end
    
    # 元のデータファイルパスに戻す
    JsonDataStore.const_set(:DATA_FILE, @original_data_file)
  end

  test "read_data returns data from JSON file" do
    data = JsonDataStore.read_data
    assert_equal 2, data['books'].length
    assert_equal 'テスト書籍1', data['books'][0]['title']
  end

  test "read_data returns empty structure when file doesn't exist" do
    File.delete(@test_data_file)
    data = JsonDataStore.read_data
    assert_equal({ 'books' => [] }, data)
  end

  test "write_data saves data to JSON file" do
    new_data = { 'books' => [{ 'id' => 3, 'title' => '新しい本', 'author' => '新しい著者' }] }
    JsonDataStore.write_data(new_data)
    
    data = JsonDataStore.read_data
    assert_equal 1, data['books'].length
    assert_equal '新しい本', data['books'][0]['title']
  end

  test "all_books returns all books" do
    books = JsonDataStore.all_books
    assert_equal 2, books.length
    assert_equal 'テスト書籍1', books[0]['title']
    assert_equal 'テスト書籍2', books[1]['title']
  end

  test "find_book returns specific book by id" do
    book = JsonDataStore.find_book(1)
    assert_not_nil book
    assert_equal 'テスト書籍1', book['title']
    assert_equal 'テスト著者1', book['author']
  end

  test "find_book returns nil for non-existent id" do
    book = JsonDataStore.find_book(999)
    assert_nil book
  end

  test "add_book adds new book with auto-generated id" do
    new_book = {
      'title' => '追加書籍',
      'author' => '追加著者',
      'finished_date' => '2025-01-03'
    }
    
    result = JsonDataStore.add_book(new_book)
    assert_equal 3, result['id']
    assert_equal '追加書籍', result['title']
    
    # データが実際に保存されているかチェック
    books = JsonDataStore.all_books
    assert_equal 3, books.length
    assert_equal '追加書籍', books[2]['title']
  end

  test "update_book updates existing book" do
    updated_data = {
      'title' => '更新された書籍1',
      'author' => '更新された著者1',
      'finished_date' => '2025-01-10'
    }
    
    result = JsonDataStore.update_book(1, updated_data)
    assert_equal 1, result['id']
    assert_equal '更新された書籍1', result['title']
    
    # データが実際に更新されているかチェック
    book = JsonDataStore.find_book(1)
    assert_equal '更新された書籍1', book['title']
    assert_equal '更新された著者1', book['author']
  end

  test "update_book returns nil for non-existent id" do
    result = JsonDataStore.update_book(999, { 'title' => 'test' })
    assert_nil result
  end

  test "delete_book removes book from data" do
    result = JsonDataStore.delete_book(1)
    assert_equal true, result
    
    # 削除されたかチェック
    books = JsonDataStore.all_books
    assert_equal 1, books.length
    assert_equal 'テスト書籍2', books[0]['title']
    
    # 削除された書籍が見つからないことをチェック
    book = JsonDataStore.find_book(1)
    assert_nil book
  end

  test "delete_book returns false for non-existent id" do
    result = JsonDataStore.delete_book(999)
    assert_equal false, result
  end

  test "add_book generates sequential ids" do
    # 最初の追加
    book1 = JsonDataStore.add_book({ 'title' => 'Book A', 'author' => 'Author A', 'finished_date' => '2025-01-01' })
    assert_equal 3, book1['id']
    
    # 2番目の追加
    book2 = JsonDataStore.add_book({ 'title' => 'Book B', 'author' => 'Author B', 'finished_date' => '2025-01-02' })
    assert_equal 4, book2['id']
  end
end