FactoryBot.define do
  factory :auth_access_grant, class: Doorkeeper.config.access_grant_model do
    expires_in { 10.minutes }
  end
end
