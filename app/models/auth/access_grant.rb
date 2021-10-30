class Auth::AccessGrant < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessGrant

  has_one :openid_request, class_name: 'Auth::OpenidRequest', inverse_of: :access_grant, dependent: :delete
end
