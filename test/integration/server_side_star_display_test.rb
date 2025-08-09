require 'test_helper'

class ServerSideStarDisplayTest < ActionDispatch::IntegrationTest
  def setup
    @test_data_file = Rails.root.join('test', 'fixtures', "server_side_star_#{SecureRandom.hex(8)}.json")
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

  test "index page should render stars directly in HTML with correct colors" do
    get books_path
    assert_response :success
    
    # 高評価（9点）の星表示とオレンジ色の確認
    assert_select 'span.stars[data-rating="9"]' do |elements|
      element = elements.first
      assert_equal '★★★★★★★★★☆', element.text
      assert_match /#ff6b35/, element['style']
    end
    
    # 中評価（7点）の星表示と黄色の確認
    assert_select 'span.stars[data-rating="7"]' do |elements|
      element = elements.first
      assert_equal '★★★★★★★☆☆☆', element.text
      assert_match /#ffc107/, element['style']
    end
    
    # 低評価（3点）の星表示とグレー色の確認
    assert_select 'span.stars[data-rating="3"]' do |elements|
      element = elements.first
      assert_equal '★★★☆☆☆☆☆☆☆', element.text
      assert_match /#6c757d/, element['style']
    end
  end

  test "show page should render stars directly in HTML with correct colors" do
    get book_path(1)
    assert_response :success
    
    # 高評価（9点）の星表示とオレンジ色の確認
    assert_select 'span.stars[data-rating="9"]' do |elements|
      element = elements.first
      assert_equal '★★★★★★★★★☆', element.text
      assert_match /#ff6b35/, element['style']
    end
    
    # 評価値も表示されていることを確認
    assert_select 'span.rating-display' do
      assert_select 'span.stars'
      assert_match /\(9\/10\)/, response.body
    end
  end

  test "different rating levels should have correct colors and star counts" do
    # 高評価のテスト
    get book_path(1)
    assert_response :success
    assert_match /★★★★★★★★★☆/, response.body
    assert_match /#ff6b35/, response.body
    
    # 中評価のテスト
    get book_path(2)
    assert_response :success
    assert_match /★★★★★★★☆☆☆/, response.body
    assert_match /#ffc107/, response.body
    
    # 低評価のテスト
    get book_path(3)
    assert_response :success
    assert_match /★★★☆☆☆☆☆☆☆/, response.body
    assert_match /#6c757d/, response.body
  end

  test "page navigation should maintain consistent star display" do
    # 一覧ページから開始
    get books_path
    assert_response :success
    assert_match /★★★★★★★★★☆/, response.body  # 9点の書籍
    assert_match /#ff6b35/, response.body
    
    # 詳細ページに遷移
    get book_path(1)
    assert_response :success
    assert_match /★★★★★★★★★☆/, response.body
    assert_match /#ff6b35/, response.body
    
    # 再び一覧に戻る
    get books_path
    assert_response :success
    assert_match /★★★★★★★★★☆/, response.body
    assert_match /#ff6b35/, response.body
  end

  test "no javascript dependencies for star display" do
    get books_path
    assert_response :success
    
    # JavaScript関数が存在しないことを確認（サーバーサイドレンダリング）
    assert_no_match /function displayStars/, response.body
    assert_no_match /MutationObserver/, response.body
    assert_no_match /addEventListener.*pageshow/, response.body
    
    # しかし星は直接HTMLに含まれている
    assert_match /★★★★★★★★★☆/, response.body
    assert_match /★★★★★★★☆☆☆/, response.body
    assert_match /★★★☆☆☆☆☆☆☆/, response.body
  end

  test "star display works immediately on page load" do
    # 任意のページにアクセスした時点で星が表示される
    get books_path
    assert_response :success
    
    # レスポンス本体に直接星文字が含まれていることを確認
    response_html = response.body
    assert_includes response_html, '★★★★★★★★★☆'
    assert_includes response_html, '★★★★★★★☆☆☆' 
    assert_includes response_html, '★★★☆☆☆☆☆☆☆'
    
    # 色の指定も含まれていることを確認
    assert_includes response_html, '#ff6b35'
    assert_includes response_html, '#ffc107'
    assert_includes response_html, '#6c757d'
  end

  test "rating color calculation works correctly" do
    get books_path
    assert_response :success
    
    # HTMLに正しい色のスタイルが適用されていることを確認
    assert_select 'span.stars[data-rating="9"][style*="#ff6b35"]'  # 高評価：オレンジ
    assert_select 'span.stars[data-rating="7"][style*="#ffc107"]'  # 中評価：黄色
    assert_select 'span.stars[data-rating="3"][style*="#6c757d"]'  # 低評価：グレー
  end

  test "comprehensive page flow maintains server-side star rendering" do
    # 一覧 → 詳細 → 編集 → 詳細 → 一覧の流れでテスト
    
    # 1. 一覧ページ
    get books_path
    assert_response :success
    assert_match /★★★★★★★★★☆/, response.body
    
    # 2. 詳細ページ
    get book_path(1)
    assert_response :success
    assert_match /★★★★★★★★★☆/, response.body
    
    # 3. 編集ページ（スライダーがある）
    get edit_book_path(1)
    assert_response :success
    assert_select '#rating-input[value="9"]'
    
    # 4. 詳細ページに戻る
    get book_path(1)
    assert_response :success
    assert_match /★★★★★★★★★☆/, response.body
    
    # 5. 一覧ページに戻る
    get books_path
    assert_response :success
    assert_match /★★★★★★★★★☆/, response.body
  end
end