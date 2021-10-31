require 'rails_helper'

RSpec.describe 'OIDC token request', type: :request do
  describe 'GET /auth/openid/token' do
    include_context 'signed in as a user'

    subject { post oauth_token_path, params: params }

    let(:rp) { create(:auth_relying_party) }
    let(:code_challenge) { '' }
    let(:code_challenge_method) { '' }
    let(:access_grant) do
      create(
        :auth_access_grant,
        application: rp,
        redirect_uri: redirect_uri,
        resource_owner_id: user.id,
        expires_in: code_expires_in,
        scopes: scopes,
        code_challenge: code_challenge,
        code_challenge_method: code_challenge_method,
      )
    end 
    let(:code_expires_in) { 3.minutes }
    let(:client_id) { rp.uid }
    let(:client_secret) { rp.secret }
    let(:redirect_uri) { rp.redirect_uri }
    let(:code) { access_grant.token }
    let(:scopes) { %w(openid) }
    let(:grant_type) { 'authorization_code' }
    let(:code_verifier_from_rp) { '' }
    let(:params) do
      {
        grant_type: grant_type,
        code: code,
        client_id: client_id,
        client_secret: client_secret,
        redirect_uri: redirect_uri,
        code_verifier: code_verifier_from_rp,
      }
    end

    context 'when parameters are valid' do
      shared_examples 'access_token_responsible' do
        it 'responses an access token and expiration date' do
          expect(response.status).to eq 200
          json = JSON.parse(response.body)
          expect(json['access_token']).to eq generated_token.token
          expect(json['expires_in']).to eq generated_token.expires_in
        end
      end

      let(:generated_token) { Doorkeeper.config.access_token_model.where(application_id: rp.id, resource_owner_id: user.id).last }
      let(:decode_token) do
        ->(encoeded_token) do
          JWT.decode(
            encoeded_token,
            OpenSSL::PKey.read(Doorkeeper::OpenidConnect.configuration.signing_key).public_key,
            true,
            { algorithm: Doorkeeper::OpenidConnect.signing_algorithm.to_s }
          )
        end
      end

      before do
        travel_to(Time.zone.local(2021, 10, 20))

        # リクエスト実行前にこのリソースを作っておく必要があるサンプルがあるのでそのためのワークアラウンド
        # prepend_before でなんとかできると思ったがサンプルの階層の問題で実現できないようだった
        # かといって before ブロックを複製したくはないので暫定的にこの対応とする
        openid_request if respond_to?(:openid_request)

        subject
      end

      context 'when scopes contain openid' do
        let(:scopes) { %w(openid) }

        it_behaves_like 'access_token_responsible'

        it 'responses a id token' do
          expect(response.status).to eq 200
          json = JSON.parse(response.body)

          payload, header = decode_token.call(json['id_token'])
          expect(payload['iss']).to eq 'issuer string'
          expect(payload['aud']).to eq rp.uid
          expect(Time.zone.at(payload['iat'])).to eq Time.zone.local(2021, 10, 20)
          expect(Time.zone.at(payload['exp'])).to eq Time.zone.local(2021, 10, 20) + 2.minutes
          expect(header['typ']).to eq 'JWT'
          expect(header['alg']).to eq 'RS256'
          expect(header['kid']).to be_present
        end

        context 'when nonce is persisted' do
          let(:openid_request) { access_grant.create_openid_request(nonce: SecureRandom.hex(20)) }

          it 'responses a id token which contains a nonce claim' do
            json = JSON.parse(response.body)

            payload, = decode_token.call(json['id_token'])
            expect(payload['nonce']).to eq openid_request.nonce
          end
        end
      end

      context 'when scopes does not contain openid' do
        let(:scopes) { '' }

        it_behaves_like 'access_token_responsible'

        it 'does not response a id token' do 
          json = JSON.parse(response.body)
          expect(json.key?('id_token')).to be false
        end
      end

      context 'when the access_grant has PKCE properties' do
        let(:code_verifier) { SecureRandom.alphanumeric(128) }
        let(:code_challenge) { Base64.urlsafe_encode64(OpenSSL::Digest::SHA256.digest(code_verifier), padding: false) }
        let(:code_challenge_method) { 'S256' }

        context 'when code_verifier is valid' do
          let(:code_verifier_from_rp) { code_verifier }

          it do
            expect(response.status).to eq 200
          end
        end

        context 'when code_verifier is invalid' do
          let(:code_verifier_from_rp) { 'foobar' }

          it do
            expect(response.status).to eq 400
            expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.invalid_grant')
          end
        end
      end
    end

    context 'when parameters are invalid' do
      before { subject }

      context 'when grant_type is not specified' do
        let(:grant_type) { '' }

        it do
          expect(response.status).to eq 400
          expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.invalid_request.missing_param', value: :grant_type)
        end
      end

      context 'when unsupported grant_type specified' do
        shared_examples 'show_an_error_about_unsupported_grant_type' do
          it do
            expect(response.status).to eq 400
            expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.unsupported_grant_type')
          end
        end

        xcontext 'when grant_type is client_credentials' do
          let(:grant_type) { 'client_credentials' }

          it_behaves_like 'show_an_error_about_unsupported_grant_type'
        end

        context 'when grant_type is password' do
          let(:grant_type) { 'password' }

          it_behaves_like 'show_an_error_about_unsupported_grant_type'
        end
      end

      context 'when code is not specified' do
        let(:code) { '' }

        it do
          expect(response.status).to eq 400
          expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.invalid_request.missing_param', value: :code)
        end
      end

      context 'when nonexistent code is specified' do
        let(:code) { 'foobar' }

        it do
          expect(response.status).to eq 400
          expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.invalid_grant')
        end
      end

      context 'when expired code is specified' do
        let(:code_expires_in) { 0 }

        it do
          expect(response.status).to eq 400
          expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.invalid_grant')
        end
      end 

      context 'when client_id is not specified' do
        let(:client_id) { '' }

        it do
          expect(response.status).to eq 401
          expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.invalid_client')
        end
      end

      context 'when specified client_id is not exist' do
        let(:client_id) { 'foobar' }

        it do
          expect(response.status).to eq 401
          expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.invalid_client')
        end
      end

      xcontext 'when redirect_uri is not specified' do
        let(:redirect_uri) { '' }

        it do
          expect(response.status).to eq 400
          expect(response.body).to be_include CGI.escapeHTML(I18n.t('doorkeeper.errors.messages.invalid_redirect_uri'))
        end
      end

      context 'when specified redirect_uri is unmatched' do
        let(:redirect_uri) { 'foobar' }

        it do
          expect(response.status).to eq 400
          expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.invalid_grant')
        end
      end
    end
  end
end
