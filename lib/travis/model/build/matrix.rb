require 'active_support/concern'
require 'active_support/core_ext/hash/keys'
require 'core_ext/hash/deep_symbolize_keys'

class Build

  # A Build contains a number of Job::Test instances that make up the build
  # matrix.
  #
  # The matrix is defined in the build configuration (`.travis.yml`) and
  # expanded (evaluated and instantiated) when the Build is created.
  #
  # A build matrix has 1 to 3 dimensions and can be defined by specifying
  # multiple values for either of:
  #
  #  * a language/vm variant (e.g. 1.9.2, rbx, jruby for a Ruby build)
  #  * a dependency definition (e.g. a Gemfile for a Ruby build)
  #  * an arbitrary env key that can be used from within the test suite in
  #    order to branch out specific variations of the test run
  module Matrix
    require 'travis/model/build/matrix/config'
    extend ActiveSupport::Concern
    ENV_KEYS = [:rvm, :gemfile, :env, :otp_release, :php, :node_js, :scala, :jdk, :python, :perl, :compiler, :go, :xcode_sdk, :xcode_scheme]


    module ClassMethods
      def matrix?(config)
        config.values_at(*ENV_KEYS).compact.any? { |value| value.is_a?(Array) && value.size > 1 }
      end

      def matrix_keys_for(config)
        keys = ENV_KEYS + [:branch]
        keys & config.keys.map(&:to_sym)
      end
    end

    # Return only the child builds whose config matches against as passed hash
    # e.g. build.matrix_for(rvm: '1.8.7', env: 'DB=postgresql')
    def matrix_for(config)
      config.blank? ? matrix : matrix.select { |job| job.matrix_config?(config) }
    end

    def matrix_finished?(*)
      matrix.all?(&:finished?)
    end

    def matrix_duration
      matrix_finished? ? matrix.inject(0) { |duration, job| duration + job.duration.to_i } : nil
    end

    def matrix_state
      tests = matrix.reject { |test| test.allow_failure? }
      if tests.blank?
        :passed
      elsif tests.any?(&:canceled?)
        :canceled
      elsif tests.any?(&:errored?)
        :errored
      elsif tests.any?(&:failed?)
        :failed
      elsif tests.all?(&:passed?)
        :passed
      else
        raise StandardError, "Invalid job state (#{tests.map(&:state)})"
      end
    end

    # expand the matrix (i.e. create test jobs) and update the config for each job
    def expand_matrix
      matrix_config.expand.each_with_index do |row, ix|
        attributes = self.attributes.slice(*Job.column_names - ['status', 'result']).symbolize_keys
        attributes.merge!(
          :owner => owner,
          :number => "#{number}.#{ix + 1}",
          :config => expand_config(row),
          :log => Log.new
        )
        matrix.build(attributes)
      end
      matrix_allow_failures # TODO should be able to join this with the loop above
      matrix
    end

    def expand_matrix!
      expand_matrix
      save!
    end

    protected

      def expand_config(row)
        hash = {}
        row.each do |key, values|
          hash[key] = values
        end

        config.merge(hash)
      end

      def matrix_config
        @matrix_config ||= Config.new(self)
      end

      # TODO: this is used in tests, fix this, it's not needed anymore, there is
      #       you can use matrix_config.expand method
      def expand_matrix_config(config)
        config.expand
      end

      def matrix_allow_failures
        allow_configs = matrix_config.matrix_settings[:allow_failures] || []
        allow_configs.each do |config|
          matrix_for(config).each { |m| m.allow_failure = true }
        end
      end
  end
end
