class AuthenticateRequest
    def initialize(app)
      @app = app
    end

    def call(env)
        request = Rack::Request.new(env)
        if ["register", "login","/"].include?(request.path.split('/').last)
          Rails.logger.debug "Skipping Authentication Middleware for #{request.path}"
          return @app.call(env) 
        end

        @headers = request.env

        if user
            env['current_user'] = user
            @app.call(env)
        else
            [401, {"Content-type" => "application/json"}, [{error: 'Unauthorized'}.to_json]]
        end
    end

    private


    def user
        @user ||= User.find_by(id: decoded_token[:user_id]) if decoded_token
    end

    def decoded_token
        @decoded_token ||= decode_token
    end

    def decode_token
        token = @headers['HTTP_AUTHORIZATION']&.split(' ')&.last
            Rails.logger.debug "Token: #{token}"
        return nil unless token

        begin
            decoded = JsonWebToken.decode(token)
             Rails.logger.debug "Decoded Token: #{decoded}"
            decoded
        rescue JWT::DecodeError => e
             Rails.logger.debug "JWT Decode Error: #{e.message}"
             
            nil
        end
    end
end