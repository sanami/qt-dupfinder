require 'find'
require 'crc32.rb'

# Поиск одинаковых файлов
class Finder
	def initialize(storage = nil)
		@storage = storage
	end

	# Сравнить два каталога
	def run(folder1, folder2)
		by_size1 = group_by_size list(folder1)
		by_size2 = group_by_size list(folder2)

		find_by_size(by_size1, by_size2) do |list1, list2|
			find_by_content(list1, list2) do |files1, files2|
				yield files1, files2
			end
		end
	end

	# Список файлов каталога
	def list(folder)
		all = []
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
			block_crc32 file
		end
	end

end
