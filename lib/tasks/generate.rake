task :generate do
  $LOAD_PATH.unshift(File.expand_path('../../../lib', __FILE__))

  ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../../Gemfile', __FILE__)

  require 'rubygems'
  require 'bundler/setup'
  require 'cloud_controller'
  require 'irb/completion'
  require 'pry'

  begin
    require File.expand_path('../../../spec/support/bootstrap/db_config.rb', __FILE__)
  rescue LoadError
    # db_config.rb does not exist in a release, but a config with a database should exist there.
  end

  @config_file = File.expand_path('../../../config/cloud_controller.yml', __FILE__)
  unless File.exist?(@config_file)
    warn "#{@config_file} not found. Try running bin/console <PATH_TO_CONFIG_FILE>."
    exit 1
  end
  @config = VCAP::CloudController::Config.from_file(@config_file)
  logger = Logger.new(STDOUT)
  db_config = @config.fetch(:db).merge(log_level: :debug)
  db_config[:database] ||= DbConfig.new.connection_string

  VCAP::CloudController::DB.load_models(db_config, logger)
  VCAP::CloudController::Config.configure_components(@config)

  $LOAD_PATH.unshift(File.expand_path('../../../spec/support', __FILE__))
  require 'machinist/sequel'
  require 'machinist/object'
  require 'fakes/blueprints'

  def get_request_definition(class_name)
    return unless class_name
    the_class = eval("VCAP::CloudController::#{class_name}")
    return the_class::ALLOWED_KEYS
  end

  #should be able to create presenter based on presenter's constructor
  def get_response_definition(model_name, presenter_name)
    return unless  model_name
    begin
     the_model = eval("VCAP::CloudController::#{model_name}")
     model = the_model.make
     the_presenter = eval("VCAP::CloudController::Presenters::V3::#{presenter_name}")
     if the_presenter.instance_method(:initialize).arity == -3
       #create new paginated presenter
       item = model_name.gsub('Model','')
       case item
        when 'Task'
         puts "ITEM=#{item.pluralize}"
         m = eval("VCAP::CloudController::#{item.pluralize}ListMessage").new
         fetcher = eval("VCAP::CloudController::#{item}ListFetcher").new
         data = fetcher.fetch_all(message: m)
         response = eval("VCAP::CloudController::Presenters::V3::PaginatedListPresenter").new(data,"/v3/#{item.pluralize.downcase}", m)
       when 'App'
         puts "ITEM=#{item.pluralize}"
         m = eval("VCAP::CloudController::#{item.pluralize}ListMessage").new
         fetcher = eval("VCAP::CloudController::#{item}ListFetcher").new
         data = fetcher.fetch_all(m)
         response = eval("VCAP::CloudController::Presenters::V3::PaginatedListPresenter").new(data,"/v3/#{item.pluralize.downcase}", m)
       when 'Process'
         puts "ITEM=#{item.pluralize}"
         m = eval("VCAP::CloudController::#{item.pluralize}ListMessage").new
         fetcher = eval("VCAP::CloudController::#{item}ListFetcher").new(m)
         data = fetcher.fetch_all()
         response = eval("VCAP::CloudController::Presenters::V3::PaginatedListPresenter").new(data,"/v3/#{item.pluralize.downcase}", m)
       when 'Droplet','RouteMapping'
         puts "ITEM=#{item.pluralize}"
         m = eval("VCAP::CloudController::#{item.pluralize}ListMessage").new
         fetcher = eval("VCAP::CloudController::#{item}ListFetcher").new(message: m)
         data = fetcher.fetch_all()
         response = eval("VCAP::CloudController::Presenters::V3::PaginatedListPresenter").new(data,"/v3/#{item.pluralize.downcase}", m)
       else
          puts "ITEM=#{item.pluralize}"
          m = eval("VCAP::CloudController::#{item.pluralize}ListMessage").new
          fetcher = eval("VCAP::CloudController::#{item}ListFetcher").new
          data = fetcher.fetch_all(message: m)
          response = eval("VCAP::CloudController::Presenters::V3::PaginatedListPresenter").new(data,"/v3/#{item.pluralize.downcase}", m)
       end
       return response
     else
       response = the_presenter.new(model)
     end
     return response
   rescue => error
     puts error
     File.open("generate.stderr.out","a+") {|f| f.write("#{model_name} -- #{presenter_name} ERR: #{error}\n")}
     return nil
    end
  end

  def get_parameter_type(model_name, parameter_name)
    return unless model_name
    the_model = eval("VCAP::CloudController::#{model_name}")

    if the_model.db_schema.key?(parameter_name)
      type = the_model.db_schema[parameter_name][:type]
    else
      type = nil
    end

    if type.nil? || type == 0
      return 'object'
    end

    return type.to_s.gsub(':','')
  end

  def get_definitions(name, presenter_hash)
    definition = Hash.new

    items = Hash.new
    presenter_hash.keys.each do |key|
       type='string'
       if presenter_hash[key].is_a? Hash
          type= 'object'
       end

       if presenter_hash[key].is_a? Array
          type = 'object'
       end

       items[key.to_s.gsub(':','')] = {
         'type' => type
       }

    end

    definition = {
          'type' => 'object',
          'properties' => items
    }
    return definition
  end

  logger.info "Will be generating swagger when done"

  # List all routes (with verb and action)
  # For each route, determine the controller and message used for a request
  routes = []
  responses = Hash.new
  response_presenters = Hash.new
  Rails.application.routes.routes.each do |rails_route|
    next unless rails_route.defaults[:swagger]

    vb = rails_route.constraints[:request_method].to_s.match(/[A-Z]+/).to_s

    parameters=[]
    path_array =  rails_route.path.spec.to_s.gsub('(.:format)', '').split('/')
    path_array.each do |element|
          if element.include?(':')
            replaced = element.gsub(element,'{'+element.gsub(':','')+'}')
            path_array[path_array.index(element)]=replaced
            parameters << {
                'name' => element.gsub(':',''),
                'required' =>true,
                'in' => 'path',
                'type' => 'string'
             }
          end
      end

  request = rails_route.defaults[:swagger][:request]
  response = get_response_definition(rails_route.defaults[:swagger][:model],rails_route.defaults[:swagger][:response])

  if response != nil
    puts "-----------------------------------------------------------------------------------------------"
    puts rails_route.defaults[:swagger][:model]
    puts rails_route.defaults[:swagger][:response]
    pp response.to_hash()
    response_presenters["#{path_array.join('/')}-#{vb}"] = response
    responses["#{path_array.join('/')}-#{vb}"] = {
      '200' => {
        'description' => 'Generated',
        'schema' => {
            '$ref' => "#/definitions/#{response.class.to_s.split('::').last}"
        }
      },
      'default' =>{
         'description' => 'Default response'
        }
    }
    puts "-----------------------------------------------------------------------------------------------"
  else
    responses["#{path_array.join('/')}-#{vb}"] = {
      'default' =>{
         'description' => 'Default response'
        }
    }
  end

   unless request.nil? || request == 0
     allowed_keys = get_request_definition(request)

     allowed_keys.each do |key|
        parameters << {
          'name' => key.to_s.gsub(':',''),
          'required' => false,
          'in' => 'body',
          'type' => get_parameter_type(rails_route.defaults[:swagger][:model], key)
        }
     end
   end

    routes << {
      :controller => rails_route.defaults[:controller],
      :action => rails_route.defaults[:action],
      :verb => vb,
      :path => path_array.join('/'),
      :parameters => parameters
    }

  end

  routes.each do |route|
    pp route
  end

  #Start preparing swagger file
  definition ='---
  swagger: "2.0"
  info:
    description: CCv3
    version: "1.0.0"
    title: CCv3
  basePath: /v3
  schemes:
    - http
  paths: {}
  definitions: {}'

  swagger = YAML.load(definition)

  paths = swagger['paths']
  definitions = swagger['definitions']

  parameters=Hash.new
   routes.each do |route|
      route[:parameters].each do |parameter|
           next unless route[:path]
           parameters[route[:path]] = route[:parameters]
         end
  end

  routes.each do |route|
    paths[route[:path]] = [] if paths[route[:path]].nil?
    paths[route[:path]] << {
      route[:verb].downcase => {
         'summary' => 'test',
         'parameters' => route[:parameters],
         'responses' => responses["#{route[:path]}-#{route[:verb]}"]
      }
    }
  end

  response_presenters.each do | path, presenter|
    unless  definitions.has_key?(presenter.class.to_s.split('::').last)
      object_details = get_definitions(presenter.class.to_s.split('::').last,presenter.to_hash)
      definitions[presenter.class.to_s.split('::').last]=object_details
    end
  end

  File.open('swagger_api.yaml','w') {|file| file.write(swagger.to_yaml(:UseBlock => true))}

end
