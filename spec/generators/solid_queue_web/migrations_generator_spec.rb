require "rails_helper"
require "rails/generators"
require "rails/generators/testing/assertions"
require "rails/generators/testing/setup_and_teardown"
require "rails/generators/testing/behavior"
require "generators/solid_queue_web/install/migrations_generator"

RSpec.describe SolidQueueWeb::Install::MigrationsGenerator do
  include Rails::Generators::Testing::Behavior
  include Rails::Generators::Testing::Assertions
  include FileUtils

  tests SolidQueueWeb::Install::MigrationsGenerator
  destination File.expand_path("../../../tmp/generator_test", __dir__)

  before { prepare_destination }

  describe "#create_migration_file" do
    before { run_generator }

    it "creates the audit events migration file" do
      assert_migration "db/migrate/create_solid_queue_web_audit_events.rb"
    end

    it "defines the solid_queue_web_audit_events table in the migration" do
      assert_migration "db/migrate/create_solid_queue_web_audit_events.rb",
                       /create_table :solid_queue_web_audit_events/
    end
  end
end
