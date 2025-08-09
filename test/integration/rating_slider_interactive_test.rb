require 'test_helper'

class RatingSliderInteractiveTest < ActionDispatch::IntegrationTest
  def setup
    @test_data_file = Rails.root.join('test', 'fixtures', "rating_slider_interactive_#{SecureRandom.hex(8)}.json")
    @original_data_file = JsonDataStore::DATA_FILE
    JsonDataStore.const_set(:DATA_FILE, @test_data_file)
    
    # テストデータの準備
    @test_data = {
      'books' => [
        {
          'id' => 1,
          'title' => 'スライダーテスト書籍',
          'author' => 'テスト著者',
          'finished_date' => '2025-01-01',
          'publisher' => 'テスト出版社',
          'isbn' => '1234567890123',
          'price' => 1000,
          'rating' => 7
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

  test "new book form should have proper rating slider structure" do
    get new_book_path
    assert_response :success
    
    # スライダー要素の確認
    assert_select 'input[type="range"]#rating-input' do |elements|
      element = elements.first
      assert_equal '1', element['min']
      assert_equal '10', element['max']
      assert_equal '1', element['step']
      assert_equal '5', element['value']  # デフォルト値
    end
    
    # 表示要素の確認
    assert_select '#rating-value', text: '5'
    assert_select '#rating-stars.stars'
    
    # レーティング入力エリアの構造確認
    assert_select '.rating-input' do
      assert_select '.rating-display'
    end
  end

  test "edit book form should have proper rating slider with existing value" do
    get edit_book_path(1)
    assert_response :success
    
    # 既存の評価値が設定されていることを確認
    assert_select 'input[type="range"]#rating-input[value="7"]'
    assert_select '#rating-value', text: '7'
    assert_select '#rating-stars.stars'
  end

  test "rating slider javascript should be present in forms" do
    get new_book_path
    assert_response :success
    
    # 必要なJavaScript関数とイベントリスナーが含まれていることを確認
    assert_match /updateRatingDisplay/, response.body
    assert_match /addEventListener\(.*input/, response.body
    assert_match /addEventListener\(.*change/, response.body
    assert_match /addEventListener\(.*mousemove/, response.body
    
    # 色分け機能の確認
    assert_match /#ff6b35.*オレンジ.*高評価/, response.body
    assert_match /#ffc107.*黄色.*中評価/, response.body
    assert_match /#6c757d.*グレー.*低評価/, response.body
  end

  test "rating update should work properly" do
    # 評価を変更してフォームを送信
    patch book_path(1), params: { book: {
      title: 'スライダーテスト書籍',
      author: 'テスト著者',
      finished_date: '2025-01-01',
      rating: 3  # 7から3に変更
    }}
    
    assert_redirected_to book_path(1)
    
    # 更新後の値を確認
    updated_book = JsonDataStore.find_book(1)
    assert_equal 3, updated_book['rating']
    
    # 編集フォームで正しい値が表示されることを確認
    get edit_book_path(1)
    assert_select 'input[type="range"]#rating-input[value="3"]'
    assert_select '#rating-value', text: '3'
  end

  test "rating extremes should work correctly" do
    # 最低評価（1）でテスト
    patch book_path(1), params: { book: {
      title: 'スライダーテスト書籍',
      author: 'テスト著者', 
      finished_date: '2025-01-01',
      rating: 1
    }}
    
    updated_book = JsonDataStore.find_book(1)
    assert_equal 1, updated_book['rating']
    
    # 最高評価（10）でテスト
    patch book_path(1), params: { book: {
      rating: 10
    }}
    
    updated_book = JsonDataStore.find_book(1)
    assert_equal 10, updated_book['rating']
  end

  test "form css classes should be properly applied" do
    get new_book_path
    assert_response :success
    
    # CSSクラスの確認
    assert_select '.rating-input'
    assert_select '.rating-display'
    assert_select '.form-range'
    assert_select '.stars'
    
    # フォームの構造確認
    assert_select '.book-form .form-group' do |elements|
      rating_group = elements.find { |el| el.to_s.include?('rating') }
      assert_not_nil rating_group, "評価入力グループが見つかりません"
    end
  end

  test "validation should still work with slider" do
    # 無効な評価値でテスト（範囲外）
    post books_path, params: { book: {
      title: '新しいテスト書籍',
      author: 'テスト著者',
      finished_date: '2025-02-01',
      rating: 15  # 範囲外の値
    }}
    
    # バリデーションエラーが発生することを確認
    assert_response :unprocessable_content
    assert_select '.error-messages'
  end
end