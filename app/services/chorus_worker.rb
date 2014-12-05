class ChorusWorker < QC::Worker
  SLEEP_INCREMENT = 2

  def start
    Thread.new { ImportCanceler.run }
    super
  end

  def thread_pool_size
    ChorusConfig.instance['worker_threads'].to_i
  end

  def handle_failure(job, e)
    cleaner = ::ActiveSupport::BacktraceCleaner.new
    cleaner.add_filter { |line| line.gsub(Rails.root.to_s, '') }
    log :level => :error, :job => job_description(job), :exception => e.message, :backtrace => "\n" + cleaner.clean(e.backtrace).join("\n")
  end

  def lock_job
    log(:level => :debug, :action => "lock_job")
    attempts = 0
    job = nil
    until job || !running?
      job = @queue.lock(@top_bound)
      if job.nil?
        log(:level => :debug, :action => "failed_lock", :attempts => attempts)
        if attempts < @max_attempts
          seconds = 2**attempts
          wait(seconds)
          attempts += 1
          next
        else
          break
        end
      else
        log(:level => :debug, :action => "finished_lock", :job => job_description(job))
      end
    end
    log(:level => :info, :action => "shutdown_workers") unless running?
    job
  end

  def wait(seconds)
    log(:level => :debug, :action => "sleep_wait", :wait => seconds)
    timer = 0
    while timer < seconds && running? do
      Kernel.sleep(SLEEP_INCREMENT)
      timer += SLEEP_INCREMENT
    end
  end
end