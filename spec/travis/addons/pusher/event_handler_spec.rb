require 'spec_helper'

describe Travis::Addons::Pusher::EventHandler do
  include Travis::Testing::Stubs

  let(:build)   { stub_build(state: :failed, repository: repository) }
  let(:subject) { Travis::Addons::Pusher::EventHandler }
  let(:payload) { Travis::Api.data(build, for: 'event', version: 'v0') }

  before do
    Travis::Event.stubs(:subscribers).returns [:pusher]
    subject.stubs(:handle => true, :handle? => true)
  end

  it "doesn't override original payload" do
    event_handler = subject.new('build:finished', build, {}, payload)
    event_handler.payload.should == payload
  end

  describe 'subscription' do
    it 'job:test:created' do
      subject.expects(:notify)
      Travis::Event.dispatch('job:test:created', test)
    end

    it 'job:test:started' do
      subject.expects(:notify)
      Travis::Event.dispatch('job:test:started', test)
    end

    it 'job:log' do
      subject.expects(:notify)
      Travis::Event.dispatch('job:test:log', test)
    end

    it 'job:test:finished' do
      subject.expects(:notify)
      Travis::Event.dispatch('job:test:finished', test)
    end

    it 'build:created' do
      subject.expects(:notify)
      Travis::Event.dispatch('build:created', build)
    end

    it 'build:started' do
      subject.expects(:notify)
      Travis::Event.dispatch('build:started', build)
    end

    it 'build:finished' do
      subject.expects(:notify)
      Travis::Event.dispatch('build:finished', build)
    end
  end

  # describe 'instrumentation' do
  #   it 'instruments with "travis.event.handler.pusher.notify"' do
  #     ActiveSupport::Notifications.stubs(:publish)
  #     ActiveSupport::Notifications.expects(:publish).with do |event, data|
  #       event =~ /travis.event.handler.pusher.notify/ && data[:target].is_a?(Travis::Event::Handler::Pusher)
  #     end
  #     Travis::Event.dispatch('build:finished', build)
  #   end

  #   it 'meters on "travis.event.handler.pusher.notify:completed"' do
  #     Metriks.expects(:timer).with('v1.travis.event.handler.pusher.notify:completed').returns(stub('timer', :update => true))
  #     Travis::Event.dispatch('build:finished', build)
  #   end
  # end
end
