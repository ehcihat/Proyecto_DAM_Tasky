class User
  include Mongoid::Document
  include Mongoid::Timestamps
  require 'bcrypt'

  field :name, type: String
  field :email, type: String
  field :password_digest, type: String

  has_many :projects, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  def password=(new_password)
    self.password_digest = BCrypt::Password.create(new_password)
  end

  def authenticate(password)
    BCrypt::Password.new(self.password_digest) == password
  end
end
