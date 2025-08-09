require 'test_helper'

class StarDisplayNavigationTest < ActionDispatch::IntegrationTest
  def setup
    @test_data_file = Rails.root.join('test', 'fixtures', "star_display_#{SecureRandom.hex(8)}.json")
    @original_data_file = JsonDataStore::DATA_FILE
    JsonDataStore.const_set(:DATA_FILE, @test_data_file)
    
    # テストデータの準備
    @test_data = {
      'books' => [
        {
          'id' => 1,
          'title' => '高評価テスト書籍',
          'author' => 'テスト著者1',
          'finished_date' => '2025-01-01',
          'publisher' => 'テスト出版社1',
          'isbn' => '1234567890123',
          'price' => 1000,
          'rating' => 9  # 高評価（オレンジ色）
        },
        {
          'id' => 2,
          'title' => '中評価テスト書籍',
          'author' => 'テスト著者2',
          'finished_date' => '2025-01-02',
          'publisher' => 'テスト出版社2',
          'isbn' => '1234567890124',
          'price' => 1200,
          'rating' => 7  # 中評価（黄色）
        },
        {
          'id' => 3,
          'title' => '低評価テスト書籍',
          'author' => 'テスト著者3',
          'finished_date' => '2025-01-03',
          'publisher' => 'テスト出版社3',
          'isbn' => '1234567890125',
          'price' => 800,
          'rating' => 3  # 低評価（グレー）
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

  test "index page should have stars with proper structure" do
    get books_path
    assert_response :success
    
    # 星表示要素が存在することを確認
    assert_select '.stars[data-rating="9"]'
    assert_select '.stars[data-rating="7"]'
    assert_select '.stars[data-rating="3"]'
    
    # JavaScript関数とイベントリスナーが含まれていることを確認
    assert_match /function displayStars/, response.body
    assert_match /addEventListener.*pageshow/, response.body
    assert_match /addEventListener.*focus/, response.body
    assert_match /addEventListener.*visibilitychange/, response.body
    assert_match /MutationObserver/, response.body
  end

  test "show page should have stars with proper structure and events" do
    get book_path(1)
    assert_response :success
    
    # 星表示要素が存在することを確認
    assert_select '.stars[data-rating="9"]'
    
    # JavaScript関数とイベントリスナーが含まれていることを確認
    assert_match /function displayStars/, response.body
    assert_match /addEventListener.*pageshow/, response.body
    assert_match /addEventListener.*focus/, response.body
    assert_match /addEventListener.*visibilitychange/, response.body
  end

  test "navigation from index to show page should maintain star display structure" do
    # まず一覧ページにアクセス
    get books_path
    assert_response :success
    assert_select '.stars[data-rating]'
    
    # 詳細ページにアクセス
    get book_path(1)
    assert_response :success
    assert_select '.stars[data-rating="9"]'
    
    # 詳細ページに必要なJavaScriptが含まれていることを確認
    assert_match /function displayStars/, response.body
  end

  test "navigation from show page back to index should maintain star display structure" do
    # まず詳細ページにアクセス
    get book_path(2)
    assert_response :success
    assert_select '.stars[data-rating="7"]'
    
    # 一覧ページに戻る
    get books_path
    assert_response :success
    assert_select '.stars[data-rating]'
    
    # 一覧ページに必要なJavaScriptが含まれていることを確認
    assert_match /MutationObserver/, response.body
  end

  test "edit page navigation should preserve star functionality" do
    # 編集ページにアクセス
    get edit_book_path(1)
    assert_response :success
    
    # レーティングスライダーとJavaScriptが含まれていることを確認
    assert_select '#rating-input'
    assert_select '#rating-stars.stars'
    assert_match /updateRatingDisplay/, response.body
    
    # 詳細ページに戻る
    get book_path(1)
    assert_response :success
    assert_select '.stars[data-rating="9"]'
  end

  test "star display works with different rating values" do
    # 高評価のテスト
    get book_path(1)
    assert_response :success
    assert_select '.stars[data-rating="9"]'
    assert_match /#ff6b35.*オレンジ.*高評価/, response.body
    
    # 中評価のテスト
    get book_path(2)
    assert_response :success
    assert_select '.stars[data-rating="7"]'
    assert_match /#ffc107.*黄色.*中評価/, response.body
    
    # 低評価のテスト
    get book_path(3)
    assert_response :success
    assert_select '.stars[data-rating="3"]'
    assert_match /#6c757d.*グレー.*低評価/, response.body
  end

  test "star duplication prevention logic should work" do
    get book_path(1)
    assert_response :success
    
    # 重複防止のロジックが含まれていることを確認
    assert_match /!stars\.textContent\.includes.*★/, response.body
  end

  test "mutation observer should be properly configured for dynamic content" do
    get books_path
    assert_response :success
    
    # MutationObserverの設定が正しく含まれていることを確認
    assert_match /observer\.observe\(document\.body/, response.body
    assert_match /childList: true/, response.body
    assert_match /subtree: true/, response.body
    assert_match /node\.classList\.contains.*stars/, response.body
  end

  test "comprehensive page flow maintains star display" do
    # 一覧ページから開始
    get books_path
    assert_response :success
    assert_select '.book-card', 3
    
    # 最初の書籍の詳細ページへ
    get book_path(1)
    assert_response :success
    assert_select '.stars[data-rating="9"]'
    
    # 編集ページへ
    get edit_book_path(1)
    assert_response :success
    assert_select '#rating-input[value="9"]'
    
    # 詳細ページに戻る
    get book_path(1)
    assert_response :success
    assert_select '.stars[data-rating="9"]'
    
    # 一覧ページに戻る
    get books_path
    assert_response :success
    assert_select '.stars[data-rating]', 3
  end
end