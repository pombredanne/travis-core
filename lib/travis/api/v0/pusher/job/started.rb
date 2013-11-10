module Travis
  module Api
    module V0
      module Pusher
        class Job
          class Started < Job
            include V1::Helpers::Legacy

            def data
              {
                'id' => job.id,
                'build_id' => job.source_id,
                'repository_id' => job.repository_id,
                'repository_slug' => job.repository.slug,
                'number' => job.number,
                'state' => job.state.to_s,
                'result' => legacy_job_result(job),
                'started_at' => format_date(job.started_at),
                'finished_at' => format_date(job.finished_at),
                'worker' => 'ruby3.worker.travis-ci.org:travis-ruby-4'
              }
            end
          end
        end
      end
    end
  end
end
