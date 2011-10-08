require 'zlib'

##
# CRC32 calculator for large files
#
# block_size - Block size in KB
def block_crc32(file_name, block_size = 1000)
	puts "block_crc32(#{file_name})"
	crc = nil
  File.open(file_name, "rb") do |f|
	  buf = ""
	  while f.read(1024*block_size, buf)
		  crc = Zlib.crc32 buf, crc
	  end
  end

	crc
end
