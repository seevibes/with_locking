require_relative '../lib/with_locking.rb'

describe WithLocking do
  let(:path) { 'tmp/pids/rspec_test.pid' }
  let(:file_name) { 'rspec_test' }

  before :each do
    File.stub(:open)
    File.stub(:delete)
  end

  describe "#do" do

    it "writes a pid file" do
      File.should_receive(:open).with(path, "w")
      WithLocking.do(:name => file_name) { }
    end

    it "executes the given block" do
      my_test_array = []
      WithLocking.do { my_test_array << 1 }
      my_test_array.count.should == 1
    end

    it "deletes the pid file" do
      File.should_receive(:delete).with(path)
      WithLocking.do(:name => file_name) {}
    end

    it "should not execute the block if the pid file already exists" do
      File.stub(:exists?).and_return(true)
      WithLocking.do {}.should == false
    end

  end

  describe "#do!" do

    it "raises an exception if the pid file already exists" do
      File.stub(:exists?).and_return(true)
      lambda { WithLocking.do! {} }.should raise_error(RuntimeError, 'locked process still running')
    end

  end

  describe "#locked?" do

    it "checks if the file exists" do
      File.should_receive(:exists?).with(path)
      WithLocking.locked?(file_name)
    end

  end
end
