require_dependency 'authenticate_request'

Rails.application.config.middleware.use AuthenticateRequest 