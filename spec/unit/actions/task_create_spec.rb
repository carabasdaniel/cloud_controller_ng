require 'spec_helper'
require 'actions/task_create'

module VCAP::CloudController
  RSpec.describe TaskCreate do
    subject(:task_create_action) { described_class.new(config, user_info) }
    let(:config) { { maximum_app_disk_in_mb: 4096 } }
    let(:user_info) { VCAP::CloudController::Audit::UserInfo.new(guid: user_guid, email: user_email) }
    let(:user_guid) { 'user-guid' }
    let(:user_email) { 'user-email' }

    describe '#create' do
      let(:app) { AppModel.make }
      let(:space) { app.space }
      let(:droplet) { DropletModel.make(app_guid: app.guid, state: DropletModel::STAGED_STATE) }
      let(:command) { 'bundle exec rake panda' }
      let(:name) { 'my_task_name' }
      let(:message) { TaskCreateMessage.new name: name, command: command, disk_in_mb: 2048, memory_in_mb: 1024 }
      let(:client) { instance_double(VCAP::CloudController::Diego::NsyncClient) }

      before do
        locator = CloudController::DependencyLocator.instance
        allow(locator).to receive(:nsync_client).and_return(client)
        allow(client).to receive(:desire_task).and_return(nil)

        app.droplet = droplet
        app.save
      end

      it 'creates and returns a task using the given app and its droplet' do
        task = task_create_action.create(app, message)

        expect(task.app).to eq(app)
        expect(task.droplet).to eq(droplet)
        expect(task.command).to eq(command)
        expect(task.name).to eq(name)
        expect(task.disk_in_mb).to eq(2048)
        expect(task.memory_in_mb).to eq(1024)
        expect(TaskModel.count).to eq(1)
      end

      it "sets the task state to 'PENDING'" do
        task = task_create_action.create(app, message)

        expect(task.state).to eq(TaskModel::PENDING_STATE)
      end

      it 'tells diego to make the task' do
        task = task_create_action.create(app, message)

        expect(client).to have_received(:desire_task).with(task)
      end

      it 'creates an app usage event for TASK_STARTED' do
        task = task_create_action.create(app, message)

        event = AppUsageEvent.last
        expect(event.state).to eq('TASK_STARTED')
        expect(event.task_guid).to eq(task.guid)
      end

      it 'creates a task create audit event' do
        task = task_create_action.create(app, message)

        event = Event.last
        expect(event.type).to eq('audit.app.task.create')
        expect(event.metadata['task_guid']).to eq(task.guid)
        expect(event.actee).to eq(app.guid)
      end

      describe 'sequence id' do
        it 'gives the task a sequence id' do
          task = task_create_action.create(app, message)

          expect(task.sequence_id).to eq(1)
        end

        it 'increments the sequence id for each task' do
          expect(task_create_action.create(app, message).sequence_id).to eq(1)
          app.reload
          expect(task_create_action.create(app, message).sequence_id).to eq(2)
          app.reload
          expect(task_create_action.create(app, message).sequence_id).to eq(3)
        end

        it 'does not re-use task ids from deleted tasks' do
          task_create_action.create(app, message)
          app.reload
          task_create_action.create(app, message)
          app.reload
          task = task_create_action.create(app, message)
          task.delete
          app.reload
          expect(task_create_action.create(app, message).sequence_id).to eq(4)
        end
      end

      describe 'default values' do
        let(:message) { TaskCreateMessage.new name: name, command: command }

        before { config[:default_app_memory] = 200 }

        it 'sets disk_in_mb to configured :default_app_disk_in_mb' do
          config[:default_app_disk_in_mb] = 200

          task = task_create_action.create(app, message)

          expect(task.disk_in_mb).to eq(200)
        end

        it 'sets memory_in_mb to configured :default_app_memory' do
          task = task_create_action.create(app, message)

          expect(task.memory_in_mb).to eq(200)
        end
      end

      context 'when the app does not have an assigned droplet' do
        let(:app_with_no_droplet) { AppModel.make }

        it 'raises a NoAssignedDroplet error' do
          expect {
            task_create_action.create(app_with_no_droplet, message)
          }.to raise_error(TaskCreate::NoAssignedDroplet, 'Task must have a droplet. Specify droplet or assign current droplet to app.')
        end
      end

      context 'when the name is not requested' do
        let(:message) { TaskCreateMessage.new command: command, memory_in_mb: 1024 }

        it 'uses a hex string as the name' do
          task = task_create_action.create(app, message)
          expect(task.name).to match /^[0-9a-f]{8}$/
        end
      end

      context 'when the task is invalid' do
        before do
          allow_any_instance_of(TaskModel).to receive(:save).and_raise(Sequel::ValidationFailed.new('booooooo'))
        end

        it 'raises an InvalidTask error' do
          expect {
            task_create_action.create(app, message)
          }.to raise_error(TaskCreate::InvalidTask, 'booooooo')
        end
      end

      context 'when a custom droplet is specified' do
        let(:custom_droplet) { DropletModel.make(app_guid: app.guid, state: DropletModel::STAGED_STATE) }

        it 'creates the task with the specified droplet' do
          task = task_create_action.create(app, message, droplet: custom_droplet)

          expect(task.droplet).to eq(custom_droplet)
        end
      end

      context 'when the requested disk in mb is higher than the configured maximum' do
        let(:config) { { maximum_app_disk_in_mb: 10 } }

        it 'raises an error' do
          expect {
            task_create_action.create(app, message)
          }.to raise_error(TaskCreate::MaximumDiskExceeded, /Cannot request disk_in_mb greater than 10/)
        end
      end
    end
  end
end
