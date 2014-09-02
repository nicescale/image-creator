require 'spec_helper'

describe FP::Vars do
  let(:service_id) {
    '53fd3d116c6f630895060000'
  }
  let(:role) {
    'slave'
  }
  let(:cluster_id) {
    '02f6170ccc8b10f84913'
  }

  let(:global_vars) {
    {
      service_id => {
        'meta' => {
          'tags' => [role],
          'cluster_id' => cluster_id
        },
        'redis' => {
          'port' => '6379'
        },
        'other' => 'foo'
      }
    }
  }

  let(:module_vars) {
    JSON.parse(<<-EOS
{
  "meta": {
    "global": {
      "meta": [
        "cluster_id",
        "service_id",
        "tag"
      ],
      "redis": [
        "port"
      ]
    },
    "tags": [
      "redis",
      "slave"
    ],
    "deploy_tags": {
      "service_name": "Redis_slave",
      "role": "slave",
      "image_name": "nicescale/redis",
      "image_version": "latest",
      "instance_ids": [
        "53fb313c6c6f6331e80b0000"
      ]
    }
  },
  "redis": {
    "port": "6379",
    "timeout": "0",
    "tcp_keepalive": "60",
    "logfile": "",
    "databases": "16"
  },
  "foo": "bar"
}
    EOS
    )
  }

  let(:project_manifest) {
    sample_json = File.expand_path('../../fixtures/project-metadata.json', __FILE__)
    IO.read(sample_json)
  }

  let(:auto_vars) {
    {
      service_id => {
        'ips' => ['1.2.3.4', '5.6.7.8']
      }
    }
  }

  let(:nicescale_config) {
    JSON.parse %q[{"init_conf_path":"/etc/.fp/credentials.conf","mco_client_conf_path":"/opt/nicescale/support/etc/mcollective/client.cfg","mco_server_conf_path":"/opt/nicescale/support/etc/mcollective/server.cfg","dynamic_params_path":"/opt/nicescale/support/env/dynamic_vars.json","project_metadata_conf_path":"/opt/nicescale/support/etc/project-metadata.json","service_conf_path":"/etc/puppet/pdata/modules/%s.json","dynamic_facter_install_path":"/opt/nicescale/support/bin/dynamic_facter.rb"}]
  }

  let(:init_config) {
    %Q[uuid=53fb313c6c6f6331e80b0000\nproject_id=fakefake]
  }

  before(:each) {
    cfg = double('config', nicescale_config)
    allow(FP::Config).to receive(:instance).and_return(cfg)

    allow(File).to receive(:read).with(FP::Config.instance.dynamic_params_path).and_return(auto_vars.to_json)
    allow(File).to receive(:read).with(FP::Config.instance.project_metadata_conf_path).and_return(project_manifest)
    allow(File).to receive(:read).with(FP::Config.instance.service_conf_path % ('m' + service_id)).and_return(module_vars.to_json)
    allow(File).to receive(:read).with(FP::Config.instance.init_conf_path).and_return(init_config)
  }

  after(:each) {
    ENV.delete('CFAGENT_PREPARE')
  }

  describe "::get_global_var_by_service" do
    it "should return the value of the specified key" do
      allow(File).to receive(:exists?).and_return(true)
      expect(
        FP::Vars.get_global_var_by_service(service_id, 'port', 'redis')
      ).to eq '6379'
    end

    it "should raise an error when the specified key dosen't exist" do
      allow(File).to receive(:exists?).and_return(true)
      expect {
        FP::Vars.get_global_var_by_service(service_id, 'moo', 'haha')
      }.to raise_error(FP::Vars::NotFound)
    end
  end

  describe "::get_global_var_by_cluster" do
    it "should return the value of the specified key in the givien cluster" do
      allow(File).to receive(:exists?).and_return(true)
      expect(
        FP::Vars.get_global_var_by_cluster(cluster_id, role, 'port', 'redis')
      ).to eq '6379'
    end

    it "should raise an error when the specified key doesn't exist" do
      allow(File).to receive(:exists?).and_return(true)
      expect {
        FP::Vars.get_global_var_by_cluster(cluster_id, role, 'moo', 'redis')
      }.to raise_error(FP::Vars::NotFound)
    end
  end

  describe "::get_auto_var_by_service" do
    it "return the value of the key" do
      allow(File).to receive(:mtime).and_return(Time.now)
      allow(File).to receive(:exists?).and_return(true)
      expect(FP::Vars.get_auto_var_by_service(service_id, 'ips')).to eq ['1.2.3.4', '5.6.7.8']
    end

    context "when cache TTL is exceeded" do
      it "should call the auto variable script to gather variables" do
        allow(File).to receive(:mtime).and_return(Time.now - 80)
        allow(File).to receive(:exists?).and_return(true)
        expect(FP::Vars).to receive(:'`').with(FP::Config.instance.dynamic_facter_install_path)
        FP::Vars.get_auto_var_by_service(service_id, 'ips')
      end
    end

    context "when auto variable cache file not exists" do
      it "should call the auto variable script to gather variables" do
        allow(File).to receive(:mtime).and_return(Time.now)
        allow(File).to receive(:exists?).and_return(false)
        expect(FP::Vars).to receive(:'`').with(FP::Config.instance.dynamic_facter_install_path)
        FP::Vars.get_auto_var_by_service(service_id, 'ips')
      end
    end
  end

  describe "::get_service_var" do
    it "should return the correct value" do
      allow(File).to receive(:exists?).and_return(true)
      expect(FP::Vars.get_service_var(service_id, 'port', 'redis')).to eq '6379'
    end

    context "when no namespaces are specified" do
      it "should return the correct value" do
        allow(File).to receive(:exists?).and_return(true)
        expect(FP::Vars.get_service_var(service_id, 'foo')).to eq 'bar'
      end
    end
  end

  describe "::get_cluster_var" do
    it "should return the correct value" do
      allow(File).to receive(:exists?).and_return(true)
      expect(FP::Vars.get_cluster_var(cluster_id, role, 'port', 'redis')).to eq '6379'
    end
  end

  describe "::services_in_this_project" do
    it "should return all the service IDs of the project" do
      allow(File).to receive(:exists?).and_return(true)
      expect(FP::Vars.services_in_this_project).to be_an(Array)
      expect(FP::Vars.services_in_this_project.count).to eq(6)
    end
  end

  context 'when the ENV["CFAGENT_PREPARE"] is set' do
    it '::get_auto_var_by_service should return nil' do
      ENV['CFAGENT_PREPARE'] = 'true'
      expect(FP::Vars.get_auto_var_by_service(service_id, 'ips')).to be_nil
    end
  end

  describe "::get_connections" do
    it "should return the connection config options of the given service" do
      allow(File).to receive(:exists?).and_return(true)
      conn = FP::Vars.get_connections(service_id)
      expect(conn.keys.first).to eq('53fd3d116c6f630895030000')
      expect(conn.values.first).to eq({"key" => "var"})
    end
  end

  describe "::get_service_name" do
    it {
      allow(File).to receive(:exists?).and_return(true)
      expect(FP::Vars.get_service_name(service_id)).to eq('Redis_slave')
    }
  end
end
