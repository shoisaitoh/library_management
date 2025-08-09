class JsonDataStore
  DATA_FILE = Rails.root.join('db', 'books.json')

  def self.read_data
    return { 'books' => [] } unless File.exist?(DATA_FILE)

    begin
      JSON.parse(File.read(DATA_FILE))
    rescue JSON::ParserError
      { 'books' => [] }
    end
  end

  def self.write_data(data)
    FileUtils.mkdir_p(File.dirname(DATA_FILE))
    File.write(DATA_FILE, JSON.pretty_generate(data))
  end

  def self.all_books
    read_data['books'] || []
  end

  def self.find_book(id)
    all_books.find { |book| book['id'] == id.to_i }
  end

  def self.add_book(book_data)
    data = read_data
    data['books'] ||= []
    
    # IDを自動生成
    next_id = data['books'].empty? ? 1 : data['books'].max_by { |book| book['id'] }['id'] + 1
    book_data['id'] = next_id
    
    data['books'] << book_data
    write_data(data)
    book_data
  end

  def self.update_book(id, book_data)
    data = read_data
    book_index = data['books'].find_index { |book| book['id'] == id.to_i }
    
    return nil unless book_index

    book_data['id'] = id.to_i
    data['books'][book_index] = book_data
    write_data(data)
    book_data
  end

  def self.delete_book(id)
    data = read_data
    deleted_book = data['books'].reject! { |book| book['id'] == id.to_i }
    
    if deleted_book
      write_data(data)
      true
    else
      false
    end
  end
end