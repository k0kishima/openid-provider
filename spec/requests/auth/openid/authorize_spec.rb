require 'rails_helper'

RSpec.describe 'OIDC authorize request', type: :request do
  describe 'GET /auth/openid/authorize' do
    subject { get oauth_authorization_path, params: params }

    let(:rp) { create(:auth_relying_party) }
    let(:other_rp) { create(:auth_relying_party) }
    let(:response_type) { 'code' }
    let(:client_id) { rp.uid }
    let(:redirect_uri) { rp.redirect_uri }
    let(:scope) { 'openid' }
    let(:code_challenge) { '' }
    let(:code_challenge_method) { '' }
    let(:params) do
      {
        response_type: response_type,
        client_id: client_id,
        redirect_uri: redirect_uri,
        scope: scope,
        code_challenge: code_challenge,
        code_challenge_method: code_challenge_method,
      }
    end

    context 'when a user is already signed in' do
      include_context 'signed in as a user'

      shared_examples 'a_redirection_to_RP_callback_uri' do
        it 'redirects to a url which is specified by RP' do
          expect(response.status).to eq 302
          expect(response.location).to eq "#{rp.redirect_uri}?code=#{code}"
        end
      end

      before { subject }

      context 'when parameters are valid' do
        let(:code) { Doorkeeper.config.access_grant_model.take.token }

        it_behaves_like 'a_redirection_to_RP_callback_uri'

        context 'when also PKCE params given' do
          context 'when code_challenge_method is "S256"' do
            let(:code_challenge_method) { 'S256' }

            context 'when code_challenge is specified' do
              let(:code_verifier) { SecureRandom.alphanumeric(128) }
              let(:code_challenge) { Base64.urlsafe_encode64(OpenSSL::Digest::SHA256.digest(code_verifier), padding: false) }
              let(:access_grant) { Doorkeeper.config.access_grant_model.take }

              it_behaves_like 'a_redirection_to_RP_callback_uri'

              it 'saves code_challenge and code_challenge_method' do
                expect(access_grant.code_challenge).to eq code_challenge
                expect(access_grant.code_challenge_method).to eq code_challenge_method
              end
            end

            # TODO: メソッドだけ指定されてチャレンジが空のパターンはエラーにすべきでは？
            context 'when code_challenge is not specified' do
              let(:code_challenge) { '' }

              it_behaves_like 'a_redirection_to_RP_callback_uri'
            end
          end

          # TODO: It should be permitted S256 only as code_challenge_method.
          # https://github.com/k0kishima/openid-provider/issues/2
          xcontext 'when code_challenge_method is not "S256"' do
            let(:code_challenge_method) { 'plain' }
          end
        end
      end

      context 'when parameters are invalid' do
        context 'when response_type is not specified' do
          let(:response_type) { '' }

          it do
            expect(response.status).to eq 200
            expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.invalid_request.missing_param', value: :response_type)
          end
        end

        context 'when unsupported response_type specified' do
          shared_examples 'show_an_error_about_unsupported_response_type' do
            it do
              expect(response.status).to eq 200
              expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.unsupported_response_type')
            end
          end

          context 'when response_type is client_credentials' do
            let(:response_type) { 'client_credentials' }

            it_behaves_like 'show_an_error_about_unsupported_response_type'
          end

          context 'when response_type is token' do
            let(:response_type) { 'token' }

            it_behaves_like 'show_an_error_about_unsupported_response_type'
          end

          context 'when response_type is id_token' do
            let(:response_type) { 'id_token' }

            it_behaves_like 'show_an_error_about_unsupported_response_type'
          end
        end

        context 'when client_id is not specified' do
          let(:client_id) { '' }

          it do
            expect(response.status).to eq 200
            expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.invalid_request.missing_param', value: :client_id)
          end
        end

        context 'when specified client_id is not exist' do
          let(:client_id) { 'foobar' }

          it do
            expect(response.status).to eq 200
            expect(response.body).to be_include I18n.t('doorkeeper.errors.messages.invalid_client')
          end
        end

        context 'when redirect_uri is not specified' do
          let(:redirect_uri) { '' }

          it do
            expect(response.status).to eq 200
            expect(response.body).to be_include CGI.escapeHTML(I18n.t('doorkeeper.errors.messages.invalid_redirect_uri'))
          end
        end

        context 'when specified redirect_uri is unmatched' do
          let(:redirect_uri) { other_rp.redirect_uri }

          it do
            expect(response.status).to eq 200
            expect(response.body).to be_include CGI.escapeHTML(I18n.t('doorkeeper.errors.messages.invalid_redirect_uri'))
          end
        end
      end
    end

    context 'when a user is not signed in yet' do
      before { subject }

      it 'redirects to sign in form' do
        expect(response.status).to eq 302
        expect(response.location).to eq new_user_session_url
      end
    end
  end
end
