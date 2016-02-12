require 'rails_helper'

RSpec.describe UserRegistration do
  subject(:registration) { UserRegistration.new(auth_hash) }

  let(:provider) { 'github' }
  let(:uid) { '98765' }
  let(:name) { 'Foo Bar' }
  let(:email) { 'foo.bar@example.com' }
  let(:auth_hash) do
    {
      provider: provider,
      uid: uid,
      info: { 
        name: name, 
        email: email
      }
    }.with_indifferent_access
  end
  
  context "when auth_hash is missing" do
    it "raises error" do
      expect { UserRegistration.new }.to raise_error(ArgumentError)
    end
  end

  describe '#user' do
    it 'returns a User instance' do
      expect(registration.user).to be_a(User)
    end
  end

  describe '#created?' do
    before do
      allow(registration).to receive(:_run)
    end

    context "for newly created users" do
      before do
        registration.instance_variable_set(:@created, true)
      end

      it "returns true" do
        expect(registration.created?).to be true
      end
    end

    context "for already existing users" do
      before do
        registration.instance_variable_set(:@created, false)
      end

      it "returns false" do
        expect(registration.created?).to be false
      end
    end
  end

  describe 'private methods' do
    describe '#_run' do

      context "if method was previously called" do
        before do
          registration.instance_variable_set(:@ran, true)
        end

        it "does nothing" do
          expect(User).to_not receive(:find)
          expect(User).to_not receive(:create)
          registration.send(:_run)
        end
      end

      context "for previously registered user" do
        let(:existing_user) { double(:user) }

        it "finds a user and sets instance variables with correct values" do
          expect(User).to receive(:find).with(uid: "#{provider}|#{uid}") { [existing_user] }
          registration.send(:_run)
          expect(registration.instance_variable_get(:@user)).to eq existing_user
          expect(registration.instance_variable_get(:@created)).to eq false
          expect(registration.instance_variable_get(:@ran)).to eq true
        end
      end

      context "for non registered user" do
        let(:new_user) { double(:user) }

        before do
          Timecop.freeze
        end

        it "creates a new user and sets instance variables with correct values" do
          expect(User).to receive(:create).with(
            uid:        "#{provider}|#{uid}", 
            name:       name,
            email:      email,
            created_at: Time.current.utc.to_i
          ) { new_user }
          registration.send(:_run)
          expect(registration.instance_variable_get(:@user)).to eq new_user
          expect(registration.instance_variable_get(:@created)).to eq true
          expect(registration.instance_variable_get(:@ran)).to eq true
        end
      end
    end
  end
end
