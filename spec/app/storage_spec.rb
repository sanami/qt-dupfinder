require 'spec_helper'
require 'storage.rb'

describe Storage do
  subject do
    Storage.new(ROOT('tmp/test.yaml'))
  end

  it 'should get' do
    test_file = TEST_DIR + '1249409841848.jpg'
    crc = subject.get_digest test_file
    #pp subject.files
    crc.should be > 0
    subject.should have(1).files

    subject.files.first[0].should == test_file.realpath.to_s
    info = subject.files.first[1]
    info.mtime.should == test_file.mtime
    info.size.should == test_file.size
  end

  it 'should save' do
    FileUtils.rm subject.db_file rescue nil
    File.exist?(subject.db_file).should be_false

    subject.is_changed = true
    subject.save

    File.exist?(subject.db_file).should be_true
  end
end
