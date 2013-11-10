require 'travis/notification'

module Travis
  module Addons
    require 'travis/addons/campfire'
    require 'travis/addons/email'
    require 'travis/addons/flowdock'
    require 'travis/addons/github_status'
    require 'travis/addons/hipchat'
    require 'travis/addons/irc'
    require 'travis/addons/pusher'
    require 'travis/addons/states_cache'
    require 'travis/addons/util'
    require 'travis/addons/webhook'

    class << self
      def register
        constants(false).each do |name|
          key = name.to_s.underscore
          const = const_get(name)
          handler = const.const_get(:EventHandler) rescue nil
          Travis::Event::Subscription.register(key, handler) if handler
          const.setup if const.respond_to?(:setup)
        end
      end
    end
  end
end
