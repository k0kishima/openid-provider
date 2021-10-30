module Auth::OpenidRequestable
  extend ActiveSupport::Concern

  included do
    self.table_name = 'oauth_openid_requests'

    validates :access_grant_id, :nonce, presence: true
    belongs_to :access_grant, class_name: 'Auth::AccessGrant', inverse_of: :openid_request
  end
end
