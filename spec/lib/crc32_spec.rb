require 'spec_helper'
require 'benchmark'
require 'digest/sha1'
require 'crc32.rb'

describe "Digest CRC32" do

  it "work with file" do
    test_file = TEST_DIR + '1249409841848.jpg'
    dig = crc = crc2 = nil
    Benchmark.bm do |x|
      x.report("Digest::CRC32") do
        dig = Digest::CRC32.file(test_file) # very slow
        dig.checksum.should == 0xf9b62400
      end
      x.report("Zlib.crc32") do
        crc = Zlib.crc32(File.read(test_file))
        dig.checksum.should == crc
      end
      x.report("block_crc32") do
        crc2 = block_crc32 test_file, 100
        crc2.should == crc
      end

      x.report("Digest::SHA1") do
        sha = Digest::SHA1.new
        File.open(test_file, 'rb') do |handle|
          while buffer = handle.read(1024*100)
            sha << buffer
          end
        end
        pp sha
      end
    end
  end

  it "work with large file" do
    test_file = '/opt/Storage/Downloads/rbc_12.10.pdf'
    #test_file = '/opt/vmware/Windows XP Professional/Windows XP Professional-s002.vmdk'

    Benchmark.bmbm do |x|
      x.report("block_crc32") do
        crc2 = block_crc32 test_file, 1000
      end
      x.report("Digest::SHA1") do
        sha = Digest::SHA1.new
        File.open(test_file, 'rb') do |handle|
          while buffer = handle.read(1024*1000)
            sha << buffer
          end
        end
      end
    end

  end


end
