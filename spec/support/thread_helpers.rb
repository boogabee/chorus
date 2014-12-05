def wait_until(total_seconds = 5, sleep_seconds = 0.1)
  Timeout::timeout(total_seconds.seconds) do
    until yield
      sleep(sleep_seconds)
    end
  end
end