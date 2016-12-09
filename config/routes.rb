Rails.application.routes.draw do
  # apps
  get '/apps', {
     to: 'apps_v3#index',
     swagger: {
       response: 'PaginatedListPresenter',
       model: 'AppModel',
       request: 'AppsListMessage'
     }
  }

  post '/apps', {
     to: 'apps_v3#create',
     swagger: {
       request: 'AppCreateMessage',
       model: 'AppModel',
       response: 'AppPresenter'
     }
   }

  get '/apps/:guid', {
     to: 'apps_v3#show',
     swagger: {
       model: 'AppModel',
       response: 'AppPresenter'
     }
  }

  put '/apps/:guid', {
     to: 'apps_v3#update',
     swagger:{
       request: 'AppUpdateMessage',
       model: 'AppModel',
       response: 'AppPresenter'
     }
   }

  patch '/apps/:guid', {
     to: 'apps_v3#update',
     swagger:{
       request: 'AppUpdateMessage',
       model: 'AppModel',
       response: 'AppPresenter'
     }
  }

  delete '/apps/:guid', {
     to: 'apps_v3#destroy',
     swagger:{
     }
  }

  put '/apps/:guid/start', {
     to: 'apps_v3#start',
     swagger: {
       model: 'AppModel',
       response: 'AppPresenter'
     }
  }

  put '/apps/:guid/stop', {
    to: 'apps_v3#stop',
    swagger: {
      model: 'AppModel',
      response: 'AppPresenter'
    }
  }

  get '/apps/:guid/env', {
     to: 'apps_v3#show_environment',
     swagger:{
       model: 'AppModel',
       response: 'AppEnvPresenter'
     }
  }

  put '/apps/:guid/droplets/current', {
    to: 'apps_v3#assign_current_droplet',
    swagger:{
      request: 'DropletCreateMessage',
      model: 'DropletModel',
      response: 'DropletPresenter'
    }
  }

  get '/apps/:guid/droplets/current', {
     to: 'apps_v3#current_droplet',
     swagger:{
       model: 'DropletModel',
       response: 'DropletPresenter'
     }
   }

  # processes
  get '/processes', {
     to: 'processes#index',
     swagger:{
       request: 'ProcessesListMessage',
       model: 'ProcessModel',
       response: 'PaginatedListPresenter'
     }
  }

  get '/processes/:process_guid', {
    to: 'processes#show',
    swagger:{
       model: 'ProcessModel',
       response: 'ProcessPresenter'
    }
  }

  patch '/processes/:process_guid', {
     to: 'processes#update',
     swagger:{
       request: 'ProcessUpdateMessage',
       model: 'ProcessModel',
       response: 'ProcessPresenter'
     }
  }

  delete '/processes/:process_guid/instances/:index',{
    to: 'processes#terminate',
    swagger:{
    }
  }

  put '/processes/:process_guid/scale', {
     to: 'processes#scale',
     swagger:{
       request: 'ProcessScaleMessage',
       model: 'ProcessModel',
       response: 'ProcessPresenter'
     }
  }

  get '/processes/:process_guid/stats', {
     to: 'processes#stats',
     swagger:{
       model: 'ProcessModel',
       response: 'ProcessStatsPresenter'
     }
  }

  get '/apps/:app_guid/processes',{
     to: 'processes#index',
     swagger:{
     }
  }
  get '/apps/:app_guid/processes/:type', {
     to: 'processes#show',
     swagger:{
       model: 'ProcessModel',
       response: 'ProcessStatsPresenter'
     }
  }
  put '/apps/:app_guid/processes/:type/scale', {
     to: 'processes#scale',
     swagger:{
       request: 'ProcessScaleMessage',
       model: 'ProcessModel',
       response: 'ProcessPresenter'
     }
  }
  delete '/apps/:app_guid/processes/:type/instances/:index', {
    to: 'processes#terminate',
    swagger:{
    }
  }

  get '/apps/:app_guid/processes/:type/stats', {
     to: 'processes#stats',
     swagger:{
         model: 'ProcessModel',
         response: 'ProcessStatsPresenter'
     }
  }

  # packages
  get '/packages',{
     to: 'packages#index',
     swagger:{
       request: 'PackagesListMessage',
       model: 'PackageModel',
       response: 'PaginatedListPresenter'
     }
  }

  get '/packages/:guid', {
     to: 'packages#show',
     swagger:{
        model: 'PackageModel',
        response: 'PackagePresenter'
     }
  }

  post '/packages/:guid/upload',{
     to: 'packages#upload',
     swagger:{
        request: 'PackageUploadMessage',
        model: 'PackageModel',
        response: 'PackagePresenter'
     }
  }

  get '/packages/:guid/download', {
     to: 'packages#download',
     swagger:{
        model: 'PackageModel',
        response: 'PackagePresenter'
     }
  }

  delete '/packages/:guid', {
     to: 'packages#destroy',
     swagger:{
     }
  }

  get '/apps/:app_guid/packages',{
     to: 'packages#index',
     swagger:{
     }
  }

  post '/apps/:app_guid/packages', {
     to: 'packages#create',
     swagger:{
       request: 'PackageCreateMessage',
       model: 'PackageModel',
       response: 'PackagePresenter'
     }
  }

  # droplets
  post '/packages/:package_guid/droplets', {
     to: 'droplets#create',
     swagger:{
       request: 'DropletCreateMessage',
       model: 'DropletModel',
       response: 'DropletPresenter'
     }
  }

  post '/droplets/:guid/copy',{
     to: 'droplets#copy',
     swagger:{
       request: 'DropletCopyMessage',
       model: 'DropletModel',
       response: 'DropletPresenter'
     }
  }

  get '/droplets', {
     to: 'droplets#index',
     swagger:{
       request: 'DropletsListMessage',
       model: 'DropletModel',
       response: 'PaginatedListPresenter'
     }
  }

  get '/droplets/:guid', {
     to: 'droplets#show',
     swagger:{
       model: 'DropletModel',
       response: 'DropletPresenter'
     }
  }

  delete '/droplets/:guid', {
    to: 'droplets#destroy',
    swagger:{
    }
  }

  get '/apps/:app_guid/droplets', {
    to: 'droplets#index',
    swagger:{
      request: 'DropletsListMessage'
    }
  }

  get '/packages/:package_guid/droplets',{
     to: 'droplets#index',
     swagger:{
       request: 'DropletsListMessage'
     }
   }

  # route_mappings
  post '/route_mappings', {
    to: 'route_mappings#create',
    swagger:{
      request: 'RouteMappingsCreateMessage',
      model: 'RouteMappingModel',
      response: 'RouteMappingPresenter'
    }
  }

  get '/route_mappings', {
     to: 'route_mappings#index',
     swagger:{
       request: 'RouteMappingsListMessage',
       model: 'RouteMappingModel',
       response: 'PaginatedListPresenter'
     }
  }

  get '/route_mappings/:route_mapping_guid',{
     to: 'route_mappings#show',
     swagger:{
       model: 'RouteMappingModel',
       response: 'RouteMappingPresenter'
     }
  }

  delete '/route_mappings/:route_mapping_guid',{
     to: 'route_mappings#destroy',
     swagger:{
     }
  }

  get '/apps/:app_guid/route_mappings', {
     to: 'route_mappings#index',
     swagger:{
     }
  }

  # tasks
  get '/tasks', {
    to: 'tasks#index',
    swagger: {
      response: 'PaginatedListPresenter',
      model: 'TaskModel',
      request: 'TasksListMessage'
    }
  }
  get '/tasks/:task_guid', {
    to: 'tasks#show',
    swagger: {
      response: 'TaskPresenter',
      model: 'TaskModel'
    }
  }

  put '/tasks/:task_guid/cancel', to: 'tasks#cancel'

  post '/apps/:app_guid/tasks', {
    to: 'tasks#create',
    swagger: {
      request: 'TaskCreateMessage',
      response: 'TaskPresenter',
      model: 'TaskModel',
    }
  }

  get '/apps/:app_guid/tasks', {
     to: 'tasks#index',
     swagger:{
       request: 'TasksListMessage'
     }
  }

  # service_bindings
  post '/service_bindings', {
     to: 'service_bindings#create',
     swagger:{
       request: 'ServiceBindingCreateMessage',
       model: 'ServiceBindingModel',
       response: 'ServiceBindingModelPresenter'
     }
  }

  get '/service_bindings/:guid', {
    to: 'service_bindings#show',
    swagger:{
      model: 'ServiceBindingModel',
      response: 'ServiceBindingModelPresenter'
    }
  }
  get '/service_bindings', {
    to: 'service_bindings#index',
    swagger:{
      request: 'ServiceBindingsListMessage'
    }
  }
  delete '/service_bindings/:guid', {
     to: 'service_bindings#destroy',
     swagger:{
     }
  }

  # errors
  match '404', to: 'errors#not_found', via: :all
  match '500', to: 'errors#internal_error', via: :all
  match '400', to: 'errors#bad_request', via: :all
end
