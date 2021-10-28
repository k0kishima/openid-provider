class Auth::AccessGrant < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessGrant

  has_one :openid_request, class_name: 'Doorkeeper::OpenidConnect::Request', dependent: :delete
end
