require 'travis/api/v1'

module Travis
  module Api
    module V0
      module Pusher
        class Build
          class Created < Build
            include V1::Helpers::Legacy

            def data
              { 'build' => build_data, 'repository' => repository_data }
            end

            def build_data
              {
                'id' => build.id,
                'repository_id' => build.repository_id,
                'job_ids' => build.matrix.map(&:id),
                'number' => build.number,
                'config' => build.obfuscated_config.stringify_keys,
                'state' => build.state.to_s,
                'result' => legacy_build_result(build),
                'started_at' => format_date(build.started_at),
                'finished_at' => format_date(build.finished_at),
                'duration' => nil,
                'commit' => commit.commit,
                'commit_id' => commit.id,
                'branch' => commit.branch,
                'message' => commit.message,
                'compare_url' => commit.compare_url,
                'committed_at' => format_date(commit.committed_at),
                'author_name' => commit.author_name,
                'author_email' => commit.author_email,
                'committer_name' => commit.committer_name,
                'committer_email' => commit.committer_email,
                'event_type' => build.event_type,
                'pull_request' => build.pull_request?,
                'pull_request_title' => build.pull_request_title,
                'pull_request_number' => build.pull_request_number,
                'job_ids' => build.matrix.map(&:id),
                'state' => build.state.to_s
              }
            end

            def repository_data
              {
                'id' => repository.id,
                'slug' => repository.slug,
                'description' => repository.description,
                'last_build_id' => repository.last_build_id,
                'last_build_number' => repository.last_build_number,
                'last_build_started_at' => format_date(repository.last_build_started_at),
                'last_build_finished_at' => format_date(repository.last_build_finished_at),
                'last_build_duration' => repository.last_build_duration,
                'last_build_state' => repository.last_build_state.try(:to_s),
                'last_build_result' => legacy_repository_last_build_result(repository),
                'last_build_language' => nil
              }
            end
          end
        end
      end
    end
  end
end

