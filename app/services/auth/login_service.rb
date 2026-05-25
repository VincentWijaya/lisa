module Auth
  class LoginService
    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @email = params[:email].to_s.strip.downcase
      @password = params[:password].to_s
      @errors = []
    end

    def call
      user = User.find_by(email: @email)

      unless user&.authenticate(@password)
        return ServiceResult.failure(errors: [ "Invalid email or password" ])
      end

      unless user.active?
        return ServiceResult.failure(errors: [ "Your account is inactive. Contact an administrator." ])
      end

      ServiceResult.success(user: user)
    end
  end
end
