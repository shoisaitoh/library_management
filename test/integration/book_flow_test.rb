require 'test_helper'

class BookFlowTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers
  def setup
    @test_data_file = Rails.root.join('test', 'fixtures', 'integration_test_books.json')
    @original_data_file = JsonDataStore::DATA_FILE
    JsonDataStore.const_set(:DATA_FILE, @test_data_file)
    
    # テストデータの準備
    @test_data = {
      'books' => [
        {
          'id' => 1,
          'title' => '既存の書籍',
          'author' => '既存の著者',
          'finished_date' => '2025-01-01',
          'publisher' => '既存の出版社',
          'isbn' => '1234567890123',
          'price' => 1000,
          'rating' => 8
        }
      ]
    }
    
    FileUtils.mkdir_p(File.dirname(@test_data_file))
    JsonDataStore.write_data(@test_data)
  end

  def teardown
    File.delete(@test_data_file) if File.exist?(@test_data_file)
    JsonDataStore.const_set(:DATA_FILE, @original_data_file)
  end

  test "complete book management workflow" do
    # 1. ホームページにアクセス
    get root_path
    assert_response :success
    assert_select 'h1', text: '蔵書管理システム'
    assert_select '.book-card', count: 1

    # 2. 新しい書籍追加
    post books_path, params: { book: {
      title: '統合テスト書籍',
      author: '統合テスト著者',
      finished_date: '2025-02-01',
      publisher: '統合テスト出版社',
      isbn: '9876543210987',
      price: 2500,
      rating: 7
    }}

    # 3. 作成成功後、詳細ページに移動
    assert_redirected_to book_path(2)
    follow_redirect!
    assert_select 'h1', text: '統合テスト書籍'

    # 4. 書籍を更新
    patch book_path(2), params: { book: {
      title: '更新された統合テスト書籍',
      author: '更新された統合テスト著者'
    }}

    # 5. 更新成功後、詳細ページで確認
    assert_redirected_to book_path(2)
    follow_redirect!
    assert_select 'h1', text: '更新された統合テスト書籍'

    # 6. 書籍を削除
    delete book_path(2)

    # 7. 削除成功を確認
    assert_redirected_to books_path
    follow_redirect!
    assert_select '.book-card', count: 1
  end

  test "book validation errors are properly handled" do
    # 必須項目を空で送信
    post books_path, params: { book: { title: '', author: '' } }

    # エラーメッセージが表示されることを確認
    assert_response :unprocessable_content
    assert_select '.error-messages'

    # 有効なデータで再送信
    post books_path, params: { book: {
      title: '有効な書籍名',
      author: '有効な著者名',
      finished_date: '2025-02-01'
    }}

    # 成功することを確認
    assert_redirected_to book_path(2)
  end

  test "empty book list shows appropriate message" do
    # 全ての書籍を削除
    JsonDataStore.write_data({ 'books' => [] })

    # 一覧ページにアクセス
    get books_path
    assert_response :success

    # 空のメッセージが表示されることを確認
    assert_select '.no-books'
    assert_select '.no-books p', text: 'まだ本が登録されていません。'
    assert_select '.no-books a', text: '最初の本を追加する'
  end

  test "book detail page displays all information correctly" do
    # 詳細ページにアクセス
    get book_path(1)
    assert_response :success

    # 基本情報が表示されることを確認
    assert_select 'h1', text: '既存の書籍'
    assert_select '.info-row'
    assert_select 'a', text: '編集'
    assert_select 'a', text: '削除'
    assert_select 'a', text: '一覧に戻る'
  end
end