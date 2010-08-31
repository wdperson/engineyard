module EY
  module Model
    class AppDeployment < ApiStruct.new(:id, :environment_name, :app_name, :repo, :account, :api)
      @@app_deployments = {}

      def self.match_one!(options)
        raise ArgumentError if options.empty?

        candidates = @@app_deployments.values

        candidates = filter_candidates(:account, options, candidates)

        if options[:app_name]
          candidates = filter_candidates(:app_name, options, candidates)
        elsif options[:repo]
          candidates = candidates.select {|c| c.repo == options[:repo] }
        end

        candidates = filter_candidates(:environment_name, options, candidates)

        raise NoMatchesError if candidates.empty?
        raise MultipleMatchesError if candidates.size > 1
        candidates.first
      end

      def self.from_hash(*args)
        app_deployment = super
        @@app_deployments[app_deployment.id] ||= app_deployment
        app_deployment
      end

      def app
        @app ||= api.apps.named(app_name)
      end

      def environment
        @environment ||= api.environments.named(environment_name)
      end

      private

      def self.filter_candidates(type, options, candidates)
        if options[type] && candidates.any?{|c| c.send(type) == options[type] }
          candidates.select {|c| c.send(type) == options[type] }
        elsif options[type]
          candidates.select {|c| c.send(type)[options[type]] }
        else
          candidates
        end
      end
    end
  end
end
