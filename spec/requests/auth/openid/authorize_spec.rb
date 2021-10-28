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
    let(:params) do
      {
        response_type: response_type,
        client_id: client_id,
        redirect_uri: redirect_uri,
        scope: scope,
      }
    end

    context 'when a user is already signed in' do
      include_context 'signed in as a user'

      before { subject }

      context 'when parameters are valid' do
        let(:code) { Doorkeeper.config.access_grant_model.take.token }

        it 'redirects to sign in form' do
          expect(response.status).to eq 302
          expect(response.location).to eq "#{rp.redirect_uri}?code=#{code}"
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
