# Copyright (c) 2009-2011 VMware, Inc.

require File.expand_path("../spec_helper", __FILE__)

describe VCAP::CloudController::App do
  let(:app_obj) { VCAP::CloudController::Models::App.make }
  let(:app_space) { VCAP::CloudController::Models::AppSpace.make }
  let(:runtime) { VCAP::CloudController::Models::Runtime.make }
  let(:framework) { VCAP::CloudController::Models::Framework.make }

  # FIXME: make app_space_id a relation check that checks the id and the url
  # part.  do everywhere
  it_behaves_like "a CloudController API", {
    :path                => "/v2/apps",
    :model               => VCAP::CloudController::Models::App,
    :basic_attributes    => [:name, :app_space_guid, :runtime_guid, :framework_guid],
    :required_attributes => [:name, :app_space_guid, :runtime_guid, :framework_guid],
    :unique_attributes   => [:name, :app_space_guid],

    :many_to_one_collection_ids => {
      :app_space       => lambda { |app| VCAP::CloudController::Models::AppSpace.make  },
      :framework       => lambda { |app| VCAP::CloudController::Models::Framework.make },
      :runtime         => lambda { |app| VCAP::CloudController::Models::Runtime.make   }
    },
    :one_to_many_collection_ids  => {
      :service_bindings   =>
       lambda { |app|
          service_binding = VCAP::CloudController::Models::ServiceBinding.make
          service_binding.service_instance.app_space = app.app_space
          service_binding
       }
    }
  }

  describe "validations" do
    let(:app_obj)   { VCAP::CloudController::Models::App.make }
    let(:decoded_response) { Yajl::Parser.parse(last_response.body) }

    let(:admin_headers) do
      user = VCAP::CloudController::Models::User.make(:admin => true)
      headers_for(user)
    end

    describe "env" do
      it "should allow an empty environment" do
        hash = {}
        update_hash = { :environment_json => hash }

        put "/v2/apps/#{app_obj.guid}", Yajl::Encoder.encode(update_hash), json_headers(admin_headers)
        last_response.status.should == 201
      end

      it "should allow multiple variables" do
        hash = { :abc => 123, :def => "hi" }
        update_hash = { :environment_json => hash }
        put "/v2/apps/#{app_obj.guid}", Yajl::Encoder.encode(update_hash), json_headers(admin_headers)
        last_response.status.should == 201
      end

      [ "VMC", "vmc", "VCAP", "vcap" ].each do |k|
        it "should not allow entries to start with #{k}" do
          hash = { :abc => 123, "#{k}_abc" => "hi" }
          update_hash = { :environment_json => hash }
          put "/v2/apps/#{app_obj.guid}", Yajl::Encoder.encode(update_hash), json_headers(admin_headers)
          last_response.status.should == 400
          decoded_response["description"].should match /environment_json reserved_key:#{k}_abc/
        end
      end
    end
  end

  describe "Permissions" do
    include_context "permissions"

    before do
      @obj_a = Models::App.make(:app_space => @app_space_a)
      @obj_b = Models::App.make(:app_space => @app_space_b)
    end

    let(:creation_req_for_a) do
      Yajl::Encoder.encode(:name => Sham.name,
                           :app_space_guid => @app_space_a.guid,
                           :framework_guid => Models::Framework.make.guid,
                           :runtime_guid => Models::Runtime.make.guid)
    end

    let(:update_req_for_a) do
      Yajl::Encoder.encode(:name => Sham.name)
    end

    describe "Org Level Permissions" do
      describe "OrgManager" do
        let(:member_a) { @org_a_manager }
        let(:member_b) { @org_b_manager }

        include_examples "permission checks", "OrgManager",
          :model => VCAP::CloudController::Models::App,
          :path => "/v2/apps",
          :enumerate => 0,
          :create => :not_allowed,
          :read => :not_allowed,
          :modify => :not_allowed,
          :delete => :not_allowed
      end

      describe "OrgUser" do
        let(:member_a) { @org_a_member }
        let(:member_b) { @org_b_member }

        include_examples "permission checks", "OrgUser",
          :model => VCAP::CloudController::Models::App,
          :path => "/v2/apps",
          :enumerate => 0,
          :create => :not_allowed,
          :read => :not_allowed,
          :modify => :not_allowed,
          :delete => :not_allowed
      end

      describe "BillingManager" do
        let(:member_a) { @org_a_billing_manager }
        let(:member_b) { @org_b_billing_manager }

        include_examples "permission checks", "BillingManager",
          :model => VCAP::CloudController::Models::App,
          :path => "/v2/apps",
          :enumerate => 0,
          :create => :not_allowed,
          :read => :not_allowed,
          :modify => :not_allowed,
          :delete => :not_allowed
      end

      describe "Auditor" do
        let(:member_a) { @org_a_auditor }
        let(:member_b) { @org_b_auditor }

        include_examples "permission checks", "Auditor",
          :model => VCAP::CloudController::Models::App,
          :path => "/v2/apps",
          :enumerate => 0,
          :create => :not_allowed,
          :read => :not_allowed,
          :modify => :not_allowed,
          :delete => :not_allowed
      end
    end

    describe "App Space Level Permissions" do
      describe "AppSpaceManager" do
        let(:member_a) { @app_space_a_manager }
        let(:member_b) { @app_space_b_manager }

        include_examples "permission checks", "AppSpaceManager",
          :model => VCAP::CloudController::Models::App,
          :path => "/v2/apps",
          :enumerate => 0,
          :create => :not_allowed,
          :read => :allowed,
          :modify => :not_allowed,
          :delete => :not_allowed
      end

      describe "Developer" do
        let(:member_a) { @app_space_a_developer }
        let(:member_b) { @app_space_b_developer }

        include_examples "permission checks", "Developer",
          :model => VCAP::CloudController::Models::App,
          :path => "/v2/apps",
          :enumerate => 1,
          :create => :allowed,
          :read => :allowed,
          :modify => :allowed,
          :delete => :allowed
      end

      describe "AppSpaceAuditor" do
        let(:member_a) { @app_space_a_auditor }
        let(:member_b) { @app_space_b_auditor }

        include_examples "permission checks", "AppSpaceAuditor",
          :model => VCAP::CloudController::Models::App,
          :path => "/v2/apps",
          :enumerate => 0,
          :create => :not_allowed,
          :read => :allowed,
          :modify => :not_allowed,
          :delete => :not_allowed
      end
    end
  end

  describe "quota" do
    let(:cf_admin) { Models::User.make(:admin => true) }
    let(:app_obj) { Models::App.make }

    describe "create" do
      it "should fetch a quota token" do
        should_receive_quota_call
        post "/v2/apps", Yajl::Encoder.encode(:name => Sham.name,
                                              :app_space_guid => app_obj.app_space_guid,
                                              :framework_guid => app_obj.framework_guid,
                                              :runtime_guid => app_obj.runtime_guid),
                                              headers_for(cf_admin)
        last_response.status.should == 201
      end
    end

    describe "get" do
      it "should not fetch a quota token" do
        should_not_receive_quota_call
        RestController::QuotaManager.should_not_receive(:fetch_quota_token)
        get "/v2/apps/#{app_obj.guid}", {}, headers_for(cf_admin)
        last_response.status.should == 200
      end
    end

    describe "update" do
      it "should fetch a quota token" do
        should_receive_quota_call
        put "/v2/apps/#{app_obj.guid}",
            Yajl::Encoder.encode(:name => "#{app_obj.name}_renamed"),
            headers_for(cf_admin)
        last_response.status.should == 201
      end
    end

    describe "delete" do
      it "should fetch a quota token" do
        should_receive_quota_call
        delete "/v2/apps/#{app_obj.guid}", {}, headers_for(cf_admin)
        last_response.status.should == 204
      end
    end
  end
end
