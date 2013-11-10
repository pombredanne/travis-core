module Travis
  module Api
    module V2
      module Http
        require 'travis/api/v2/http/accounts'
        require 'travis/api/v2/http/broadcasts'
        require 'travis/api/v2/http/branch'
        require 'travis/api/v2/http/branches'
        require 'travis/api/v2/http/build'
        require 'travis/api/v2/http/builds'
        require 'travis/api/v2/http/events'
        require 'travis/api/v2/http/caches'
        require 'travis/api/v2/http/hooks'
        require 'travis/api/v2/http/job'
        require 'travis/api/v2/http/jobs'
        require 'travis/api/v2/http/log'
        require 'travis/api/v2/http/permissions'
        require 'travis/api/v2/http/repositories'
        require 'travis/api/v2/http/repository'
        require 'travis/api/v2/http/ssl_key'
        require 'travis/api/v2/http/user'
        require 'travis/api/v2/http/workers'
        require 'travis/api/v2/http/worker'
      end
    end
  end
end
