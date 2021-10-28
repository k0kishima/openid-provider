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

  access_grant_class 'Auth::AccessGrant'
  application_class 'Auth::RelyingParty'

  default_scopes  :openid

  skip_authorization do
    # NOTE:
    # ここでのauthorization:
    # 認可リクエストの際に認可内容をユーザーに確認する画面（「Authorization required」みたいなタイトル）
    # 現状、外部のアプリケーションを登録するような仕様ではないため身内のことは信頼してスキップ
    true
  end
end
