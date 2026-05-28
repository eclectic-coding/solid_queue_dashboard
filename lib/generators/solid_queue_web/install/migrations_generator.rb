require "rails/generators"
require "rails/generators/active_record"

module SolidQueueWeb
  module Install
    class MigrationsGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)
      desc "Copy SolidQueueWeb migrations to your application."

      def self.next_migration_number(path)
        ActiveRecord::Generators::Base.next_migration_number(path)
      end

      def create_migration_file
        migration_template(
          "create_solid_queue_web_audit_events.rb.tt",
          "db/migrate/create_solid_queue_web_audit_events.rb"
        )
      end
    end
  end
end
