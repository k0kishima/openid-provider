# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  resource_owner_authenticator do
    current_user || warden.authenticate!(scope: :user)
  end

  # TODO:
  # ここで認証済ませたエンティティはRPの操作などができてしまうので、
  # 必要性が生じたときに制限を加える
  admin_authenticator do
    current_user || warden.authenticate!(scope: :user)
  end

  default_scopes  :openid
end
