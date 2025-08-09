require 'test_helper'

class BooksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @test_data_file = Rails.root.join('test', 'fixtures', 'test_books.json')
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
    
    FileUtils.mkdir_p(File.dirname(@test_data_file))
    JsonDataStore.write_data(@test_data)

    @valid_book_params = {
      title: '新しい書籍',
      author: '新しい著者',
      finished_date: '2025-01-15',
      publisher: '新しい出版社',
      isbn: '1234567890125',
      price: 2000,
      rating: 7
    }
  end

  def teardown
    File.delete(@test_data_file) if File.exist?(@test_data_file)
    JsonDataStore.const_set(:DATA_FILE, @original_data_file)
  end

  test "should get index" do
    get books_url
    assert_response :success
    assert_select 'h1', text: '蔵書管理システム'
    assert_select '.book-card', count: 2
    assert_select 'a', text: 'テスト書籍1'
    assert_select 'a', text: 'テスト書籍2'
  end

  test "should show book" do
    get book_url(1)
    assert_response :success
    assert_select 'h1', text: 'テスト書籍1'
    assert_select 'span', text: 'テスト著者1'
    assert_select 'span', text: 'テスト出版社'
  end

  test "should redirect when book not found" do
    get book_url(999)
    assert_redirected_to books_path
    follow_redirect!
    assert_select '.alert', text: /書籍が見つかりませんでした。/
  end

  test "should get new" do
    get new_book_url
    assert_response :success
    assert_select 'h1', text: '新しい本を追加'
    assert_select 'form'
    assert_select 'input[name="book[title]"]'
    assert_select 'input[name="book[author]"]'
  end

  test "should create book with valid params" do
    assert_difference('Book.all.count') do
      post books_url, params: { book: @valid_book_params }
    end

    assert_redirected_to book_path(3)  # 新しいIDは3になる
    follow_redirect!
    assert_select 'h1', text: '新しい書籍'
    assert_select '.notice', text: /書籍が正常に作成されました。/
  end

  test "should not create book with invalid params" do
    invalid_params = @valid_book_params.merge(title: '')
    
    assert_no_difference('Book.all.count') do
      post books_url, params: { book: invalid_params }
    end

    assert_response :unprocessable_entity
    assert_select '.error-messages'
  end

  test "should get edit" do
    get edit_book_url(1)
    assert_response :success
    assert_select 'h1', text: /テスト書籍1を編集/
    assert_select 'form'
    assert_select 'input[value="テスト書籍1"]'
    assert_select 'input[value="テスト著者1"]'
  end

  test "should update book with valid params" do
    patch book_url(1), params: { book: { title: '更新された書籍', author: '更新された著者' } }
    
    assert_redirected_to book_path(1)
    follow_redirect!
    assert_select 'h1', text: '更新された書籍'
    assert_select 'span', text: '更新された著者'
    assert_select '.notice', text: /書籍が正常に更新されました。/
  end

  test "should not update book with invalid params" do
    patch book_url(1), params: { book: { title: '', author: 'テスト著者' } }
    
    assert_response :unprocessable_entity
    assert_select '.error-messages'
  end

  test "should destroy book" do
    assert_difference('Book.all.count', -1) do
      delete book_url(1)
    end

    assert_redirected_to books_path
    follow_redirect!
    assert_select '.notice', text: /書籍が正常に削除されました。/
    
    # 削除された書籍が表示されていないことを確認
    assert_select '.book-card', count: 1
    assert_select 'a', text: 'テスト書籍2'
  end

  test "root path should redirect to books index" do
    get root_url
    assert_response :success
    assert_select 'h1', text: '蔵書管理システム'
  end

  test "index should handle empty book list" do
    # 全ての書籍を削除
    JsonDataStore.write_data({ 'books' => [] })
    
    get books_url
    assert_response :success
    assert_select '.no-books'
    assert_select 'p', text: 'まだ本が登録されていません。'
  end

  test "index should display search and sort elements" do
    get books_url
    assert_response :success
    assert_select 'input#search'
    assert_select 'select#sort'
    assert_select 'option[value="title"]', text: '書籍名順'
    assert_select 'option[value="author"]', text: '著者名順'
  end

  test "show should display all book information" do
    get book_url(1)
    assert_response :success
    
    # 基本情報の表示確認
    assert_select '.info-row', text: /著者:/
    assert_select '.info-row', text: /出版社:/
    assert_select '.info-row', text: /読了日:/
    assert_select '.info-row', text: /ISBN:/
    assert_select '.info-row', text: /価格:/
    assert_select '.info-row', text: /評価:/
    
    # 星評価の表示確認
    assert_select '.stars[data-rating="8"]'
  end

  test "form should include all required fields" do
    get new_book_url
    assert_response :success
    
    assert_select 'input[name="book[title]"][required]'
    assert_select 'input[name="book[author]"][required]'
    assert_select 'input[name="book[finished_date]"][required]'
    assert_select 'input[name="book[publisher]"]'
    assert_select 'input[name="book[isbn]"]'
    assert_select 'input[name="book[price]"]'
    assert_select 'input[name="book[rating]"]'
  end

  test "edit form should populate with existing data" do
    get edit_book_url(1)
    assert_response :success
    
    assert_select 'input[name="book[title]"][value="テスト書籍1"]'
    assert_select 'input[name="book[author]"][value="テスト著者1"]'
    assert_select 'input[name="book[finished_date]"][value="2025-01-01"]'
    assert_select 'input[name="book[publisher]"][value="テスト出版社"]'
    assert_select 'input[name="book[isbn]"][value="1234567890123"]'
    assert_select 'input[name="book[price]"][value="1000"]'
  end
end