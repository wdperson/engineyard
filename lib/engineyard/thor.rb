require 'thor'

module EY
  module UtilityMethods
    protected
    def api
      @api ||= EY::CLI::API.new
    end

    def repo
      @repo ||= EY::Repo.new
    end

    def loudly_check_engineyard_serverside(environment)
      environment.ensure_engineyard_serverside_present do |action|
        case action
        when :installing
          EY.ui.warn "Instance does not have server-side component installed"
          EY.ui.info "Installing server-side component..."
        when :upgrading
          EY.ui.info "Upgrading server-side component..."
        else
          # nothing slow is happening, so there's nothing to say
        end
      end
    end

    # if an app is supplied, it is used as a constraint for implied environment lookup
    def fetch_environment(env_name, app = nil)
      env_name ||= EY.config.default_environment
      if env_name
        (app || api).environments.match_one!(env_name)
      else
        (app || api.app_for_repo!(repo)).sole_environment!
      end
    end

    def fetch_environment_without_app(env_name)
      fetch_environment(env_name)
    rescue EY::AmbiguousGitUriError
      raise EY::AmbiguousEnvironmentGitUriError.new(api.environments)
    end

    def fetch_app_deployment(app_name = nil, environment_name = nil)
      api.app_deployments
      EY::Model::AppDeployment.match_one!(:app_name => app_name,
                                          :environment_name => environment_name,
                                          :repo => repo,
                                          :api => api)
    end

    def get_apps(all_apps = false)
      if all_apps
        api.apps
      else
        api.apps_for_repo(repo)
      end
    end

  end # UtilityMethods

  class Thor < ::Thor
    include UtilityMethods

    no_tasks do
      def self.subcommand_help(cmd)
        desc "#{cmd} help [COMMAND]", "Describe all subcommands or one specific subcommand."
        class_eval <<-RUBY
          def help(*args)
            if args.empty?
              EY.ui.say "usage: #{banner_base} #{cmd} COMMAND"
              EY.ui.say
              subcommands = self.class.printable_tasks.sort_by{|s| s[0] }
              subcommands.reject!{|t| t[0] =~ /#{cmd} help$/}
              EY.ui.print_help(subcommands)
              EY.ui.say self.class.send(:class_options_help, EY.ui)
              EY.ui.say "See #{banner_base} #{cmd} help COMMAND" +
                " for more information on a specific subcommand." if args.empty?
            else
              super
            end
          end
        RUBY
      end

      def self.banner_base
        "ey"
      end

      def self.banner(task, task_help = false, subcommand = false)
        subcommand_banner = to_s.split(/::/).map{|s| s.downcase}[2..-1]
        subcommand_banner = if subcommand_banner.size > 0
                              subcommand_banner.join(' ')
                            else
                              nil
                            end

        task = (task_help ? task.formatted_usage(self, false, subcommand) : task.name)
        [banner_base, subcommand_banner, task].compact.join(" ")
      end

      def self.handle_no_task_error(task)
        raise UndefinedTaskError, "Could not find command #{task.inspect}."
      end

      def self.subcommand(name, klass)
        @@subcommand_class_for ||= {}
        @@subcommand_class_for[name] = klass
        super
      end

      def self.subcommand_class_for(name)
        @@subcommand_class_for ||= {}
        @@subcommand_class_for[name]
      end

    end

    protected

    def self.exit_on_failure?
      true
    end

  end
end
