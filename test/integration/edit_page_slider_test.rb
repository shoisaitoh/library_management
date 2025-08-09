require 'test_helper'

class EditPageSliderTest < ActionDispatch::IntegrationTest
  def setup
    @test_data_file = Rails.root.join('test', 'fixtures', "edit_slider_#{SecureRandom.hex(8)}.json")
    @original_data_file = JsonDataStore::DATA_FILE
    JsonDataStore.const_set(:DATA_FILE, @test_data_file)
    
    # テストデータの準備
    @test_data = {
      'books' => [
        {
          'id' => 1,
          'title' => '編集テスト書籍1',
          'author' => 'テスト著者1',
          'finished_date' => '2025-01-01',
          'publisher' => 'テスト出版社1',
          'isbn' => '1234567890123',
          'price' => 1000,
          'rating' => 7
        },
        {
          'id' => 2,
          'title' => '編集テスト書籍2',
          'author' => 'テスト著者2',
          'finished_date' => '2025-01-02',
          'publisher' => 'テスト出版社2',
          'isbn' => '1234567890124',
          'price' => 1200,
          'rating' => 9
        },
        {
          'id' => 3,
          'title' => '編集テスト書籍3',
          'author' => 'テスト著者3',
          'finished_date' => '2025-01-03',
          'publisher' => 'テスト出版社3',
          'isbn' => '1234567890125',
          'price' => 800,
          'rating' => 3
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

  test "edit page should have proper rating slider structure with existing value" do
    get edit_book_path(1)
    assert_response :success
    
    # スライダー要素の確認
    assert_select 'input[type="range"]#rating-input' do |elements|
      element = elements.first
      assert_equal '1', element['min']
      assert_equal '10', element['max']
      assert_equal '1', element['step']
      assert_equal '7', element['value']  # 既存の評価値
    end
    
    # 表示要素の確認
    assert_select '#rating-value', text: '7'
    assert_select '#rating-stars.stars'
    
    # レーティング入力エリアの構造確認
    assert_select '.rating-input' do
      assert_select '.rating-display'
    end
  end

  test "edit page should have enhanced rating slider initialization" do
    get edit_book_path(2)
    assert_response :success
    
    # 強化されたJavaScript初期化機能の確認
    assert_match /function initializeRatingSlider/, response.body
    assert_match /addEventListener.*DOMContentLoaded.*initializeRatingSlider/, response.body
    assert_match /addEventListener.*load.*initializeRatingSlider/, response.body
    assert_match /addEventListener.*pageshow.*initializeRatingSlider/, response.body
    
    # イベントハンドラーの重複防止機能の確認
    assert_match /removeEventListener/, response.body
    assert_match /_inputHandler/, response.body
    assert_match /_changeHandler/, response.body
    assert_match /_mousemoveHandler/, response.body
  end

  test "edit page should handle different rating values correctly" do
    # 高評価の書籍をテスト
    get edit_book_path(2)
    assert_response :success
    assert_select 'input[type="range"]#rating-input[value="9"]'
    assert_select '#rating-value', text: '9'
    
    # 中評価の書籍をテスト
    get edit_book_path(1)
    assert_response :success
    assert_select 'input[type="range"]#rating-input[value="7"]'
    assert_select '#rating-value', text: '7'
    
    # 低評価の書籍をテスト
    get edit_book_path(3)
    assert_response :success
    assert_select 'input[type="range"]#rating-input[value="3"]'
    assert_select '#rating-value', text: '3'
  end

  test "edit page should have color-coded star display logic" do
    get edit_book_path(1)
    assert_response :success
    
    # 色分けロジックがJavaScriptに含まれていることを確認
    assert_match /#ff6b35.*オレンジ.*高評価/, response.body
    assert_match /#ffc107.*黄色.*中評価/, response.body
    assert_match /#6c757d.*グレー.*低評価/, response.body
  end

  test "edit page should have proper form validation" do
    get edit_book_path(1)
    assert_response :success
    
    # フォームバリデーションが含まれていることを確認
    assert_match /form\.addEventListener.*submit/, response.body
    assert_match /必須項目を入力してください/, response.body
    assert_match /ISBNは13文字以下で入力してください/, response.body
    assert_match /価格は0以上の値を入力してください/, response.body
  end

  test "edit page should be accessible without javascript errors" do
    # 各評価レベルの編集ページが正常にレンダリングされることを確認
    [1, 2, 3].each do |book_id|
      get edit_book_path(book_id)
      assert_response :success
      
      # 必要な要素が全て存在することを確認
      assert_select '#rating-input'
      assert_select '#rating-value'
      assert_select '#rating-stars'
      assert_select '.rating-display'
      assert_select '.rating-input'
    end
  end

  test "edit form should maintain slider functionality after page transitions" do
    # 詳細ページから編集ページへの遷移
    get book_path(1)
    assert_response :success
    
    get edit_book_path(1)
    assert_response :success
    
    # スライダーの構造が正しく設定されていることを確認
    assert_select 'input[type="range"]#rating-input[value="7"]'
    assert_select '#rating-value', text: '7'
    assert_select '#rating-stars.stars'
    
    # JavaScript初期化関数が含まれていることを確認
    assert_match /initializeRatingSlider/, response.body
  end

  test "edit page should handle edge case ratings" do
    # 最低評価のテスト（rating=1に変更）
    @test_data['books'][0]['rating'] = 1
    JsonDataStore.write_data(@test_data)
    
    get edit_book_path(1)
    assert_response :success
    assert_select 'input[type="range"]#rating-input[value="1"]'
    assert_select '#rating-value', text: '1'
    
    # 最高評価のテスト（rating=10に変更）
    @test_data['books'][0]['rating'] = 10
    JsonDataStore.write_data(@test_data)
    
    get edit_book_path(1)
    assert_response :success
    assert_select 'input[type="range"]#rating-input[value="10"]'
    assert_select '#rating-value', text: '10'
  end

  test "edit page JavaScript should be robust against multiple initializations" do
    get edit_book_path(1)
    assert_response :success
    
    # イベントリスナーの重複防止機能が実装されていることを確認
    response_body = response.body
    assert_includes response_body, 'removeEventListener'
    assert_includes response_body, '_inputHandler'
    assert_includes response_body, '_changeHandler'
    assert_includes response_body, '_mousemoveHandler'
    
    # 複数のタイミングでの初期化が設定されていることを確認
    initialization_count = response_body.scan(/initializeRatingSlider/).length
    assert_operator initialization_count, :>=, 3  # DOMContentLoaded, load, pageshow
  end

  test "edit page should update correctly after form submission" do
    # 編集フォームを送信
    patch book_path(1), params: { book: {
      title: '編集テスト書籍1',
      author: 'テスト著者1',
      finished_date: '2025-01-01',
      rating: 8  # 7から8に変更
    }}
    
    assert_redirected_to book_path(1)
    
    # 更新後の値を確認
    updated_book = JsonDataStore.find_book(1)
    assert_equal 8, updated_book['rating']
    
    # 編集フォームで正しい値が表示されることを確認
    get edit_book_path(1)
    assert_select 'input[type="range"]#rating-input[value="8"]'
    assert_select '#rating-value', text: '8'
  end
end