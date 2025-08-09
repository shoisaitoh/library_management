class BooksController < ApplicationController
  before_action :set_book, only: [:show, :edit, :update, :destroy]

  def index
    @books = Book.all
  end

  def show
  end

  def new
    @book = Book.new
  end

  def edit
  end

  def create
    @book = Book.new(book_params)

    if @book.save
      redirect_to @book, notice: '書籍が正常に作成されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @book.update(book_params)
      redirect_to @book, notice: '書籍が正常に更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to books_path, notice: '書籍が正常に削除されました。'
  end

  private

  def set_book
    @book = Book.find(params[:id])
    redirect_to books_path, alert: '書籍が見つかりませんでした。' unless @book
  end

  def book_params
    params.require(:book).permit(:title, :author, :finished_date, :publisher, :isbn, :price, :rating)
  end
end