def run_jobs_synchronously
  stub(QC.default_queue).enqueue_if_not_queued.with_any_args do |class_and_message, *args|
    className, message = class_and_message.split(".")
    className.constantize.send(message, *args)
  end
end