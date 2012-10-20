require 'find'
require 'crc32.rb'

# Поиск одинаковых файлов
class Finder
  def initialize(storage = nil)
    @storage = storage
  end

  # Delete duplicate files from folder
  #
  # :main_folder Main folder
  # :clean_folder Folder to clean
  # :action - :pretend no delete, :delete real
  def clean_folder(params)
    params[:action] ||= :pretend
    if params[:main_folder] && params[:clean_folder]
      self.compare(params[:main_folder], params[:clean_folder]) do |files1, files2|
        pp files1#, files2


        # Remove all duplicates
        files2.each do |dup_file|
          puts "\t#{dup_file}"
          if params[:action] == :delete
            File.delete dup_file
            puts "\t\tdeleted"
          end
        end

        puts '------------------------'
      end
    end
  end

  # Сравнить два каталога
  def compare(folder1, folder2)
    pp "Finder#compare(#{folder1}, #{folder2})"
    by_size1 = group_by_size list(folder1)
    by_size2 = group_by_size list(folder2)

    find_by_size(by_size1, by_size2) do |list1, list2|
      find_by_content(list1, list2) do |files1, files2|
        yield files1, files2
      end
    end
  end

  # Поиск дубликатов в каталогах
  def run(folder_list)
    unless folder_list.is_a? Enumerable
      folder_list = [folder_list]
    end

    all_files = []
    folder_list.each do |folder|
      if File.exist?(folder)
        list(folder, all_files)
      else
        puts "Folder not exist: #{folder}"
      end
    end
    by_size = group_by_size(all_files)

    by_size.each do |size, same_size_files|
      if same_size_files.count > 1
        by_digest = same_size_files.group_by { |file| get_digest file }
        by_digest.each do |digest, same_digest_files|
          yield same_digest_files if same_digest_files.count > 1
        end
      end
    end
  end

  # Список файлов каталога
  def list(folder, all = [])
    Find.find(folder) do |path|
      path = Pathname.new path
      if path.file?
        all << path
      end
    end

    all
  end

  # Группировать список по размерам файлов
  def group_by_size(all)
    all.group_by do |file|
      file.size
    end
  end

  # Сравнить два списка группированных по размерам
  def find_by_size(list1, list2)
    list1.each do |size, files1|
      if list2.include? size
        yield files1, list2[size]
      end
    end
  end

  # Найти одинаковые по содержимому
  def find_by_content(list1, list2)
    list1 = list1.group_by { |file| get_digest file }
    list2 = list2.group_by { |file| get_digest file }

    list1.each do |digest, files1|
      if list2.include? digest
        yield files1, list2[digest]
      end
    end
  end

  # Вычислить уникальный код
  def get_digest(file)
    if @storage
      @storage.get(file)
    else
      @digest_storage ||= {}
      @digest_storage[file] ||= block_crc32(file, 1000, 1)
    end
  end

  def fix_file_name(folder)
    all = []
    rx_good = /^[a-z\d\$\.\-\+_]+$/i
    rx_bad = /[^a-z\d\$\.\-\+_]/i

    Find.find(folder) do |path|
      path = Pathname.new path
      if path.file?
        unless path.basename.to_s =~ rx_good
          #pp path
          all << path
        end
      end
    end

    #pp all
    all.each do |path|
      good_path = path.basename(path.extname).to_s
      pp good_path
      good_path.gsub! rx_bad, '_'
      good_path = path.dirname + (good_path + path.extname)
      pp good_path
      #path.rename good_path

    end
  end

end
