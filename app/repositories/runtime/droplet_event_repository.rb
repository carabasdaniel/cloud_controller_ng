module VCAP::CloudController
  module Repositories
    module Runtime
      class DropletEventRepository
        def self.record_dropet_create_by_staging(droplet, actor, actor_name, request_attrs, v3_app_name, space_guid, org_guid)
          Loggregator.emit(droplet.app_guid, "Creating droplet for app with guid #{droplet.app_guid}")

          metadata = {
            droplet_guid: droplet.guid,
            request: request_attrs
          }

          Event.create(
            type: 'audit.app.droplet.create',
            actor: actor.guid,
            actor_type: 'user',
            actor_name: actor_name,
            actee: droplet.app_guid,
            actee_type: 'v3-app',
            actee_name: v3_app_name,
            timestamp: Sequel::CURRENT_TIMESTAMP,
            metadata: metadata,
            space_guid: space_guid,
            organization_guid: org_guid
          )
        end

        def self.record_dropet_delete(droplet, actor_guid, actor_name, v3_app_name, space_guid, org_guid)
          Loggregator.emit(droplet.app_guid, "Deleting droplet for app with guid #{droplet.app_guid}")

          metadata = { droplet_guid: droplet.guid }

          Event.create(
            type: 'audit.app.droplet.delete',
            actor: actor_guid,
            actor_type: 'user',
            actor_name: actor_name,
            actee: droplet.app_guid,
            actee_type: 'v3-app',
            actee_name: v3_app_name,
            timestamp: Sequel::CURRENT_TIMESTAMP,
            metadata: metadata,
            space_guid: space_guid,
            organization_guid: org_guid
          )
        end

        def self.record_dropet_download(droplet, actor, actor_name, v3_app_name, space_guid, org_guid)
          Loggregator.emit(droplet.app_guid, "Downloading droplet for app with guid #{droplet.app_guid}")

          metadata = { droplet_guid: droplet.guid }

          Event.create(
            type: 'audit.app.droplet.download',
            actor: actor.guid,
            actor_type: 'user',
            actor_name: actor_name,
            actee: droplet.app_guid,
            actee_type: 'v3-app',
            actee_name: v3_app_name,
            timestamp: Sequel::CURRENT_TIMESTAMP,
            metadata: metadata,
            space_guid: space_guid,
            organization_guid: org_guid
          )
        end
      end
    end
  end
end
