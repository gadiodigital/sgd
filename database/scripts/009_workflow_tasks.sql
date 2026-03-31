CREATE SCHEMA IF NOT EXISTS workflow;

CREATE TABLE IF NOT EXISTS workflow.workflow_tasks (
    workflow_task_id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    document_id uuid NOT NULL REFERENCES documents.documents (document_id),
    title varchar(200) NOT NULL,
    notes text NULL,
    status varchar(32) NOT NULL CHECK (status IN ('OPEN', 'COMPLETED')),
    created_by_user_id uuid NULL REFERENCES identity.users (user_id),
    created_at_utc timestamptz NOT NULL,
    due_at_utc timestamptz NULL,
    completed_by_user_id uuid NULL REFERENCES identity.users (user_id),
    completed_at_utc timestamptz NULL,
    CONSTRAINT workflow_tasks_completion_check CHECK (
        (status = 'OPEN' AND completed_at_utc IS NULL)
        OR (status = 'COMPLETED' AND completed_at_utc IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS ix_workflow_tasks_tenant_status_due
    ON workflow.workflow_tasks (tenant_id, status, due_at_utc);

CREATE INDEX IF NOT EXISTS ix_workflow_tasks_document
    ON workflow.workflow_tasks (document_id);

COMMENT ON TABLE workflow.workflow_tasks IS 'Tareas simples de workflow ligadas a documentos.';
COMMENT ON COLUMN workflow.workflow_tasks.tenant_id IS 'Tenant dueño de la tarea.';
COMMENT ON COLUMN workflow.workflow_tasks.document_id IS 'Documento asociado a la tarea.';
COMMENT ON COLUMN workflow.workflow_tasks.status IS 'Estado OPEN/COMPLETED.';
