# frozen_string_literal: true

Doorkeeper::OpenidConnect.configure do
  issuer do |resource_owner, application|
    'issuer string'
  end

  signing_key File.read(Rails.root.join(ENV.fetch('JWT_SECRET_KEY_FILE_NAME') { 'jwtRS256.key' }))

  subject_types_supported [:public]

  resource_owner_from_access_token do |access_token|
    User.find_by(id: access_token.resource_owner_id)
  end

  auth_time_from_resource_owner do |resource_owner|
  end

  reauthenticate_resource_owner do |resource_owner, return_to|
    store_location_for resource_owner, return_to
    sign_out resource_owner
    redirect_to new_user_session_url
  end

  select_account_for_resource_owner do |resource_owner, return_to|
  end

  subject do |resource_owner, _application|
    resource_owner.id
  end

  claims do
    # NOTE: normal_claim は claim の alias
    normal_claim :email, scope: :openid do |resource_owner|
      resource_owner.email
    end
  end
end
