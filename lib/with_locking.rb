require "with_locking/version"

module WithLocking
  class << self
    attr_accessor :piddir
  end

  def self.run(options = {}, &block)
    raise "No block given" unless block_given?
    return false if locked?(options)

    pid_file = pidfile(options)
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

  def self.remove_stale_file(options)
    return unless File.exists?(pidfile(options)) && options.include?(:stale_seconds)
    File.delete(pidfile(options)) if pid_stale(options)
  end

  def self.pid_stale(options)
    Time.now.utc.to_i - File.ctime(pidfile(options)).utc.to_i >= options[:stale_seconds]
  end

  def self.locked?(name_or_options)
    options = name_or_options.kind_of?(Hash) ? name_or_options : {}
    options = options.merge(name: name_or_options) unless options.include?(:name)
    remove_stale_file(options)
    File.exists?(pidfile(options))
  end


  def self.pidfile(options)
    name = options[:name] || "locking_service_task"
    File.join(effective_piddir(options), "#{name}.pid")
  end

  def self.effective_piddir(options)
    options.fetch(:piddir, WithLocking.piddir || ENV["WITH_LOCKING_PIDDIR"] || "tmp/pids")
  end
end
