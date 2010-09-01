require 'spec_helper'

describe EY::Model::AppDeployment do
  def new_app_deployment(options)
    @id ||= 0
    @id += 1
    EY::Model::AppDeployment.from_hash({"id" => @id}.merge(options))
  end

  let(:production) { new_app_deployment("environment_name" => "app_production", "app_name" => "app", "account" => "ey", "repository_uri" => "git://github.com/repo/app.git") }
  let(:staging)    { new_app_deployment("environment_name" => "app_staging"   , "app_name" => "app",           "account" => "ey", "repository_uri" => "git://github.com/repo/app.git") }
  let(:big)        { new_app_deployment("environment_name" => "bigapp_staging", "app_name" => "bigapp",        "account" => "ey", "repository_uri" => "git://github.com/repo/bigapp.git") }
  let(:ey_dup)     { new_app_deployment("environment_name" => "app_duplicate" , "app_name" => "app_duplicate", "account" => "ey", "repository_uri" => "git://github.com/repo/dup.git") }
  let(:me_dup)     { new_app_deployment("environment_name" => "app_duplicate" , "app_name" => "app_duplicate", "account" => "me", "repository_uri" => "git://github.com/repo/dup.git") }

  before do
    production
    staging
    big
    ey_dup
    me_dup
  end

  def resolve(*args)
    described_class.match_one!(*args)
  end

  def repo(url)
    mock("repo", :urls => [url])
  end

  describe "#match_one!" do
    it "raises argument error if the conditions are empty" do
      lambda { resolve({}) }.should raise_error(ArgumentError)
    end

    it "raises when there is no app match" do
      lambda { resolve(:environment_name => 'app_duplicate', :app_name => 'smallapp') }.should raise_error(EY::InvalidAppError)
    end

    it "raises when the git repo does not match any apps" do
      lambda { resolve(:environment_name => 'app_duplicate', :repo => repo("git://github.com/no-such/app.git")) }.should raise_error(EY::NoAppError)
    end

    it "raises when there is no environment match" do
      lambda { resolve(:environment_name => 'gibberish', :app_name => 'app') }.should raise_error(EY::NoEnvironmentError)
    end

    it "raises when there are no matches" do
      lambda { resolve(:environment_name => 'app_duplicate', :app_name => 'bigapp') }.should raise_error(EY::NoMatchesError)
      lambda { resolve(:repo => repo("git://github.com/repo/app.git"), :environment_name => 'app_duplicate') }.should raise_error(EY::NoMatchesError)
    end

    it "raises when there is more than one match" do
      lambda { resolve(:app_name => "app") }.should raise_error(EY::MultipleMatchesError)
      lambda { resolve(:account => "ey", :app_name => "app") }.should raise_error(EY::MultipleMatchesError)
      lambda { resolve(:repo => repo("git://github.com/repo/dup.git")) }.should raise_error(EY::MultipleMatchesError)
      lambda { resolve(:repo => repo("git://github.com/repo/app.git")) }.should raise_error(EY::MultipleMatchesError)
    end

    it "returns one deployment whene there is only one match" do
      resolve(:account => "ey", :app_name => "big").should == big
      resolve(:environment_name => "production").should == production
      resolve(:repo => repo("git://github.com/repo/bigapp.git")).should == big
      resolve(:repo => repo("git://github.com/repo/app.git"), :environment_name => "staging").should == staging
    end

    it "returns the match when an app is specified even when there is a repo" do
      resolve(:account => "ey", :app_name => "bigapp", :repo => repo("git://github.com/repo/app.git")).should == big
    end

    it "returns the specific match even if there is a partial match" do
      resolve(:environment_name => 'app_staging', :app_name => 'app').should == staging
      resolve(:environment_name => "app_staging").should == staging
      resolve(:app_name => "app", :environment_name => "staging").should == staging
    end

    it "scopes searches under the correct account" do
      resolve(:account => "ey", :environment_name => "dup").should == ey_dup
      resolve(:account => "ey", :app_name => "dup").should == ey_dup
      resolve(:account => "me", :environment_name => "dup").should == me_dup
      resolve(:account => "me", :app_name => "dup").should == me_dup
    end
  end
end
