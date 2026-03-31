ALTER TABLE workflow.workflow_tasks
    ADD COLUMN IF NOT EXISTS assigned_to_user_id uuid NULL REFERENCES identity.users (user_id);

CREATE INDEX IF NOT EXISTS ix_workflow_tasks_assigned_to_user
    ON workflow.workflow_tasks (tenant_id, assigned_to_user_id, status);

COMMENT ON COLUMN workflow.workflow_tasks.assigned_to_user_id IS 'Usuario asignado como responsable principal de la tarea.';
