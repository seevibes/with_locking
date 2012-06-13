require "with_locking/version"

module WithLocking 

  def self.do(options = {}, &block)
    raise "No block given" unless block_given?

    name = options[:name] || "locking_service_task"
    pid_file = "tmp/pids/#{name}.pid"
      
    return false if File.exists? pid_file

    begin 
      Dir.mkdir("tmp")
      Dir.mkdir("tmp/pids")
    rescue Errno::EEXIST => e
      # ignore this error
    end
      
    File.open(pid_file, 'w') { |f| f.puts Process.pid }
      
    begin
      block.call
    ensure
      File.delete pid_file
    end
    return true
  end

  def self.do!(options = {}, &block)
    raise "locked process still running" unless self.do(options, &block)
  end

  def self.locked?(name)
    File.exists?("tmp/pids/#{name}.pid")
  end

end
