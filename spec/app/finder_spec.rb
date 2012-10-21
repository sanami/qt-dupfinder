require 'spec_helper'
require 'finder.rb'
require 'storage.rb'

describe Finder do

  it "should list files in folder" do
    all = subject.list TEST_DIR
    all.should_not be_empty
    all.is_a?(Array).should be_true
  end

  it "should list unique in folders" do
    all = subject.list TEST_DIR
    all.should_not be_empty

    all2 = {}
    subject.list_unique(TEST_DIR, all2)
    subject.list_unique(TEST_DIR, all2) # same folder
    all2 = all2.keys
    all2.count.should == all.count
  end

  it "should group list by size" do
    all = subject.list TEST_DIR
    all = subject.group_by_size all
    #pp all
    all.should_not be_empty
    all.is_a?(Hash).should be_true
  end

  it "should find by size" do
    list1 = {1 => 'file1'}
    list2 = {1 => 'file2'}

    all = nil
    subject.find_by_size(list1, list2) do |files1, files2|
      all = [files1, files2]
    end
    all.should == ['file1', 'file2']
  end

  it "should get file digest" do
    crc = subject.get_digest TEST_DIR + '1249409841848.jpg'
    crc.should be > 0
  end

  it "should find by content" do
    # dup files
    list1 = [TEST_DIR + 'folder1/1281362761866.jpg']
    list2 = [TEST_DIR + 'folder2/1281362761866.jpg', TEST_DIR + 'folder2/1281362761866_2.jpg']

    found = false
    subject.find_by_content(list1, list2) do |files1, files2|
      found = true
    end
    found.should be_true

    # different files
    list1 = [TEST_DIR + 'folder1/1281362761866.jpg']
    list2 = [TEST_DIR + 'folder2/1281362761866_diff.jpg']

    found = false
    subject.find_by_content(list1, list2) do |files1, files2|
      found = true
    end
    found.should be_false
  end

  it "should compare two folders" do
    folder1 = TEST_DIR + 'folder1'
    folder2 = TEST_DIR + 'folder2'
    subject.compare(folder1, folder2) do |files1, files2|
      pp [files1, files2]
      pp '------------------------'
    end
  end

  it "should find dups in single folder" do
    folder1 = TEST_DIR + 'folder1'
    found = false
    subject.run(folder1) do |files|
      pp files
      pp '------------------------'
      found = true
    end
    found.should be_true
  end

  it "should find dups in multiple folder" do
    folder1 = TEST_DIR + 'folder1'
    folder2 = TEST_DIR + 'folder2'
    found = false
    subject.run([folder1, folder2]) do |files|
      pp files
      pp '------------------------'
      found = true
    end
    found.should be_true
  end

  it "should fix file name" do
    #subject.fix_file_name '/media/truecrypt1/'
  end

  it "should run" do
    #folder = '/media/truecrypt2'
    #subject.run(folder) do |files|
    #  pp files
    #  puts '-'*77
    #end
  end

  it "should clean second folder" do
    storage = Storage.new(ROOT('db/storage_books.yaml'))
    finder = Finder.new storage

    #finder.clean_folder :main_folder => '/home/sa/Books', :clean_folder => '/home/sa/Books1', :action => :delete

    storage.save
  end
end
