require 'spec_helper'

describe "ey web enable" do
  given "integration"
  use_git_repo('default')

  before(:all) do
    api_scenario "one app, one environment"
  end

  it "tells eysd to take down the maintenance page" do
    ey "web enable"
    @ssh_commands.should have_command_like(/eysd deploy disable_maintenance_page --app rails232app/)
  end
end

describe "ey web enable" do
  given "integration"

  def command_to_run(opts)
    "web enable #{opts[:env]}"
  end

  def verify_ran(scenario)
    @out.should =~ /Taking down maintenance page.*#{scenario[:environment]}/
  end

  it_should_behave_like "it takes an environment name"
end
