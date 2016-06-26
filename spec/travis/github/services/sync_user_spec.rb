require 'spec_helper'

describe Travis::Github::Services::SyncUser do
  include Support::ActiveRecord

  let(:user)    { Factory(:user) }
  let(:service) { described_class.new(user) }

  before do
    Travis.config.email.from = 'support@travis-ci.com'
  end

  describe 'run' do
    it 'resets is_syncing even on error' do
      service.expects(:syncing).raises(StandardError)
      user.expects(:update_column).with(:is_syncing, false)

      expect {
        service.run
      }.to raise_error
    end
  end

  describe 'syncing' do
    it 'returns the block value' do
      service.send(:syncing) { 42 }.should == 42
    end

    it 'sets is_syncing?' do
      user.is_syncing = false
      user.should_not be_syncing
      service.send(:syncing) { user.should be_syncing }
      user.should_not be_syncing
    end

    it 'sets synced_at' do
      time = Time.now
      service.send(:syncing) { }
      user.synced_at.should >= time
    end

    it 'raises exceptions' do
      exception = nil
      expect { service.send(:syncing) { raise('kaputt') } }.to raise_error
    end

    it 'ensures the user is set back to not sycing when an exception raises' do
      service.send(:syncing) { raise('kaputt') } rescue nil
      user.should_not be_syncing
    end
  end

  describe 'new_user?' do
    it 'sends an email to a new user' do
      user.synced_at = nil
      Travis.config.welcome_email = true
      expect {
        service.new_user?
      }.to change(ActionMailer::Base, :deliveries)
    end

    it "doesn't send an email to an existing user" do
      user.synced_at = Time.now
      Travis.config.welcome_email = true
      expect {
        service.new_user?
      }.to_not change(ActionMailer::Base, :deliveries)
    end

    it "doesn't send an email with the welcome email disabled" do
      user.synced_at = Time.now
      Travis.config.welcome_email = false
      expect {
        service.new_user?
      }.to_not change(ActionMailer::Base, :deliveries)
    end

    it "doesn't send an email if the user is older than 48 hours" do
      user.created_at = Time.now - 49.hours
      Travis.config.welcome_email = true
      expect {
        service.new_user?
      }.to_not change(ActionMailer::Base, :deliveries)
    end

    it "doesn't send an email if the user doesn't have a valid email" do
      user.email = ""
      Travis.config.welcome_email = true
      expect {
        service.new_user?
      }.to_not change(ActionMailer::Base, :deliveries)
    end
  end
end
