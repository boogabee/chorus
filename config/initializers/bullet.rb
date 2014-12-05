if Rails.env.development?
  Rails.configuration.after_initialize do
    Bullet.enable = false
    Bullet.rails_logger = true
  end
end
