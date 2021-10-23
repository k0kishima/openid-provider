FactoryBot.define do
  factory :auth_relying_party, class: Auth::RelyingParty do
    name { Faker::App.name }
    redirect_uri { Faker::Internet.url(scheme: :https) }
    scopes { "openid profile:read" }
  end
end
