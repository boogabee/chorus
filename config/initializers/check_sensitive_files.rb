if Rails.env.production? && !SensitiveFileChecker.check
  message = "FATAL ERROR: #{SensitiveFileChecker.unprotected_files.to_sentence} are readable or writable by other users."
  Rails.logger.fatal message
  abort message
end