Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins /\Ahttp:\/\/localhost(:\d+)?\z/,
      /\Ahttp:\/\/host.docker.internal(:\d+)?\z/

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
