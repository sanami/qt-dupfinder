require 'zlib'

# CRC32 calculator for large files
#
# block_size - Block size in KB
# block_count - Only first blocks
def block_crc32(file_name, block_size = 1000, block_count = nil)
  puts "block_crc32(#{file_name})"
  crc = nil
  count = 0
  File.open(file_name, "rb") do |f|
    buf = ""
    while f.read(1024*block_size, buf)
      crc = Zlib.crc32 buf, crc

      # Limit
      count += 1
      if block_count && count >= block_count
        break
      end
    end
  end

  crc
end
