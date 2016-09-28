require 'models/runtime/app_bits_package'
require 'models/runtime/security_group'
require 'models/runtime/security_groups_space'
require 'models/runtime/app_usage_event'
require 'models/runtime/auto_detection_buildpack'
require 'models/runtime/app_event'
require 'models/runtime/app'
require 'models/runtime/droplet'
require 'models/runtime/buildpack'
require 'models/runtime/buildpack_bits_delete'
require 'models/runtime/domain'
require 'models/runtime/shared_domain'
require 'models/runtime/space_reserved_route_ports'
require 'models/runtime/private_domain'
require 'models/runtime/event'
require 'models/runtime/feature_flag'
require 'models/runtime/environment_variable_group'
require 'models/runtime/custom_buildpack'
require 'models/runtime/organization'
require 'models/runtime/organization_routes'
require 'models/runtime/organization_reserved_route_ports'
require 'models/runtime/quota_definition'
require 'models/runtime/quota_constraints/max_private_domains_policy'
require 'models/runtime/quota_constraints/max_routes_policy'
require 'models/runtime/quota_constraints/max_reserved_route_ports_policy'
require 'models/runtime/quota_constraints/max_service_instance_policy'
require 'models/runtime/quota_constraints/paid_service_instance_policy'
require 'models/runtime/quota_constraints/max_service_keys_policy'
require 'models/runtime/constraints/max_disk_quota_policy'
require 'models/runtime/constraints/min_disk_quota_policy'
require 'models/runtime/constraints/custom_buildpack_policy'
require 'models/runtime/constraints/app_environment_policy'
require 'models/runtime/constraints/metadata_policy'
require 'models/runtime/constraints/max_memory_policy'
require 'models/runtime/constraints/max_instance_memory_policy'
require 'models/runtime/constraints/min_memory_policy'
require 'models/runtime/constraints/ports_policy'
require 'models/runtime/constraints/instances_policy'
require 'models/runtime/constraints/max_app_instances_policy'
require 'models/runtime/constraints/max_app_tasks_policy'
require 'models/runtime/constraints/health_check_policy'
require 'models/runtime/constraints/docker_policy'
require 'models/runtime/constraints/diego_to_dea_policy'
require 'models/runtime/route'
require 'models/runtime/space'
require 'models/runtime/space_routes'
require 'models/runtime/space_quota_definition'
require 'models/runtime/stack'
require 'models/runtime/user'
require 'models/runtime/locking'
require 'models/runtime/route_mapping'

require 'models/services/service'
require 'models/services/service_binding'
require 'models/services/route_binding'
require 'models/services/service_dashboard_client'
require 'models/services/service_instance'
require 'models/services/managed_service_instance'
require 'models/services/service_instance_operation'
require 'models/services/user_provided_service_instance'
require 'models/services/service_broker'
require 'models/services/service_plan'
require 'models/services/service_plan_visibility'
require 'models/services/service_usage_event'
require 'models/services/service_key'
require 'models/services/route_binding'

require 'models/job'

require 'models/v3/persistence/app_model'
require 'models/v3/persistence/route_mapping_model'
require 'models/v3/persistence/package_model'
require 'models/v3/persistence/droplet_model'
require 'models/v3/persistence/buildpack_lifecycle_data_model'
require 'models/v3/persistence/docker_lifecycle_data_model'
require 'models/v3/persistence/package_docker_data_model'
require 'models/v3/persistence/service_binding_model'
require 'models/v3/persistence/task_model'

#------------------------------------------------------------------------------
# Code to make swagger.yml
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# From pry:
#
# all_classes = VCAP::CloudController.constants.select {|c| Class === VCAP::CloudController.const_get(c)}
# all_classes.select {|c| Object.const_get("VCAP::CloudController").const_get(c.to_s).superclass.name == 'Sequel::Model' }
# all_classes.each do |a_class|
# end

# puts new(::VCAP::CloudController::TaskModel.make).to_hash.to_yaml
# puts(::VCAP::CloudController::Presenters::V3::TaskPresenter.new(::VCAP::CloudController::TaskModel.make).to_hash)
#------------------------------------------------------------------------------


require 'yaml'
require 'machinist'
require 'machinist/sequel'
require '/root/cf-dotnet-sdk-builder/cloud_controller_ng/spec/support/fakes/blueprints'

model = ::VCAP::CloudController::TaskModel.make
presenter = ::VCAP::CloudController::Presenters::V3::TaskPresenter.new(model)

puts presenter.to_hash

swagger = YAML.load <<'...'
swagger: "2.0"
info:
  description: CCv3
  version: "2.0.0"
  title: CCv3
basePath: /v3
schemes:
- http
paths: {}
definitions: {}
...

def get_request_definition(class_name)
  return unless class_name
  the_class = eval("VCAP::CloudController::#{class_name}")
  keys = the_class::ALLOWED_KEYS
  puts keys
end

def get_response_definition(class_name)
  the_class = eval("VCAP::CloudController::Presenters::V3::#{class_name}")
  
  puts the_class #.to_hash
  puts the_class.to_yaml
end

paths = swagger['paths']
Rails.application.routes.routes.each do |r|
  path = r.path.spec.to_s
  method = r.constraints[:request_method]
  method = method.to_s.sub(/.*\^/, '').sub(/\$.*/, '').downcase
  path.sub! /\(\.:format\)$/, ''
  path.gsub! /:(\w+)/, '{\1}'
  paths[path] = {
    method => {
      'summary' => '...',
      'description' => '...',
    },
  }

  next unless r.defaults[:meta]

  request_class_name = r.defaults[:meta][:request]
  response_class_name = r.defaults[:meta][:response]

  request_definition = get_request_definition(request_class_name)
  response_definition = get_response_definition(response_class_name)
end

File.open('/tmp/swagger.yaml', 'w') { |file| file.write(swagger.to_yaml) }
