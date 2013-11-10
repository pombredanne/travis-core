require 'active_record'
require 'active_support/core_ext/hash/deep_dup'

# Job models a unit of work that is run on a remote worker.
#
# There currently only one job type:
#
#  * Job::Test belongs to a Build (one or many Job::Test instances make up a
#    build matrix) and executes a test suite with parameters defined in the
#    configuration.
class Job < Travis::Model
  require 'travis/model/job/queue'
  require 'travis/model/job/test'
  require 'travis/model/env_helpers'

  class << self
    # what we return from the json api
    def queued(queue = nil)
      scope = where(state: [:created, :queued])
      scope = scope.where(queue: queue) if queue
      scope
    end

    # what needs to be queued up
    def queueable(queue = nil)
      scope = where(state: :created).order('jobs.id')
      scope = scope.where(queue: queue) if queue
      scope
    end

    # what already is queued or started
    def running(queue = nil)
      scope = where(state: [:queued, :started]).order('jobs.id')
      scope = scope.where(queue: queue) if queue
      scope
    end

    def unfinished
      # TODO conflate Job and Job::Test and use States::FINISHED_STATES
      where('state NOT IN (?)', [:finished, :passed, :failed, :errored, :canceled])
    end

    def owned_by(owner)
      where(owner_id: owner.id, owner_type: owner.class.to_s)
    end
  end

  include Travis::Model::EnvHelpers

  has_one    :log, dependent: :destroy
  has_many   :events, as: :source

  belongs_to :repository
  belongs_to :commit
  belongs_to :source, polymorphic: true, autosave: true
  belongs_to :owner, polymorphic: true

  validates :repository_id, :commit_id, :source_id, :source_type, :owner_id, :owner_type, presence: true

  serialize :config

  delegate :request_id, to: :source # TODO denormalize
  delegate :pull_request?, to: :commit
  delegate :secure_env_enabled?, :addons_enabled?, to: :source

  after_initialize do
    self.config = {} if config.nil? rescue nil
  end

  before_create do
    build_log
    self.state = :created if self.state.nil?
    self.queue = Queue.for(self).name
  end

  after_commit on: :create do
    notify(:create)
  end

  def propagate(name, *args)
    # if we propagate cancel, we can't send it as "cancel", because
    # it would trigger cancelling the entire matrix
    if name == :cancel
      name = :cancel_job
    end
    source.send(name, *args)
    true
  end

  def duration
    started_at && finished_at ? finished_at - started_at : nil
  end

  def config=(config)
    super normalize_config(config)
  end

  def obfuscated_config
    normalize_config(config).deep_dup.tap do |config|
      delete_addons(config)
      config.delete(:source_key)
      if config[:env]
        obfuscated_env = process_env(config[:env]) { |env| obfuscate_env(env) }
        config[:env] = obfuscated_env ? obfuscated_env.join(' ') : nil
      end
      if config[:global_env]
        obfuscated_env = process_env(config[:global_env]) { |env| obfuscate_env(env) }
        config[:global_env] = obfuscated_env ? obfuscated_env.join(' ') : nil
      end
    end
  end

  def decrypted_config
    normalize_config(self.config).deep_dup.tap do |config|
      config[:env] = process_env(config[:env]) { |env| decrypt_env(env) } if config[:env]
      config[:global_env] = process_env(config[:global_env]) { |env| decrypt_env(env) } if config[:global_env]
      if config[:addons]
        if addons_enabled?
          config[:addons] = decrypt_addons(config[:addons])
        else
          delete_addons(config)
        end
      end
    end
  rescue => e
    logger.warn "[job id:#{id}] Config could not be decrypted due to #{e.message}"
    {}
  end

  def matrix_config?(config)
    return false unless config.respond_to?(:to_hash)
    config = config.to_hash.symbolize_keys
    Build.matrix_keys_for(config).map do |key|
      self.config[key.to_sym] == config[key] || commit.branch == config[key]
    end.inject(:&)
  end

  def log_content=(content)
    create_log! unless log
    log.update_attributes!(content: content, aggregated_at: Time.now)
  end

  private

    def whitelisted_addons
      [:firefox, :hosts]
    end

    def delete_addons(config)
      if config[:addons].is_a?(Hash)
        config[:addons].keep_if { |key, value| whitelisted_addons.include? key.to_sym }
      else
        config.delete(:addons)
      end
    end

    def normalize_config(config)
      config = config ? config.deep_symbolize_keys : {}

      if config[:deploy]
        config[:addons] ||= {}
        config[:addons][:deploy] = config.delete(:deploy)
      end

      config
    end

    def process_env(env)
      env = [env] unless env.is_a?(Array)
      env = normalize_env(env)
      env = if secure_env_enabled?
        yield(env)
      else
        remove_encrypted_env_vars(env)
      end
      env.compact.presence
    end

    def remove_encrypted_env_vars(env)
      env.reject do |var|
        var.is_a?(Hash) && var.has_key?(:secure)
      end
    end

    def normalize_env(env)
      env.map do |line|
        if line.is_a?(Hash) && !line.has_key?(:secure)
          line.map { |k, v| "#{k}=#{v}" }.join(' ')
        else
          line
        end
      end
    end

    def decrypt_addons(addons)
      decrypt(addons)
    end

    def decrypt_env(env)
      env.map do |var|
        decrypt(var) do |var|
          var.dup.insert(0, 'SECURE ') unless var.include?('SECURE ')
        end
      end
    rescue
      {}
    end

    def decrypt(v, &block)
      repository.key.secure.decrypt(v, &block)
    end
end
