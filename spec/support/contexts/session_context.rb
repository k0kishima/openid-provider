RSpec.shared_context 'signed in as a user', shared_context: :metadata do
  let(:user) { create(:user) }
  before { sign_in(user) }
end
