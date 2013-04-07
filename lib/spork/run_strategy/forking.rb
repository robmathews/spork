class Spork::RunStrategy::Forking < Spork::RunStrategy
  def self.available?
    Kernel.respond_to?(:fork)
  end

  def run(argv, stderr, stdout, env_opts={})
    @children ||= []
    @children << (child = ::Spork::Forker.new do
      env_opts.each do |k,v|
        ENV[k]=v
      end
      $stdout, $stderr = stdout, stderr
      load test_framework.helper_file
      Spork.exec_each_run
      result = test_framework.run_tests(argv, stderr, stdout)
      Spork.exec_after_each_run
      result
    end)
    @children = @children.reject {|c| c == child}
    child.result
  end

  def abort
    @children && @children.each {|child| child.abort}
  end

  def preload
    test_framework.preload
  end

  def running?
    @children && @children.detect {|child| child.running?}
  end

  def assert_ready!
    raise RuntimeError, "This process hasn't loaded the environment yet by loading the prefork block" unless Spork.using_spork?
  end
end