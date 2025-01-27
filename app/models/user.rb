class User < ApplicationRecord
  has_many :microposts,dependent: :destroy
  has_many :active_relationships,class_name: "Relationship",
    foreign_key: "follower_id",dependent: :destroy
  has_many :passive_relationships,class_name: "Relationship",
    foreign_key: "followed_id",dependent: :destroy
  has_many :following,through: :active_relationships,source: :followed
  has_many :followers,through: :passive_relationships
  attr_accessor :remember_token
  before_save {self.email=email.downcase}
  validates :name,presence: true,length: {maximum:50}
  VALID_EMAIL_REGEX=/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email,presence: true,length: {maximum:255},
                    format: {with:VALID_EMAIL_REGEX},
                    uniqueness: {case_sensitive: false}
  has_secure_password
  validates :password,presence: true,length: {minimum: 6},allow_nil: true

  def self.digest(string)
    cost=ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST:
                            BCrypt::Engine.cost
    BCrypt::Password.create(string,cost: cost)
  end

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token=User.new_token
      update_attribute(:remember_digest,User.digest(remember_token))
  end

  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  def forget
    update_attribute(:remember_digest,nil)
  end

  def feed
    following_ids = "SELECT followed_id FROM relationships
                     WHERE follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids})
                     OR user_id = :user_id", user_id: id)
  end

  def follow(other)
    following << other
  end

  def unfollow(other)
    active_relationships.find_by(followed_id: other.id).destroy
  end

  def following?(other)
    following.include?(other)
  end
end
