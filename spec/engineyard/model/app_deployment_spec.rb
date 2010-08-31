require 'spec_helper'

describe EY::Model::AppDeployment do
  let(:production) { EY::Model::AppDeployment.from_hash("id" => 1234, "environment" => "app_production", "app" => "app",           "account" => "ey", "repo" => "git://github.com/repo/app.git") }
  let(:staging)    { EY::Model::AppDeployment.from_hash("id" => 4321, "environment" => "app_staging"   , "app" => "app",           "account" => "ey", "repo" => "git://github.com/repo/app.git") }
  let(:big)        { EY::Model::AppDeployment.from_hash("id" => 8765, "environment" => "bigapp_staging", "app" => "bigapp",        "account" => "ey", "repo" => "git://github.com/repo/bigapp.git") }
  let(:ey_dup)     { EY::Model::AppDeployment.from_hash("id" => 4532, "environment" => "app_duplicate" , "app" => "app_duplicate", "account" => "ey", "repo" => "git://github.com/repo/dup.git") }
  let(:me_dup)     { EY::Model::AppDeployment.from_hash("id" => 4533, "environment" => "app_duplicate" , "app" => "app_duplicate", "account" => "me", "repo" => "git://github.com/repo/dup.git") }

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

  describe "#match_one!" do
    it "raises argument error if the conditions are empty" do
      lambda { resolve({}) }.should raise_error(ArgumentError)
    end

    it "raises when there are no matches" do
      lambda { resolve(:environment => 'app_duplicate', :app => 'bigapp') }.should raise_error(EY::NoMatchesError)
      lambda { resolve(:repo => "git://github.com/repo/app.git", :environment => 'app_duplicate') }.should raise_error(EY::NoMatchesError)
    end

    it "raises when there is more than one match" do
      lambda { resolve(:app => "app") }.should raise_error(EY::MultipleMatchesError)
      lambda { resolve(:account => "ey", :app => "app") }.should raise_error(EY::MultipleMatchesError)
      lambda { resolve(:repo => "git://github.com/repo/dup.git") }.should raise_error(EY::MultipleMatchesError)
      lambda { resolve(:repo => "git://github.com/repo/app.git") }.should raise_error(EY::MultipleMatchesError)
    end

    it "returns one deployment whene there is only one match" do
      resolve(:account => "ey", :app => "big").should == big
      resolve(:environment => "production").should == production
      resolve(:repo => "git://github.com/repo/bigapp.git").should == big
      resolve(:repo => "git://github.com/repo/app.git", :environment => "staging").should == staging
    end

    it "returns the match when an app is specified even when there is a repo" do
      resolve(:account => "ey", :app => "bigapp", :repo => "git://github.com/repo/app.git").should == big
    end

    it "returns the specific match even if there is a partial match" do
      resolve(:environment => 'app_staging', :app => 'app').should == staging
      resolve(:environment => "app_staging").should == staging
      resolve(:app => "app", :environment => "staging").should == staging
    end

    it "scopes searches under the correct account" do
      resolve(:account => "ey", :environment => "dup").should == ey_dup
      resolve(:account => "ey", :app => "dup").should == ey_dup
      resolve(:account => "me", :environment => "dup").should == me_dup
      resolve(:account => "me", :app => "dup").should == me_dup
    end
  end
end
