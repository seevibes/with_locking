require "with_locking/version"

module WithLocking 
  def self.run(options = {}, &block)
    raise "No block given" unless block_given?

    name = options[:name] || "locking_service_task"
    pid_file = "tmp/pids/#{name}.pid"
      
    return false if File.exists? pid_file

    Dir.mkdir("tmp") unless Dir.exists?("tmp")
    Dir.mkdir("tmp/pids") unless Dir.exists?("tmp/pids")
      
    File.open(pid_file, 'w') { |f| f.puts Process.pid }
      
    begin
      block.call
    ensure
      File.delete pid_file
    end
    true
  end

  def self.run!(options = {}, &block)
    raise "locked process still running" unless self.run(options, &block)
  end

  def self.locked?(name)
    File.exists?("tmp/pids/#{name}.pid")
  end
end