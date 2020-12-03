class AuthenticateUser
  prepend SimpleCommand
  attr_accessor :email, :password
  
  def initialize(email, password) 
    @email = email
    @password = password
  end

  def call
    JsonWebToken.encode(user_id: user.id, email: user.email) if user
  end

  private

  def user
   #byebug 
    #user = User.find_by(email: email)
    user =  User.where(email: email).present? ? User.find_by(email: email): nil
    return user if user && BCrypt::Password.new(user.password) == password
    errors.add :user_authentication, 'invalid credentials'
    nil
  end
end
