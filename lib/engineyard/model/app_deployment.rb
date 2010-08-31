module EY
  module Model
    class AppDeployment < ApiStruct.new(:id, :environment_name, :app_name, :repo, :account, :api)
      @@app_deployments = {}

      def self.match_one!(options)
        raise ArgumentError if options.empty?

        candidates = @@app_deployments.values

        candidates = filter_candidates(:account, options, candidates)

        app_candidates =if options[:app_name]
          filter_candidates(:app_name, options, candidates)
        elsif options[:repo]
          candidates.select {|c| c.repo == options[:repo] }
        end

        environment_candidates = filter_candidates(:environment_name, options, candidates)
        candidates = app_candidates & environment_candidates

        if candidates.empty?
          if environment_candidates.empty?
            message = "Could not find any matching environments."
          elsif app_candidates.empty?
            message = "Could not find any matching applications."
          else
            message = "The matched apps & environments do not correspond with each other.\n"
            message << "Applications:\n"
            app_candidates.map{|ad| ad.app_name}.uniq.each do |app_name|
              app = app_candidates.first.api.apps.named(app_name)
              message << "\t#{app.name}\n"
              app.environments.each do |env|
                message << "\t\t#{env.name} # ey deploy -e #{env.name} -a #{app.name}\n"
              end
            end
          end
          raise NoMatchesError.new(message)
        elsif candidates.size > 1
          message = "Multiple app deployments possible, please be more specific:\n\n"
          candidates.map{|c| c.app_name}.uniq.each do |app_name|
            message << "#{app_name}\n"
            candidates.select {|x| x.app_name == app_name }.map{|x| x.environment_name}.uniq.each do |env_name|
              message << "\t#{env_name} # ey deploy -e #{env_name} -a #{app_name}\n"
            end
          end
          raise MultipleMatchesError.new(message)
        end
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
