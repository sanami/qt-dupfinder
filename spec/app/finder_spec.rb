require 'spec_helper'
require 'finder.rb'

describe Finder do

	it "should list folder" do
		all = subject.list TEST_DIR
		all.should_not be_empty
		all.is_a?(Array).should be_true
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

	it "should run" do
		folder1 = TEST_DIR + 'folder1'
		folder2 = TEST_DIR + 'folder2'
		subject.run(folder1, folder2) do |files1, files2|
			pp [files1, files2]
			pp '------------------------'
		end
	end
end
