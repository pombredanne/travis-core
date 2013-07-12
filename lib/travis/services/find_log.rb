module Travis
  module Services
    class FindLog < Base
      register :find_log

      def run(options = {})
        result if result
      end

      private

        def result
          @result ||= if params[:id]
            scope(:log).find_by_id(params[:id])
          elsif params[:job_id]
            scope(:log).where(job_id: params[:job_id]).first
          end
        end
    end
  end
end
