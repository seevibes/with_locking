require_relative '../lib/with_locking.rb'
require "timecop"

describe WithLocking do
  let(:path) { 'tmp/pids/rspec_test.pid' }
  let(:file_name) { 'rspec_test' }

  before :each do
    File.stub(:open)
    File.stub(:delete)
    File.stub(:ctime).and_return(Time.now.utc)
  end

  describe "#run" do

    it "writes a pid file" do
      File.should_receive(:open).with(path, "w")
      WithLocking.run(name: file_name) { }
    end

    it "executes the given block" do
      my_test_array = []
      WithLocking.run { my_test_array << 1 }
      my_test_array.count.should == 1
    end

    it "deletes the pid file" do
      File.should_receive(:delete).with(path)
      WithLocking.run(name: file_name) {}
    end

    it "should not execute the block if the pid file already exists" do
      File.stub(:exists?).and_return(true)
      WithLocking.run {}.should == false
    end

  end

  describe "#run!" do

    it "raises an exception if the pid file already exists" do
      File.stub(:exists?).and_return(true)
      message = 'locked process still running'
      ->() { WithLocking.run! {} }.should raise_error(RuntimeError, message)
    end

  end

  describe "#locked?" do

    it "checks if the file exists" do
      File.should_receive(:exists?).with(path).twice
      WithLocking.locked?(file_name)
    end

  end

  describe "#remove_staled_file" do

    it "returns if the option :stale_seconds is not provided" do
      File.should_receive(:exists?).with(path)
      File.should_not_receive(:delete).with(path)
      WithLocking.remove_stale_file(name: file_name)
    end

    it "deletes the file if stale_seconds is provided" do
      Timecop.travel(Time.now.utc + 2)
      File.stub(:exists?).and_return(true)
      File.should_receive(:delete).with(path)
      WithLocking.remove_stale_file(name: file_name, stale_seconds: 1)
    end

  end

  describe "#pid_staled" do
    it "returns true if stale" do
      Timecop.travel(Time.now.utc + 2)
      expect(WithLocking.pid_stale(name: file_name, stale_seconds: 1)).to be(true)
    end

    it "returns false if not stale" do
      expect(WithLocking.pid_stale(name: file_name, stale_seconds: 1)).to be(false)
    end
  end

end

describe WithLocking, "with local piddir" do
  let(:path) { '/var/run/rspec_test.pid' }
  let(:file_name) { 'rspec_test' }

  before :each do
    File.stub(:open)
    File.stub(:delete)
  end

  describe "#run" do

    it "writes a pid file" do
      File.should_receive(:open).with(path, "w")
      WithLocking.run(name: file_name, piddir: "/var/run") { }
    end

    it "deletes the pid file" do
      File.should_receive(:delete).with(path)
      WithLocking.run(name: file_name, piddir: "/var/run") {}
    end

  end
end

describe WithLocking, "with global piddir" do
  let(:path) { '/var/run/myapp/rspec_test.pid' }
  let(:file_name) { 'rspec_test' }

  before :each do
    File.stub(:open)
    File.stub(:delete)
  end

  before :each do
    WithLocking.piddir = "/var/run/myapp"
  end

  after :each do
    WithLocking.piddir = nil
  end

  describe "#run" do

    it "writes a pid file" do
      File.should_receive(:open).with(path, "w")
      WithLocking.run(name: file_name) { }
    end

    it "deletes the pid file" do
      File.should_receive(:delete).with(path)
      WithLocking.run(name: file_name) {}
    end

  end
end

describe WithLocking, "with ENV piddir" do
  let(:path) { '/var/local/run/myapp/rspec_test.pid' }
  let(:file_name) { 'rspec_test' }

  before :each do
    File.stub(:open)
    File.stub(:delete)
  end

  before :each do
    ENV["WITH_LOCKING_PIDDIR"] = "/var/local/run/myapp"
  end

  after :each do
    ENV["WITH_LOCKING_PIDDIR"] = nil
  end

  describe "#run" do

    it "writes a pid file" do
      File.should_receive(:open).with(path, "w")
      WithLocking.run(name: file_name) { }
    end

    it "deletes the pid file" do
      File.should_receive(:delete).with(path)
      WithLocking.run(name: file_name) {}
    end

  end
end

describe WithLocking do

  before :each do
    File.stub(:open)
    File.stub(:delete)
  end

  after :each do
    WithLocking.piddir = nil
  end

  after :each do
    ENV["WITH_LOCKING_PIDDIR"] = nil
  end

  it "should prefer locally specified piddir" do
    File.should_receive(:open).with("/var/run/testapp.pid", "w")

    ENV["WITH_LOCKING_PIDDIR"] = "/var/local/run/myapp"
    WithLocking.piddir = "/var/run/myapp"
    WithLocking.run(name: "testapp", piddir: "/var/run") {}
  end

  it "should prefer globally specified piddir" do
    File.should_receive(:open).with("/var/run/myapp/testapp.pid", "w")

    ENV["WITH_LOCKING_PIDDIR"] = "/var/local/run/myapp"
    WithLocking.piddir = "/var/run/myapp"
    WithLocking.run(name: "testapp") {}
  end

end
