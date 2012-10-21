require 'yaml'
require 'crc32.rb'

# Хранилище информации о файлах
class Storage
  Info = Struct.new(:mtime, :size, :crc)

  attr_reader :files        # { file_path => file_info, .. }
  attr_writer :is_changed
  attr_reader :db_file

  def initialize(db_file)
    @files = {}
    @db_file = db_file
    @is_changed = false
    load
  end

  # Вычислить уникальный код
  def get_digest(file)
    path_name = file.realpath.to_s
    @files[path_name] ||= Info.new

    stored = @files[path_name]
    if stored.size == file.size && stored.mtime == file.mtime
      return stored.crc
    end
    @is_changed = true

    stored.mtime = file.mtime
    stored.size = file.size
    stored.crc = block_crc32 file

    stored.crc
  end

  def load
    @is_changed = false
    @files = YAML.load_file @db_file
    puts "Storage.loaded: #{@files.count}"
  rescue
    @files = {}
  end

  def save
    if @is_changed
      File.open( @db_file, 'w' ) do |out|
        YAML.dump( @files, out )
      end
      puts "Storage.saved: #{@files.count}"
    end
  end

end
