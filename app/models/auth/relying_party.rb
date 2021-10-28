class Auth::RelyingParty < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application
end
