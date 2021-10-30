module Doorkeeper
  # NOTE:
  # doorkeeper では設定ファイルで独自で実装したモデルを代替として使用することを宣言できる
  # 一方 doorkeeper-openid_connect では doorkeeper の組み込みモデルを使うことを前提としていて、
  # 独自実装したモデルを用いた場合にエラーが発生してしまう
  # 上記問題を解決するためのワークアラウンド
  #
  # c.f.
  # https://github.com/doorkeeper-gem/doorkeeper-openid_connect/blob/master/lib/doorkeeper/openid_connect/oauth/authorization/code.rb#L28
  ActiveSupport.on_load(:active_record) do
    raise NameError unless defined?(OpenidConnect::Request)

    OpenidConnect::Request.include Auth::OpenidRequestable
  end
end
