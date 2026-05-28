class CreateSolidQueueWebAuditEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :solid_queue_web_audit_events do |t|
      t.string  :action,     null: false
      t.string  :actor
      t.string  :job_class
      t.string  :queue_name
      t.integer :item_count, null: false, default: 1
      t.datetime :created_at, null: false
    end

    add_index :solid_queue_web_audit_events, :created_at
    add_index :solid_queue_web_audit_events, :action
    add_index :solid_queue_web_audit_events, :actor
  end
end