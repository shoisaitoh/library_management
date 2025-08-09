# CLAUDE.md

すべて日本語で回答してください。
このアプリは、私の蔵書を管理するためのWebアプリケーションです。
Ruby on Railsで、JSONファイルをデータストアとして利用する蔵書管理アプリです。
Railsのバージョンは8です。
Rubyのバージョンは3.3.0です。

JSONファイルのサンプルは下記の通りです。

```json
{
  "books": [
    {
      "title": "吾輩は猫である",
      "author": "夏目漱石",
      "finished_date": "2025-08-01",
      "publisher": "春陽堂",
      "isbn": "9784394101019",
      "price": 500,
      "rating": 9
    },
    {
      "title": "走れメロス",
      "author": "太宰治",
      "finished_date": "2025-08-05",
      "publisher": "小峰書店",
      "isbn": "9784338089201",
      "price": 800,
      "rating": 8
    }
  ]
}
```

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a library management system project. The codebase is currently empty and ready for initial development.

## 開発環境のセットアップ

このプロジェクトはRuby on Rails 8を使用した蔵書管理システムです。JSONファイルをデータストアとして利用します。

### 必要な環境
- Ruby 3.3.0
- Rails 8
- bundler

### セットアップ手順
```bash
bundle install
```

## 共通開発コマンド

### 開発用サーバーの起動
```bash
rails server
# または
bin/dev
```

### テスト実行
```bash
# 全テストの実行
rails test

# 特定のテストファイルの実行
rails test test/services/json_data_store_test.rb
rails test test/models/book_test.rb
rails test test/controllers/books_controller_test.rb
rails test test/integration/book_flow_test.rb
```

### リンターとフォーマッター
```bash
bin/rubocop
```

### データファイル
JSONデータは `db/books.json` に保存されます。アプリケーションの初回実行時にサンプルデータが作成されます。

### テストについて
テストファイルは以下のような構成になっています：

- `test/services/json_data_store_test.rb` - JSONファイル操作のテスト
- `test/models/book_test.rb` - Bookモデルのバリデーションや操作のテスト
- `test/controllers/books_controller_test.rb` - コントローラーのテスト
- `test/integration/book_flow_test.rb` - 統合テスト

テストは独立したテストデータを使用するため、本番データに影響しません。

## アーキテクチャー

この蔵書管理システムは以下の構成になっています：

### コア機能
- 書籍のCRUD操作（作成、読み取り、更新、削除）
- 検索・フィルタリング機能（書籍名、著者名）
- ソート機能（書籍名、著者名、読了日、評価順）
- 評価システム（1-10段階）

### 主要なファイル構成

#### Models
- `app/models/book.rb` - Bookモデル（ActiveModelを使用）
- `app/services/json_data_store.rb` - JSONファイル操作用サービス

#### Controllers  
- `app/controllers/books_controller.rb` - 書籍のCRUD操作

#### Views
- `app/views/books/` - 書籍関連のビューファイル
- `app/views/layouts/application.html.erb` - レイアウトファイル

#### Data Storage
- `db/books.json` - 書籍データの保存先

### フロントエンド機能
- リアルタイム検索（JavaScript）
- 動的ソート機能
- レスポンシブデザイン
- 星評価表示システム
- インタラクティブな評価スライダー（1-10段階、リアルタイム更新）
  - スライダーを動かすと連動して星の数と色が変化
  - 評価レベルに応じた色分け（高評価：オレンジ、中評価：黄色、低評価：グレー）

### データ形式
```json
{
  "books": [
    {
      "id": 1,
      "title": "書籍名",
      "author": "著者名",
      "finished_date": "2025-08-01",
      "publisher": "出版社",
      "isbn": "ISBN番号",
      "price": 価格,
      "rating": 評価（1-10）
    }
  ]
}
```