/**
 * SGD - Sistema de Gestión Documental
 * Main Application JavaScript
 */

// Application State
const AppState = {
    currentPage: 'dashboard',
    sidebarCollapsed: false,
    adminActiveTab: 'users',
    uploadSource: 'file',
    user: {
        name: 'María García',
        email: 'mgarcia@empresa.com.ar',
        role: 'Administrador',
        initials: 'MG'
    }
};

// Mock Data
const MockData = {
    documents: [
        { id: 1, title: 'Contrato de Servicios - Cliente ABC', type: 'pdf', status: 'active', classification: 'Confidencial', date: '2026-01-20', author: 'Juan Pérez', version: '2.1.0', description: 'Contrato marco de prestación de servicios de consultoría IT con el cliente ABC S.A. Incluye cláusulas de confidencialidad y SLA.', tags: 'contrato, servicios, legal', expedienteId: 1, customValues: { 'Partes': 'Empresa S.A. / ABC S.A.', 'Monto': '$ 1.500.000', 'Vigencia': '12 meses' } },
        { id: 2, title: 'Balance Fiscal Q4 2025', type: 'xls', status: 'pending', classification: 'Interno', date: '2026-01-19', author: 'Ana Rodríguez', version: '1.0.0', description: 'Balance de cierre del cuarto trimestre del ejercicio fiscal 2025.', tags: 'finanzas, contabilidad, balance', expedienteId: 3, customValues: { 'Período': 'Q4 2025', 'Responsable': 'Gerencia Financiera' } },
        { id: 3, title: 'Escritura Propiedad Lote 45', type: 'pdf', status: 'signed', classification: 'Confidencial', date: '2026-01-18', author: 'Carlos López', version: '1.2.0', description: 'Escritura traslativa de dominio del inmueble sito en Parque Industrial.', tags: 'legales, inmuebles, escritura', expedienteId: 1 },
        { id: 4, title: 'Manual de Procedimientos ISO', type: 'doc', status: 'active', classification: 'Público', date: '2026-01-17', author: 'María García', version: '3.0.0', description: 'Procedimientos operativos estándar actualizados según norma ISO 9001:2015.', tags: 'calidad, iso, procedimientos' },
        { id: 5, title: 'Informe Auditoría Interna', type: 'pdf', status: 'archived', classification: 'Estrictamente Confidencial', date: '2026-01-15', author: 'Roberto Sánchez', version: '1.0.0', description: 'Informe preliminar de hallazgos de auditoría interna de procesos.', tags: 'auditoria, control interno', expedienteId: 3 },
        { id: 6, title: 'Factura Proveedor #12345', type: 'pdf', status: 'active', classification: 'Interno', date: '2026-01-14', author: 'Laura Martínez', version: '1.0.0', description: 'Factura por compra de insumos de oficina.', tags: 'compras, facturas', customValues: { 'Proveedor': 'Officenet', 'Importe': '$ 45.000' } },
        { id: 7, title: 'Planos Oficina Central', type: 'img', status: 'active', classification: 'Interno', date: '2026-01-12', author: 'Diego Fernández', version: '1.1.0' },
        { id: 8, title: 'Acta Reunión Directorio', type: 'doc', status: 'pending', classification: 'Confidencial', date: '2026-01-10', author: 'María García', version: '1.0.0' }
    ],
    expedientes: [
        { id: 1, number: 'EXP-2026-0001', title: 'Caso ABC vs DEF', status: 'active', documents: 15, responsible: 'Juan Pérez', openDate: '2026-01-05', seriesId: 10, priority: 'Alta' },
        { id: 2, number: 'EXP-2026-0002', title: 'Licitación Municipal #567', status: 'active', documents: 23, responsible: 'Ana Rodríguez', openDate: '2026-01-08', seriesId: 1, priority: 'Normal' },
        { id: 3, number: 'EXP-2025-0089', title: 'Auditoría Fiscal 2025', status: 'closed', documents: 45, responsible: 'Carlos López', openDate: '2025-03-15', seriesId: 7, priority: 'Normal' },
        { id: 4, number: 'EXP-2026-0003', title: 'Sucesión García', status: 'pending', documents: 8, responsible: 'María García', openDate: '2026-01-12', seriesId: 10, priority: 'Urgente' },
        { id: 5, number: 'EXP-2025-0102', title: 'Contrato Framework 2026', status: 'active', documents: 12, responsible: 'Roberto Sánchez', openDate: '2025-11-20', seriesId: 9, priority: 'Normal' }
    ],
    workflows: [
        { id: 1, title: 'Aprobación Contrato Cliente XYZ', type: 'approval', status: 'pending', requester: 'Juan Pérez', date: '2026-01-21', priority: 'high' },
        { id: 2, title: 'Firma Digital Balance Q4', type: 'signature', status: 'pending', requester: 'Ana Rodríguez', date: '2026-01-20', priority: 'medium' },
        { id: 3, title: 'Revisión Manual de Calidad', type: 'review', status: 'approved', requester: 'Carlos López', date: '2026-01-19', priority: 'low' },
        { id: 4, title: 'Validación Escritura #456', type: 'validation', status: 'pending', requester: 'María García', date: '2026-01-18', priority: 'high' }
    ],
    auditLogs: [
        { id: 1, timestamp: '2026-01-21 10:45:23', user: 'María García', action: 'Visualización', resource: 'Contrato Cliente ABC', result: 'success', ip: '192.168.1.105' },
        { id: 2, timestamp: '2026-01-21 10:32:15', user: 'Juan Pérez', action: 'Descarga', resource: 'Balance Q4 2025', result: 'success', ip: '192.168.1.42' },
        { id: 3, timestamp: '2026-01-21 10:15:08', user: 'Ana Rodríguez', action: 'Firma Digital', resource: 'Escritura Lote 45', result: 'success', ip: '192.168.1.78' },
        { id: 4, timestamp: '2026-01-21 09:58:42', user: 'Carlos López', action: 'Modificación', resource: 'Manual ISO', result: 'success', ip: '192.168.1.33' },
        { id: 5, timestamp: '2026-01-21 09:45:11', user: 'Usuario Desconocido', action: 'Intento de Acceso', resource: 'Informe Auditoría', result: 'error', ip: '201.45.67.89' },
        { id: 6, timestamp: '2026-01-21 09:30:55', user: 'María García', action: 'Creación', resource: 'Expediente EXP-2026-0003', result: 'success', ip: '192.168.1.105' },
        { id: 7, timestamp: '2026-01-21 09:15:22', user: 'Roberto Sánchez', action: 'Aprobación', resource: 'Workflow #1023', result: 'success', ip: '192.168.1.91' },
        { id: 8, timestamp: '2026-01-21 08:55:33', user: 'Laura Martínez', action: 'Carga', resource: 'Factura #12345', result: 'success', ip: '192.168.1.55' }
    ],
    users: [
        { id: 1, name: 'María García', email: 'mgarcia@empresa.com.ar', role: 'Administrador', status: 'active', initials: 'MG' },
        { id: 2, name: 'Juan Pérez', email: 'jperez@empresa.com.ar', role: 'Gestor Documental', status: 'active', initials: 'JP' },
        { id: 3, name: 'Ana Rodríguez', email: 'arodriguez@empresa.com.ar', role: 'Usuario', status: 'active', initials: 'AR' },
        { id: 4, name: 'Carlos López', email: 'clopez@empresa.com.ar', role: 'Auditor', status: 'active', initials: 'CL' },
        { id: 5, name: 'Roberto Sánchez', email: 'rsanchez@empresa.com.ar', role: 'Gestor Documental', status: 'inactive', initials: 'RS' }
    ],
    documentTypes: [
        {
            id: 1,
            name: 'Contrato',
            code: 'CTR',
            description: 'Contratos comerciales, laborales y de servicios',
            retentionYears: 10,
            fields: [
                { name: 'partes', label: 'Partes del Contrato', type: 'text', required: true },
                { name: 'monto', label: 'Monto ($)', type: 'number', required: false },
                { name: 'fecha_vencimiento', label: 'Fecha de Vencimiento', type: 'date', required: true },
                { name: 'tipo_contrato', label: 'Tipo de Contrato', type: 'select', required: true, options: ['Comercial', 'Laboral', 'Servicios', 'Locación', 'Otro'] }
            ]
        },
        {
            id: 2,
            name: 'Factura',
            code: 'FAC',
            description: 'Facturas de compra y venta',
            retentionYears: 10,
            fields: [
                { name: 'proveedor_cliente', label: 'Proveedor/Cliente', type: 'text', required: true },
                { name: 'numero_factura', label: 'Número de Factura', type: 'text', required: true },
                { name: 'cuit', label: 'CUIT', type: 'text', required: true },
                { name: 'monto_total', label: 'Monto Total ($)', type: 'number', required: true },
                { name: 'fecha_vencimiento', label: 'Fecha de Vencimiento', type: 'date', required: false },
                { name: 'tipo_factura', label: 'Tipo', type: 'select', required: true, options: ['A', 'B', 'C', 'E', 'Nota de Crédito', 'Nota de Débito'] }
            ]
        },
        {
            id: 3,
            name: 'Escritura',
            code: 'ESC',
            description: 'Escrituras notariales y públicas',
            retentionYears: 0,
            fields: [
                { name: 'escribano', label: 'Escribano', type: 'text', required: true },
                { name: 'numero_escritura', label: 'Número de Escritura', type: 'text', required: true },
                { name: 'registro', label: 'Registro Notarial', type: 'text', required: true },
                { name: 'objeto', label: 'Objeto', type: 'textarea', required: true }
            ]
        },
        {
            id: 4,
            name: 'Informe',
            code: 'INF',
            description: 'Informes técnicos, financieros y de gestión',
            retentionYears: 5,
            fields: [
                { name: 'area_responsable', label: 'Área Responsable', type: 'text', required: true },
                { name: 'periodo', label: 'Período Cubierto', type: 'text', required: false },
                { name: 'destinatario', label: 'Destinatario', type: 'text', required: false }
            ]
        },
        {
            id: 5,
            name: 'Acta',
            code: 'ACT',
            description: 'Actas de reunión, asamblea y directorio',
            retentionYears: 0,
            fields: [
                { name: 'tipo_reunion', label: 'Tipo de Reunión', type: 'select', required: true, options: ['Directorio', 'Asamblea Ordinaria', 'Asamblea Extraordinaria', 'Comité', 'Equipo'] },
                { name: 'numero_acta', label: 'Número de Acta', type: 'text', required: true },
                { name: 'participantes', label: 'Participantes', type: 'textarea', required: true }
            ]
        },
        {
            id: 6,
            name: 'Correspondencia',
            code: 'COR',
            description: 'Cartas, notas y comunicaciones oficiales',
            retentionYears: 3,
            fields: [
                { name: 'remitente', label: 'Remitente', type: 'text', required: true },
                { name: 'destinatario', label: 'Destinatario', type: 'text', required: true },
                { name: 'asunto', label: 'Asunto', type: 'text', required: true },
                { name: 'tipo_correspondencia', label: 'Tipo', type: 'select', required: true, options: ['Entrante', 'Saliente', 'Interna'] }
            ]
        },
        {
            id: 7,
            name: 'Manual/Procedimiento',
            code: 'MAN',
            description: 'Manuales, procedimientos y políticas internas',
            retentionYears: 0,
            fields: [
                { name: 'version', label: 'Versión', type: 'text', required: true },
                { name: 'area_responsable', label: 'Área Responsable', type: 'text', required: true },
                { name: 'fecha_vigencia', label: 'Fecha de Vigencia', type: 'date', required: true },
                { name: 'aprobado_por', label: 'Aprobado Por', type: 'text', required: true }
            ]
        },
        {
            id: 8,
            name: 'Otro',
            code: 'OTR',
            description: 'Otros documentos no clasificados',
            retentionYears: 5,
            fields: []
        }
    ],
    documentSeries: [
        { id: 1, code: 'ADM', name: 'Administración', description: 'Documentos administrativos generales', parentId: null, retentionYears: 5 },
        { id: 2, code: 'ADM-ORG', name: 'Organización Interna', description: 'Organigramas, políticas y procedimientos', parentId: 1, retentionYears: 0 },
        { id: 3, code: 'ADM-COR', name: 'Correspondencia General', description: 'Comunicaciones internas y externas', parentId: 1, retentionYears: 3 },
        { id: 4, code: 'CON', name: 'Contabilidad', description: 'Documentos contables y financieros', parentId: null, retentionYears: 10 },
        { id: 5, code: 'CON-FAC', name: 'Facturación', description: 'Facturas emitidas y recibidas', parentId: 4, retentionYears: 10 },
        { id: 6, code: 'CON-BAL', name: 'Balances', description: 'Estados contables y balances', parentId: 4, retentionYears: 10 },
        { id: 7, code: 'CON-IMP', name: 'Impuestos', description: 'Declaraciones juradas y pagos impositivos', parentId: 4, retentionYears: 10 },
        { id: 8, code: 'LEG', name: 'Legal', description: 'Documentos legales y jurídicos', parentId: null, retentionYears: 0 },
        { id: 9, code: 'LEG-CTR', name: 'Contratos', description: 'Contratos y convenios', parentId: 8, retentionYears: 10 },
        { id: 10, code: 'LEG-LIT', name: 'Litigios', description: 'Expedientes judiciales', parentId: 8, retentionYears: 0 },
        { id: 11, code: 'RRHH', name: 'Recursos Humanos', description: 'Gestión del personal', parentId: null, retentionYears: 50 },
        { id: 12, code: 'RRHH-LEG', name: 'Legajos', description: 'Legajos de empleados', parentId: 11, retentionYears: 50 },
        { id: 13, code: 'RRHH-LIQ', name: 'Liquidaciones', description: 'Recibos de sueldo y liquidaciones', parentId: 11, retentionYears: 10 },
        { id: 14, code: 'COM', name: 'Comercial', description: 'Documentos comerciales y de clientes', parentId: null, retentionYears: 5 }
    ],
    retentionPolicies: [
        {
            id: 1,
            name: 'Fiscal Obligatorio',
            description: 'Documentos con obligación fiscal (AFIP)',
            years: 10,
            action: 'archive',
            seriesIds: [4, 5, 6, 7],
            workflow: [
                { order: 1, name: 'Generación/Recepción', role: 'Usuario', action: 'create', sla: '24 hs' },
                { order: 2, name: 'Validación Fiscal', role: 'Contador', action: 'approve', sla: '48 hs' },
                { order: 3, name: 'Presentación AFIP', role: 'Sistema', action: 'system', sla: 'Inmediato' },
                { order: 4, name: 'Archivo Fiscal', role: 'Sistema', action: 'archive', sla: '10 años' },
                { order: 5, name: 'Depuración Segura', role: 'Administrador', action: 'delete', sla: 'N/A' }
            ]
        },
        {
            id: 2,
            name: 'Laboral Obligatorio',
            description: 'Documentos laborales según LCT',
            years: 50,
            action: 'archive',
            seriesIds: [11, 12, 13],
            workflow: [
                { order: 1, name: 'Alta Empleado/Documento', role: 'RRHH', action: 'create', sla: '48 hs' },
                { order: 2, name: 'Firma Empleado', role: 'Usuario', action: 'sign', sla: '5 días' },
                { order: 3, name: 'Digitalización Legajo', role: 'RRHH', action: 'archive', sla: 'Permanente' },
                { order: 4, name: 'Custodia Largo Plazo', role: 'Sistema', action: 'archive', sla: '50 años' }
            ]
        },
        {
            id: 3,
            name: 'Contratos Activos',
            description: 'Contratos hasta 10 años post vencimiento',
            years: 10,
            action: 'review',
            seriesIds: [9],
            workflow: [
                { order: 1, name: 'Borrador', role: 'Legal', action: 'draft', sla: '5 días' },
                { order: 2, name: 'Revisión Contraparte', role: 'Externo', action: 'review', sla: '10 días' },
                { order: 3, name: 'Firma Digital', role: 'Apoderado', action: 'sign', sla: '48 hs' },
                { order: 4, name: 'Gestión Activa', role: 'Comercial', action: 'monitor', sla: 'Vigencia' },
                { order: 5, name: 'Cierre y Archivo', role: 'Legal', action: 'archive', sla: '10 años' }
            ]
        },
        {
            id: 4,
            name: 'Correspondencia',
            description: 'Correspondencia general',
            years: 3,
            action: 'delete',
            seriesIds: [3],
            workflow: [
                { order: 1, name: 'Recepción', role: 'Mesa de Entradas', action: 'scan', sla: '4 hs' },
                { order: 2, name: 'Distribución', role: 'Sistema', action: 'distribute', sla: 'Inmediato' },
                { order: 3, name: 'Archivo Temporal', role: 'Sistema', action: 'archive', sla: '3 años' },
                { order: 4, name: 'Eliminación Automática', role: 'Sistema', action: 'delete', sla: 'N/A' }
            ]
        },
        {
            id: 5,
            name: 'Conservación Permanente',
            description: 'Documentos de valor histórico',
            years: 0,
            action: 'permanent',
            seriesIds: [2, 8, 10],
            workflow: [
                { order: 1, name: 'Catalogación', role: 'Archivista', action: 'classify', sla: 'N/A' },
                { order: 2, name: 'Preservación Digital', role: 'Sistema', action: 'archive', sla: 'Permanente' },
                { order: 3, name: 'Acceso Público/Privado', role: 'Usuarios', action: 'read', sla: 'N/A' }
            ]
        },
        {
            id: 6,
            name: 'Documentos Generales',
            description: 'Sin requisito legal específico',
            years: 5,
            action: 'delete',
            seriesIds: [1, 14],
            workflow: [
                { order: 1, name: 'Creación', role: 'Usuario', action: 'create', sla: 'N/A' },
                { order: 2, name: 'Colaboración', role: 'Equipo', action: 'edit', sla: 'Activo' },
                { order: 3, name: 'Archivo Inactivo', role: 'Sistema', action: 'archive', sla: '5 años' },
                { order: 4, name: 'Revisión Disposición', role: 'Gestor Documental', action: 'review', sla: '30 días' }
            ]
        }
    ],
    roles: [
        {
            id: 1,
            name: 'Administrador',
            description: 'Acceso completo al sistema',
            permissions: { create: true, read: true, edit: true, delete: true, download: true, print: true, sign: true, approve: true, manage_permissions: true, configure: true }
        },
        {
            id: 2,
            name: 'Gestor Documental',
            description: 'Gestión de documentos y expedientes',
            permissions: { create: true, read: true, edit: true, delete: false, download: true, print: true, sign: true, approve: false, manage_permissions: false, configure: false }
        },
        {
            id: 3,
            name: 'Usuario',
            description: 'Usuario estándar con acceso limitado',
            permissions: { create: true, read: true, edit: false, delete: false, download: true, print: true, sign: false, approve: false, manage_permissions: false, configure: false }
        },
        {
            id: 4,
            name: 'Auditor',
            description: 'Acceso de solo lectura para auditoría',
            permissions: { create: false, read: true, edit: false, delete: false, download: true, print: true, sign: false, approve: false, manage_permissions: false, configure: false }
        },
        {
            id: 5,
            name: 'Invitado',
            description: 'Acceso temporal limitado',
            permissions: { create: false, read: true, edit: false, delete: false, download: false, print: false, sign: false, approve: false, manage_permissions: false, configure: false }
        }
    ],
    stats: {
        totalDocuments: 15847,
        pendingApprovals: 23,
        expiringRetention: 12,
        storageUsed: 78
    }
};

// Page Renderers
const PageRenderers = {
    dashboard: function () {
        return `
            <div class="page-header">
                <h1 class="page-title">Dashboard</h1>
                <p class="page-subtitle">Resumen de actividad del sistema</p>
            </div>
            
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon primary">
                        <span class="material-icons">description</span>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${MockData.stats.totalDocuments.toLocaleString()}</div>
                        <div class="stat-label">Documentos Totales</div>
                        <div class="stat-trend positive">
                            <span class="material-icons" style="font-size:16px">trending_up</span>
                            +245 este mes
                        </div>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon tertiary">
                        <span class="material-icons">pending_actions</span>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${MockData.stats.pendingApprovals}</div>
                        <div class="stat-label">Aprobaciones Pendientes</div>
                        <div class="stat-trend negative">
                            <span class="material-icons" style="font-size:16px">priority_high</span>
                            5 urgentes
                        </div>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon error">
                        <span class="material-icons">schedule</span>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${MockData.stats.expiringRetention}</div>
                        <div class="stat-label">Retención por Vencer</div>
                        <div class="stat-trend negative">
                            <span class="material-icons" style="font-size:16px">warning</span>
                            Próximos 30 días
                        </div>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon secondary">
                        <span class="material-icons">cloud_done</span>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${MockData.stats.storageUsed}%</div>
                        <div class="stat-label">Almacenamiento Usado</div>
                        <div class="stat-trend positive">
                            <span class="material-icons" style="font-size:16px">check_circle</span>
                            2.2 TB disponibles
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="dashboard-grid">
                <div class="card">
                    <div class="card-header">
                        <span class="card-title">Actividad Reciente</span>
                        <button class="btn btn-text">Ver todo</button>
                    </div>
                    <div class="card-content">
                        <div class="activity-chart">
                            <div class="chart-bar" style="height:60%"></div>
                            <div class="chart-bar" style="height:80%"></div>
                            <div class="chart-bar" style="height:45%"></div>
                            <div class="chart-bar" style="height:70%"></div>
                            <div class="chart-bar" style="height:90%"></div>
                            <div class="chart-bar" style="height:65%"></div>
                            <div class="chart-bar" style="height:75%"></div>
                            <div class="chart-bar" style="height:55%"></div>
                            <div class="chart-bar" style="height:85%"></div>
                            <div class="chart-bar" style="height:50%"></div>
                            <div class="chart-bar" style="height:95%"></div>
                            <div class="chart-bar" style="height:70%"></div>
                        </div>
                        <div class="recent-documents mt-24">
                            ${MockData.documents.slice(0, 5).map(doc => `
                                <div class="list-item" onclick="App.viewDocument(${doc.id})">
                                    <div class="document-icon ${doc.type}">
                                        <span class="material-icons">${getDocumentIcon(doc.type)}</span>
                                    </div>
                                    <div class="list-item-content">
                                        <div class="list-item-title">${doc.title}</div>
                                        <div class="list-item-subtitle">${doc.author} • ${formatDate(doc.date)}</div>
                                    </div>
                                    <span class="chip ${getStatusClass(doc.status)}">${getStatusLabel(doc.status)}</span>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                </div>
                
                <div>
                    <div class="card mb-24">
                        <div class="card-header">
                            <span class="card-title">Alertas</span>
                        </div>
                        <div class="card-content">
                            <div class="alerts-list">
                                <div class="alert-item">
                                    <span class="material-icons">schedule</span>
                                    <div class="alert-content">
                                        <div class="alert-title">12 documentos próximos a vencer</div>
                                        <div class="alert-subtitle">Revisar políticas de retención</div>
                                    </div>
                                </div>
                                <div class="alert-item error">
                                    <span class="material-icons">gpp_bad</span>
                                    <div class="alert-content">
                                        <div class="alert-title">Intento de acceso no autorizado</div>
                                        <div class="alert-subtitle">Hace 2 horas - IP: 201.45.67.89</div>
                                    </div>
                                </div>
                                <div class="alert-item">
                                    <span class="material-icons">update</span>
                                    <div class="alert-content">
                                        <div class="alert-title">Backup completado</div>
                                        <div class="alert-subtitle">Último backup: hoy 03:00 AM</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="card">
                        <div class="card-header">
                            <span class="card-title">Tareas Pendientes</span>
                        </div>
                        <div class="card-content">
                            ${MockData.workflows.filter(w => w.status === 'pending').slice(0, 3).map(w => `
                                <div class="list-item" onclick="App.navigate('workflows')">
                                    <div class="workflow-status pending">
                                        <span class="material-icons">${getWorkflowIcon(w.type)}</span>
                                    </div>
                                    <div class="list-item-content">
                                        <div class="list-item-title">${w.title}</div>
                                        <div class="list-item-subtitle">${w.requester} • ${formatDate(w.date)}</div>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                </div>
            </div>
        `;
    },

    documents: function () {
        return `
            <div class="page-header">
                <h1 class="page-title">Gestión Documental</h1>
                <p class="page-subtitle">Administra todos los documentos del sistema</p>
            </div>
            
            <div class="documents-toolbar">
                <div class="filter-chips">
                    <button class="filter-chip active" onclick="App.filterDocuments('all')">
                        <span class="material-icons" style="font-size:18px">folder</span>
                        Todos
                    </button>
                    <button class="filter-chip" onclick="App.filterDocuments('active')">
                        <span class="material-icons" style="font-size:18px">check_circle</span>
                        Activos
                    </button>
                    <button class="filter-chip" onclick="App.filterDocuments('pending')">
                        <span class="material-icons" style="font-size:18px">pending</span>
                        Pendientes
                    </button>
                    <button class="filter-chip" onclick="App.filterDocuments('signed')">
                        <span class="material-icons" style="font-size:18px">verified</span>
                        Firmados
                    </button>
                    <button class="filter-chip" onclick="App.filterDocuments('archived')">
                        <span class="material-icons" style="font-size:18px">inventory_2</span>
                        Archivados
                    </button>
                </div>
                <div style="flex:1"></div>
                <button class="btn btn-secondary" onclick="App.openAdvancedSearch()">
                    <span class="material-icons">tune</span>
                    Filtros Avanzados
                </button>
            </div>
            
            <div class="card">
                <div class="card-content" style="padding:0">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th class="checkbox-cell">
                                    <div class="checkbox"></div>
                                </th>
                                <th>Documento</th>
                                <th>Clasificación</th>
                                <th>Versión</th>
                                <th>Estado</th>
                                <th>Fecha</th>
                                <th class="actions-cell">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${MockData.documents
                .filter(doc => {
                    const matchesFilter = !AppState.currentDocumentFilter || AppState.currentDocumentFilter === 'all' || doc.status === AppState.currentDocumentFilter;
                    const matchesSearch = !AppState.globalQuery ||
                        doc.title.toLowerCase().includes(AppState.globalQuery) ||
                        doc.author.toLowerCase().includes(AppState.globalQuery) ||
                        (doc.tags && doc.tags.toLowerCase().includes(AppState.globalQuery));
                    return matchesFilter && matchesSearch;
                })
                .map(doc => `
                                <tr onclick="App.viewDocument(${doc.id})">
                                    <td class="checkbox-cell" onclick="event.stopPropagation()">
                                        <div class="checkbox"></div>
                                    </td>
                                    <td>
                                        <div class="flex items-center gap-16">
                                            <div class="document-icon ${doc.type}">
                                                <span class="material-icons">${getDocumentIcon(doc.type)}</span>
                                            </div>
                                            <div>
                                                <div style="font-weight:500">${doc.title}</div>
                                                <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">${doc.author}</div>
                                            </div>
                                        </div>
                                    </td>
                                    <td><span class="chip">${doc.classification}</span></td>
                                    <td>v${doc.version}</td>
                                    <td><span class="chip ${getStatusClass(doc.status)}">${getStatusLabel(doc.status)}</span></td>
                                    <td>${formatDate(doc.date)}</td>
                                    <td class="actions-cell" onclick="event.stopPropagation()">
                                        <button class="icon-button" title="Ver" onclick="App.viewDocument(${doc.id})"><span class="material-icons">visibility</span></button>
                                        <button class="icon-button" title="Descargar"><span class="material-icons">download</span></button>
                                        <button class="icon-button" title="Más opciones"><span class="material-icons">more_vert</span></button>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
            
            <button class="fab fab-extended" onclick="App.openUploadModal()">
                <span class="material-icons">add</span>
                <span>Nuevo Documento</span>
            </button>
        `;
    },

    search: function () {
        return `
            <div class="page-header">
                <h1 class="page-title">Búsqueda Avanzada</h1>
                <p class="page-subtitle">Encuentra documentos usando múltiples criterios</p>
            </div>
            
            <div class="card mb-24">
                <div class="card-content">
                    <div class="search-bar" style="max-width:100%;height:56px;margin-bottom:20px">
                        <span class="material-icons">search</span>
                        <input type="text" placeholder="Buscar por título, contenido, metadatos...">
                        <button class="icon-button"><span class="material-icons">mic</span></button>
                    </div>
                    
                    <div class="flex gap-16" style="flex-wrap:wrap">
                        <div class="form-group" style="flex:1;min-width:200px;margin:0">
                            <label class="form-label">Tipo de Documento</label>
                            <select class="form-input form-select">
                                <option>Todos los tipos</option>
                                <option>Contratos</option>
                                <option>Facturas</option>
                                <option>Escrituras</option>
                                <option>Informes</option>
                            </select>
                        </div>
                        <div class="form-group" style="flex:1;min-width:200px;margin:0">
                            <label class="form-label">Clasificación</label>
                            <select class="form-input form-select">
                                <option>Todas</option>
                                <option>Público</option>
                                <option>Interno</option>
                                <option>Confidencial</option>
                                <option>Estrictamente Confidencial</option>
                            </select>
                        </div>
                        <div class="form-group" style="flex:1;min-width:200px;margin:0">
                            <label class="form-label">Fecha Desde</label>
                            <input type="date" class="form-input">
                        </div>
                        <div class="form-group" style="flex:1;min-width:200px;margin:0">
                            <label class="form-label">Fecha Hasta</label>
                            <input type="date" class="form-input">
                        </div>
                    </div>
                    
                    <div class="flex justify-between items-center mt-24">
                        <div class="filter-chips">
                            <span class="chip primary">Contratos <span class="material-icons" style="font-size:16px;cursor:pointer">close</span></span>
                            <span class="chip primary">2026 <span class="material-icons" style="font-size:16px;cursor:pointer">close</span></span>
                        </div>
                        <button class="btn btn-primary">
                            <span class="material-icons">search</span>
                            Buscar
                        </button>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <span class="card-title">Resultados (${MockData.documents.length})</span>
                    <div class="flex gap-8">
                        <button class="icon-button"><span class="material-icons">view_list</span></button>
                        <button class="icon-button"><span class="material-icons">grid_view</span></button>
                    </div>
                </div>
                <div class="card-content">
                    <div class="recent-documents">
                        ${MockData.documents.map(doc => `
                            <div class="list-item" onclick="App.viewDocument(${doc.id})">
                                <div class="document-icon ${doc.type}">
                                    <span class="material-icons">${getDocumentIcon(doc.type)}</span>
                                </div>
                                <div class="list-item-content">
                                    <div class="list-item-title">${doc.title}</div>
                                    <div class="list-item-subtitle">${doc.author} • ${doc.classification} • v${doc.version}</div>
                                </div>
                                <div class="list-item-trailing">${formatDate(doc.date)}</div>
                            </div>
                        `).join('')}
                    </div>
                </div>
            </div>
        `;
    },

    expedientes: function () {
        return `
            <div class="page-header">
                <h1 class="page-title">Expedientes</h1>
                <p class="page-subtitle">Gestión de casos y expedientes documentales</p>
            </div>
            
            <div class="documents-toolbar">
                <div class="filter-chips">
                    <button class="filter-chip active">Todos</button>
                    <button class="filter-chip">Activos</button>
                    <button class="filter-chip">Pendientes</button>
                    <button class="filter-chip">Cerrados</button>
                </div>
            </div>
            
            <div class="card">
                <div class="card-content" style="padding:0">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Número</th>
                                <th>Título</th>
                                <th>Documentos</th>
                                <th>Responsable</th>
                                <th>Estado</th>
                                <th>Fecha Apertura</th>
                                <th class="actions-cell">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${MockData.expedientes.map(exp => `
                                <tr onclick="App.viewExpediente(${exp.id})">
                                    <td><strong>${exp.number}</strong></td>
                                    <td>${exp.title}</td>
                                    <td>
                                        <span class="chip">${exp.documents} docs</span>
                                    </td>
                                    <td>${exp.responsible}</td>
                                    <td><span class="chip ${getStatusClass(exp.status)}">${getStatusLabel(exp.status)}</span></td>
                                    <td>${formatDate(exp.openDate)}</td>
                                    <td class="actions-cell" onclick="event.stopPropagation()">
                                        <button class="icon-button" title="Ver" onclick="App.viewExpediente(${exp.id})"><span class="material-icons">visibility</span></button>
                                        <button class="icon-button" title="Editar" onclick="App.editExpediente(${exp.id})"><span class="material-icons">edit</span></button>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
            
            <button class="fab fab-extended" onclick="App.openNewExpedienteModal()">
                <span class="material-icons">add</span>
                <span>Nuevo Expediente</span>
            </button>
        `;
    },

    workflows: function () {
        return `
            <div class="page-header">
                <h1 class="page-title">Flujos de Trabajo</h1>
                <p class="page-subtitle">Gestiona aprobaciones, firmas y revisiones</p>
            </div>
            
            <div class="tabs">
                <div class="tab active">Pendientes (${MockData.workflows.filter(w => w.status === 'pending').length})</div>
                <div class="tab">Aprobados</div>
                <div class="tab">Rechazados</div>
                <div class="tab">Todos</div>
            </div>
            
            <div>
                ${MockData.workflows.map(w => `
                    <div class="workflow-card" onclick="App.viewWorkflow(${w.id})" style="cursor:pointer">
                        <div class="workflow-status ${w.status}">
                            <span class="material-icons">${getWorkflowIcon(w.type)}</span>
                        </div>
                        <div class="workflow-content">
                            <div class="workflow-title">${w.title}</div>
                            <div class="workflow-meta">
                                <span><span class="material-icons" style="font-size:16px;vertical-align:middle">person</span> ${w.requester}</span>
                                <span><span class="material-icons" style="font-size:16px;vertical-align:middle">schedule</span> ${formatDate(w.date)}</span>
                                <span class="chip ${w.priority === 'high' ? 'error' : w.priority === 'medium' ? 'warning' : ''}">${getPriorityLabel(w.priority)}</span>
                            </div>
                        </div>
                        <div class="workflow-actions" onclick="event.stopPropagation()">
                            ${w.status === 'pending' ? `
                                <button class="btn btn-primary" onclick="App.approveWorkflow(${w.id})">
                                    <span class="material-icons">check</span>
                                    Aprobar
                                </button>
                                <button class="btn btn-secondary" onclick="App.rejectWorkflow(${w.id})">
                                    <span class="material-icons">close</span>
                                </button>
                            ` : `
                                <button class="btn btn-text" onclick="App.viewWorkflow(${w.id})">Ver Detalles</button>
                            `}
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    },

    signature: function () {
        return `
            <div class="page-header">
                <h1 class="page-title">Firma Digital</h1>
                <p class="page-subtitle">Firma documentos con certificado digital homologado (Ley 25.506)</p>
            </div>
            
            <div class="signature-preview">
                <div class="document-preview">
                    <div class="flex justify-between items-center mb-16">
                        <span style="font-weight:500">Contrato de Servicios - Cliente ABC.pdf</span>
                        <div class="flex gap-8">
                            <button class="icon-button"><span class="material-icons">zoom_out</span></button>
                            <button class="icon-button"><span class="material-icons">zoom_in</span></button>
                            <button class="icon-button"><span class="material-icons">fullscreen</span></button>
                        </div>
                    </div>
                    <div class="preview-placeholder">
                        <span class="material-icons">picture_as_pdf</span>
                        <p>Vista previa del documento</p>
                        <p style="font-size:12px;margin-top:8px">Página 1 de 5</p>
                    </div>
                </div>
                
                <div class="signature-panel">
                    <div class="certificate-card">
                        <div class="certificate-header">
                            <div class="certificate-icon">
                                <span class="material-icons">verified_user</span>
                            </div>
                            <div class="certificate-info">
                                <h4>Certificado Digital</h4>
                                <p>AC Raíz Argentina</p>
                            </div>
                        </div>
                        <div class="certificate-details">
                            <div class="certificate-row">
                                <span>Titular:</span>
                                <span>María García</span>
                            </div>
                            <div class="certificate-row">
                                <span>CUIL:</span>
                                <span>27-12345678-9</span>
                            </div>
                            <div class="certificate-row">
                                <span>Válido hasta:</span>
                                <span>15/06/2027</span>
                            </div>
                            <div class="certificate-row">
                                <span>Certificador:</span>
                                <span>ENCODE S.A.</span>
                            </div>
                            <div class="certificate-row">
                                <span>Estado:</span>
                                <span style="color:var(--md-sys-color-secondary)">✓ Vigente</span>
                            </div>
                        </div>
                    </div>
                    
                    <div class="card">
                        <div class="card-content">
                            <h4 style="margin-bottom:16px">Opciones de Firma</h4>
                            <div class="form-group">
                                <label class="form-label">Tipo de Firma</label>
                                <select class="form-input form-select">
                                    <option>Firma Digital Calificada (PAdES)</option>
                                    <option>Firma Avanzada</option>
                                    <option>Firma Electrónica Simple</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Motivo de la Firma</label>
                                <input type="text" class="form-input" placeholder="Ej: Aprobación del contrato">
                            </div>
                            <div class="checkbox-wrapper" style="margin-bottom:16px">
                                <div class="checkbox checked">
                                    <span class="material-icons" style="font-size:16px">check</span>
                                </div>
                                <span>Incluir sellado de tiempo (TSA)</span>
                            </div>
                            <div class="checkbox-wrapper">
                                <div class="checkbox">
                                </div>
                                <span>Firma visible en documento</span>
                            </div>
                        </div>
                    </div>
                    
                    <button class="btn btn-primary" style="width:100%;height:56px;font-size:16px" onclick="App.signDocument()">
                        <span class="material-icons">draw</span>
                        Firmar Documento
                    </button>
                    
                    <p style="font-size:12px;color:var(--md-sys-color-on-surface-variant);text-align:center">
                        Al firmar, confirma haber leído y aceptado el contenido del documento
                    </p>
                </div>
            </div>
        `;
    },

    audit: function () {
        return `
            <div class="page-header">
                <h1 class="page-title">Auditoría</h1>
                <p class="page-subtitle">Registro completo de actividad del sistema (ISO 27001)</p>
            </div>
            
            <div class="audit-filters">
                <input type="text" class="form-input" placeholder="Buscar en logs..." style="min-width:300px">
                <select class="form-input form-select" style="min-width:160px">
                    <option>Todas las acciones</option>
                    <option>Visualización</option>
                    <option>Descarga</option>
                    <option>Modificación</option>
                    <option>Firma Digital</option>
                    <option>Acceso</option>
                </select>
                <select class="form-input form-select" style="min-width:140px">
                    <option>Hoy</option>
                    <option>Últimos 7 días</option>
                    <option>Últimos 30 días</option>
                    <option>Personalizado</option>
                </select>
                <button class="btn btn-secondary">
                    <span class="material-icons">file_download</span>
                    Exportar
                </button>
            </div>
            
            <div class="card">
                <div class="card-content" style="padding:0">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Fecha y Hora</th>
                                <th>Usuario</th>
                                <th>Acción</th>
                                <th>Recurso</th>
                                <th>IP</th>
                                <th>Resultado</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${MockData.auditLogs.map(log => `
                                <tr>
                                    <td><code style="font-size:12px">${log.timestamp}</code></td>
                                    <td>${log.user}</td>
                                    <td><span class="audit-badge info">${log.action}</span></td>
                                    <td>${log.resource}</td>
                                    <td><code style="font-size:12px">${log.ip}</code></td>
                                    <td>
                                        <span class="audit-badge ${log.result}">
                                            <span class="material-icons" style="font-size:14px">${log.result === 'success' ? 'check_circle' : 'error'}</span>
                                            ${log.result === 'success' ? 'Exitoso' : 'Fallido'}
                                        </span>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
            
            <div class="flex justify-between items-center mt-16">
                <span style="color:var(--md-sys-color-on-surface-variant)">Mostrando 1-8 de 1,234 registros</span>
                <div class="flex gap-8">
                    <button class="btn btn-secondary" disabled>Anterior</button>
                    <button class="btn btn-secondary">Siguiente</button>
                </div>
            </div>
        `;
    },

    retention: function () {
        return `
            <div class="page-header">
                <h1 class="page-title">Retención y Disposición</h1>
                <p class="page-subtitle">Gestión del ciclo de vida documental (ISO 15489)</p>
            </div>
            
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon tertiary">
                        <span class="material-icons">schedule</span>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">12</div>
                        <div class="stat-label">Por Vencer (30 días)</div>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon error">
                        <span class="material-icons">warning</span>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">3</div>
                        <div class="stat-label">Vencidos Pendientes</div>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon secondary">
                        <span class="material-icons">delete_forever</span>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">156</div>
                        <div class="stat-label">Eliminados Este Año</div>
                    </div>
                </div>
            </div>
            
            <div class="tabs">
                <div class="tab active">Próximos a Vencer</div>
                <div class="tab">Políticas de Retención</div>
                <div class="tab">Historial de Disposición</div>
            </div>
            
            <div class="card">
                <div class="card-content">
                    ${[
                { title: 'Facturas Proveedores 2016', type: 'Eliminación', days: 5, series: 'Contabilidad' },
                { title: 'Contratos Laborales 2014', type: 'Archivo Histórico', days: 12, series: 'RRHH' },
                { title: 'Correspondencia Clientes 2021', type: 'Eliminación', days: 18, series: 'Comercial' }
            ].map(item => `
                        <div class="workflow-card">
                            <div class="workflow-status ${item.days <= 7 ? 'rejected' : 'pending'}">
                                <span class="material-icons">event</span>
                            </div>
                            <div class="workflow-content">
                                <div class="workflow-title">${item.title}</div>
                                <div class="workflow-meta">
                                    <span>${item.series}</span>
                                    <span>Acción: ${item.type}</span>
                                    <span class="chip ${item.days <= 7 ? 'error' : 'warning'}">${item.days} días restantes</span>
                                </div>
                            </div>
                            <div class="workflow-actions">
                                <button class="btn btn-primary">Ejecutar</button>
                                <button class="btn btn-secondary">Postergar</button>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    },

    admin: function () {
        const permissionLabels = {
            create: 'Crear', read: 'Leer', edit: 'Editar', delete: 'Eliminar',
            download: 'Descargar', print: 'Imprimir', sign: 'Firmar', approve: 'Aprobar',
            manage_permissions: 'Permisos', configure: 'Configurar'
        };

        const actionLabels = {
            archive: 'Archivar', delete: 'Eliminar', review: 'Revisar', permanent: 'Permanente'
        };

        const renderAdminContent = () => {
            switch (AppState.adminActiveTab) {
                case 'users':
                    return `
                        <div class="flex justify-between items-center mb-24">
                            <h3>Gestión de Usuarios</h3>
                            <button class="btn btn-primary" onclick="App.openNewUserModal()">
                                <span class="material-icons">person_add</span>
                                Nuevo Usuario
                            </button>
                        </div>
                        ${MockData.users.map(user => `
                            <div class="user-list-item">
                                <div class="user-avatar-sm">${user.initials}</div>
                                <div class="user-info">
                                    <div class="user-name">${user.name}</div>
                                    <div class="user-role">${user.email}</div>
                                </div>
                                <span class="chip ${user.role === 'Administrador' ? 'primary' : ''}">${user.role}</span>
                                <span class="chip ${user.status === 'active' ? 'success' : ''}">${user.status === 'active' ? 'Activo' : 'Inactivo'}</span>
                                <button class="icon-button"><span class="material-icons">edit</span></button>
                                <button class="icon-button"><span class="material-icons">more_vert</span></button>
                            </div>
                        `).join('')}
                    `;
                case 'roles':
                    return `
                        <div class="flex justify-between items-center mb-24">
                            <h3>Roles y Permisos</h3>
                            <button class="btn btn-primary">
                                <span class="material-icons">add</span>
                                Nuevo Rol
                            </button>
                        </div>
                        <div class="roles-table-container">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th style="min-width:150px">Rol</th>
                                        ${Object.keys(permissionLabels).map(p => `<th class="text-center" style="font-size:11px;padding:8px 4px">${permissionLabels[p]}</th>`).join('')}
                                        <th>Acciones</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${MockData.roles.map(role => `
                                        <tr>
                                            <td>
                                                <div style="font-weight:500">${role.name}</div>
                                                <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">${role.description}</div>
                                            </td>
                                            ${Object.keys(permissionLabels).map(p => `
                                                <td class="text-center">
                                                    <span class="material-icons" style="font-size:20px;color:${role.permissions[p] ? 'var(--md-sys-color-secondary)' : 'var(--md-sys-color-outline-variant)'}">
                                                        ${role.permissions[p] ? 'check_circle' : 'cancel'}
                                                    </span>
                                                </td>
                                            `).join('')}
                                            <td>
                                                <button class="icon-button"><span class="material-icons">edit</span></button>
                                            </td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    `;
                case 'types':
                    return `
                        <div class="flex justify-between items-center mb-24">
                            <h3>Tipos Documentales</h3>
                            <button class="btn btn-primary" onclick="App.openDocTypeModal()">
                                <span class="material-icons">add</span>
                                Nuevo Tipo
                            </button>
                        </div>
                        <div class="doc-types-grid">
                            ${MockData.documentTypes.map(dt => `
                                <div class="doc-type-card">
                                    <div class="doc-type-header">
                                        <div class="doc-type-code">${dt.code}</div>
                                        <div class="doc-type-info">
                                            <div class="doc-type-name">${dt.name}</div>
                                            <div class="doc-type-desc">${dt.description}</div>
                                        </div>
                                        <button class="icon-button" onclick="App.openDocTypeModal(${dt.id})"><span class="material-icons">edit</span></button>
                                    </div>
                                    <div class="doc-type-meta">
                                        <span class="chip">
                                            <span class="material-icons" style="font-size:14px">schedule</span>
                                            ${dt.retentionYears === 0 ? 'Permanente' : dt.retentionYears + ' años'}
                                        </span>
                                        <span class="chip">
                                            <span class="material-icons" style="font-size:14px">input</span>
                                            ${dt.fields.length} campos
                                        </span>
                                    </div>
                                    ${dt.fields.length > 0 ? `
                                        <div class="doc-type-fields">
                                            <div class="doc-type-fields-title">Campos personalizados:</div>
                                            <div class="doc-type-fields-list">
                                                ${dt.fields.slice(0, 4).map(f => `
                                                    <span class="field-tag ${f.required ? 'required' : ''}">${f.label}${f.required ? ' *' : ''}</span>
                                                `).join('')}
                                                ${dt.fields.length > 4 ? `<span class="field-tag">+${dt.fields.length - 4} más</span>` : ''}
                                            </div>
                                        </div>
                                    ` : ''}
                                </div>
                            `).join('')}
                        </div>
                    `;
                case 'series':
                    const rootSeries = MockData.documentSeries.filter(s => s.parentId === null);
                    const getChildren = (parentId) => MockData.documentSeries.filter(s => s.parentId === parentId);

                    return `
                        <div class="flex justify-between items-center mb-24">
                            <h3>Series Documentales</h3>
                            <button class="btn btn-primary" onclick="App.openSeriesModal()">
                                <span class="material-icons">add</span>
                                Nueva Serie
                            </button>
                        </div>
                        <div class="series-tree">
                            ${rootSeries.map(series => `
                                <div class="series-item root">
                                    <div class="series-row">
                                        <span class="material-icons series-icon">folder</span>
                                        <div class="series-info">
                                            <div class="series-name"><strong>${series.code}</strong> - ${series.name}</div>
                                            <div class="series-desc">${series.description}</div>
                                        </div>
                                        <span class="chip">${series.retentionYears === 0 ? 'Permanente' : series.retentionYears + ' años'}</span>
                                        <button class="icon-button" onclick="App.openSeriesModal(${series.id})" title="Editar"><span class="material-icons">edit</span></button>
                                        <button class="icon-button" onclick="App.openSeriesModal(null, ${series.id})" title="Agregar Sub-Serie"><span class="material-icons">add</span></button>
                                    </div>
                                    ${getChildren(series.id).length > 0 ? `
                                        <div class="series-children">
                                            ${getChildren(series.id).map(child => `
                                                <div class="series-item child">
                                                    <div class="series-row">
                                                        <span class="material-icons series-icon">subdirectory_arrow_right</span>
                                                        <span class="material-icons series-icon">folder_open</span>
                                                        <div class="series-info">
                                                            <div class="series-name"><strong>${child.code}</strong> - ${child.name}</div>
                                                            <div class="series-desc">${child.description}</div>
                                                        </div>
                                                        <span class="chip">${child.retentionYears === 0 ? 'Permanente' : child.retentionYears + ' años'}</span>
                                                        <button class="icon-button" onclick="App.openSeriesModal(${child.id})" title="Editar Sub-Serie"><span class="material-icons">edit</span></button>
                                                    </div>
                                                </div>
                                            `).join('')}
                                        </div>
                                    ` : ''}
                                </div>
                            `).join('')}
                        </div>
                    `;
                case 'retention':
                    return `
                        <div class="flex justify-between items-center mb-24">
                            <h3>Políticas de Retención</h3>
                            <button class="btn btn-primary" onclick="App.openPolicyModal()">
                                <span class="material-icons">add</span>
                                Nueva Política
                            </button>
                        </div>
                        ${MockData.retentionPolicies.map(policy => `
                            <div class="retention-card">
                                <div class="retention-header">
                                    <div class="retention-icon ${policy.action}">
                                        <span class="material-icons">${policy.action === 'permanent' ? 'lock' : policy.action === 'delete' ? 'delete' : policy.action === 'archive' ? 'inventory_2' : 'rate_review'}</span>
                                    </div>
                                    <div class="retention-info">
                                        <div class="retention-name">${policy.name}</div>
                                        <div class="retention-desc">${policy.description}</div>
                                    </div>
                                    <div class="retention-meta">
                                        <span class="chip ${policy.action === 'permanent' ? 'primary' : policy.action === 'delete' ? 'error' : 'warning'}">
                                            ${policy.years === 0 ? 'Permanente' : policy.years + ' años'}
                                        </span>
                                        <span class="chip">${actionLabels[policy.action]}</span>
                                    </div>
                                    <button class="icon-button" title="Editar Política" onclick="App.openPolicyModal(${policy.id})"><span class="material-icons">edit</span></button>
                                </div>
                                
                                <div class="workflow-stepper-container">
                                    <div class="workflow-stepper-title">Flujo de Trabajo del Ciclo de Vida</div>
                                    <div class="workflow-stepper">
                                        ${policy.workflow ? policy.workflow.map((step, index) => `
                                            <div class="workflow-step">
                                                <div class="step-circle" title="${step.action}">${step.order}</div>
                                                <div class="step-content">
                                                    <div class="step-name">${step.name}</div>
                                                    <div class="step-role-badge">${step.role}</div>
                                                    <div class="step-sla">SLA: ${step.sla}</div>
                                                </div>
                                                ${index < policy.workflow.length - 1 ? '<div class="step-connector"></div>' : ''}
                                            </div>
                                        `).join('') : '<div style="padding:16px;color:var(--md-sys-color-on-surface-variant)">Sin flujo definido</div>'}
                                    </div>
                                    <div style="text-align:right;margin-top:16px;border-top:1px solid var(--md-sys-color-outline-variant);padding-top:12px;">
                                        <button class="btn btn-text" onclick="App.openWorkflowEditor(${policy.id})">
                                            <span class="material-icons" style="font-size:18px;margin-right:8px;">account_tree</span>
                                            Editar Flujo
                                        </button>
                                    </div>
                                </div>

                                <div class="retention-series">
                                    <span style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">Series aplicables:</span>
                                    ${policy.seriesIds.map(sid => {
                        const s = MockData.documentSeries.find(x => x.id === sid);
                        return s ? `<span class="chip" style="font-size:11px">${s.code}</span>` : '';
                    }).join('')}
                                </div>
                            </div>
                        `).join('')}
                    `;
                case 'config':
                    return `
                        <div class="flex justify-between items-center mb-24">
                            <h3>Configuración General</h3>
                            <button class="btn btn-primary">
                                <span class="material-icons">save</span>
                                Guardar Cambios
                            </button>
                        </div>
                        <div class="config-sections">
                            <div class="config-section">
                                <h4><span class="material-icons">business</span> Datos de la Organización</h4>
                                <div class="config-form">
                                    <div class="form-group">
                                        <label class="form-label">Nombre de la Organización</label>
                                        <input type="text" class="form-input" value="Empresa S.A.">
                                    </div>
                                    <div class="form-group">
                                        <label class="form-label">CUIT</label>
                                        <input type="text" class="form-input" value="30-12345678-9">
                                    </div>
                                    <div class="form-group">
                                        <label class="form-label">Domicilio Legal</label>
                                        <input type="text" class="form-input" value="Av. Corrientes 1234, CABA">
                                    </div>
                                </div>
                            </div>
                            <div class="config-section">
                                <h4><span class="material-icons">security</span> Seguridad</h4>
                                <div class="config-form">
                                    <div class="checkbox-wrapper" style="margin-bottom:16px">
                                        <div class="checkbox checked"><span class="material-icons" style="font-size:16px">check</span></div>
                                        <span>Requerir MFA para administradores</span>
                                    </div>
                                    <div class="checkbox-wrapper" style="margin-bottom:16px">
                                        <div class="checkbox checked"><span class="material-icons" style="font-size:16px">check</span></div>
                                        <span>Bloquear cuenta después de 5 intentos fallidos</span>
                                    </div>
                                    <div class="checkbox-wrapper" style="margin-bottom:16px">
                                        <div class="checkbox"><span class="material-icons" style="font-size:16px"></span></div>
                                        <span>Forzar cambio de contraseña cada 90 días</span>
                                    </div>
                                    <div class="form-group" style="margin-top:16px">
                                        <label class="form-label">Tiempo de sesión inactiva (minutos)</label>
                                        <input type="number" class="form-input" value="30" style="max-width:120px">
                                    </div>
                                </div>
                            </div>
                            <div class="config-section">
                                <h4><span class="material-icons">cloud</span> Almacenamiento</h4>
                                <div class="config-form">
                                    <div class="storage-bar">
                                        <div class="storage-used" style="width:78%"></div>
                                    </div>
                                    <div style="display:flex;justify-content:space-between;font-size:12px;color:var(--md-sys-color-on-surface-variant);margin-top:8px">
                                        <span>7.8 TB usados</span>
                                        <span>10 TB totales</span>
                                    </div>
                                    <div class="form-group" style="margin-top:16px">
                                        <label class="form-label">Tamaño máximo de archivo (MB)</label>
                                        <input type="number" class="form-input" value="50" style="max-width:120px">
                                    </div>
                                </div>
                            </div>
                            <div class="config-section">
                                <h4><span class="material-icons">draw</span> Firma Digital</h4>
                                <div class="config-form">
                                    <div class="form-group">
                                        <label class="form-label">Certificador Habilitado</label>
                                        <select class="form-input form-select">
                                            <option selected>ENCODE S.A.</option>
                                            <option>AC Camerfirma</option>
                                            <option>Identidad Digital S.A.</option>
                                        </select>
                                    </div>
                                    <div class="checkbox-wrapper" style="margin-bottom:16px">
                                        <div class="checkbox checked"><span class="material-icons" style="font-size:16px">check</span></div>
                                        <span>Incluir sellado de tiempo (TSA) en firmas</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    `;
                default:
                    return '<p>Seleccione una opción del menú</p>';
            }
        };

        return `
            <div class="page-header">
                <h1 class="page-title">Administración</h1>
                <p class="page-subtitle">Configuración del sistema y gestión de usuarios</p>
            </div>
            
            <div class="admin-layout">
                <div class="admin-sidebar">
                    <div class="nav-item ${AppState.adminActiveTab === 'users' ? 'active' : ''}" onclick="App.setAdminTab('users')">
                        <span class="material-icons">people</span>
                        <span class="nav-item-text">Usuarios</span>
                    </div>
                    <div class="nav-item ${AppState.adminActiveTab === 'roles' ? 'active' : ''}" onclick="App.setAdminTab('roles')">
                        <span class="material-icons">admin_panel_settings</span>
                        <span class="nav-item-text">Roles y Permisos</span>
                    </div>
                    <div class="nav-item ${AppState.adminActiveTab === 'types' ? 'active' : ''}" onclick="App.setAdminTab('types')">
                        <span class="material-icons">category</span>
                        <span class="nav-item-text">Tipos Documentales</span>
                    </div>
                    <div class="nav-item ${AppState.adminActiveTab === 'series' ? 'active' : ''}" onclick="App.setAdminTab('series')">
                        <span class="material-icons">account_tree</span>
                        <span class="nav-item-text">Series Documentales</span>
                    </div>
                    <div class="nav-item ${AppState.adminActiveTab === 'retention' ? 'active' : ''}" onclick="App.setAdminTab('retention')">
                        <span class="material-icons">event_repeat</span>
                        <span class="nav-item-text">Políticas Retención</span>
                    </div>
                    <div class="nav-item ${AppState.adminActiveTab === 'config' ? 'active' : ''}" onclick="App.setAdminTab('config')">
                        <span class="material-icons">settings</span>
                        <span class="nav-item-text">Configuración General</span>
                    </div>
                </div>
                
                <div class="admin-content">
                    ${renderAdminContent()}
                </div>
            </div>
        `;
    },

    privacy: function () {
        return `
            <div class="page-header">
                <h1 class="page-title">Protección de Datos</h1>
                <p class="page-subtitle">Cumplimiento Ley 25.326 - Protección de Datos Personales</p>
            </div>
            
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon primary">
                        <span class="material-icons">privacy_tip</span>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">1,234</div>
                        <div class="stat-label">Documentos con Datos Personales</div>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon tertiary">
                        <span class="material-icons">pending_actions</span>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">3</div>
                        <div class="stat-label">Solicitudes ARCO Pendientes</div>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon secondary">
                        <span class="material-icons">check_circle</span>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">100%</div>
                        <div class="stat-label">Cumplimiento de Plazos</div>
                    </div>
                </div>
            </div>
            
            <div class="tabs">
                <div class="tab active">Solicitudes ARCO</div>
                <div class="tab">Datos Sensibles</div>
                <div class="tab">Consentimientos</div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <span class="card-title">Solicitudes de Titulares</span>
                    <button class="btn btn-primary">
                        <span class="material-icons">add</span>
                        Nueva Solicitud
                    </button>
                </div>
                <div class="card-content">
                    ${[
                { id: 'ARCO-2026-015', type: 'Acceso', titular: 'Juan Carlos Fernández', date: '2026-01-19', status: 'pending', deadline: 5 },
                { id: 'ARCO-2026-014', type: 'Rectificación', titular: 'María Elena Gómez', date: '2026-01-17', status: 'pending', deadline: 7 },
                { id: 'ARCO-2026-013', type: 'Cancelación', titular: 'Roberto Martínez', date: '2026-01-15', status: 'completed', deadline: 0 }
            ].map(req => `
                        <div class="workflow-card">
                            <div class="workflow-status ${req.status === 'pending' ? 'pending' : 'approved'}">
                                <span class="material-icons">${req.type === 'Acceso' ? 'visibility' : req.type === 'Rectificación' ? 'edit' : 'delete'}</span>
                            </div>
                            <div class="workflow-content">
                                <div class="workflow-title">${req.id} - ${req.type}</div>
                                <div class="workflow-meta">
                                    <span>Titular: ${req.titular}</span>
                                    <span>Recibido: ${formatDate(req.date)}</span>
                                    ${req.status === 'pending' ? `<span class="chip ${req.deadline <= 5 ? 'error' : 'warning'}">${req.deadline} días hábiles restantes</span>` : '<span class="chip success">Completada</span>'}
                                </div>
                            </div>
                            <div class="workflow-actions">
                                <button class="btn ${req.status === 'pending' ? 'btn-primary' : 'btn-text'}">${req.status === 'pending' ? 'Gestionar' : 'Ver Detalles'}</button>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    }
};

// Helper Functions
function getDocumentIcon(type) {
    const icons = {
        pdf: 'picture_as_pdf',
        doc: 'description',
        xls: 'table_chart',
        img: 'image'
    };
    return icons[type] || 'insert_drive_file';
}

function getStatusClass(status) {
    const classes = {
        active: 'success',
        pending: 'warning',
        signed: 'primary',
        archived: '',
        closed: ''
    };
    return classes[status] || '';
}

function getStatusLabel(status) {
    const labels = {
        active: 'Activo',
        pending: 'Pendiente',
        signed: 'Firmado',
        archived: 'Archivado',
        closed: 'Cerrado',
        approved: 'Aprobado',
        rejected: 'Rechazado'
    };
    return labels[status] || status;
}

function getWorkflowIcon(type) {
    const icons = {
        approval: 'thumb_up',
        signature: 'draw',
        review: 'rate_review',
        validation: 'verified'
    };
    return icons[type] || 'task';
}

function getPriorityLabel(priority) {
    const labels = {
        high: 'Urgente',
        medium: 'Normal',
        low: 'Baja'
    };
    return labels[priority] || priority;
}

function formatDate(dateStr) {
    const date = new Date(dateStr);
    return date.toLocaleDateString('es-AR', { day: '2-digit', month: 'short', year: 'numeric' });
}

// Application Controller
const App = {
    init: function () {
        this.bindEvents();
        this.render();
    },

    bindEvents: function () {
        // Menu toggle
        document.getElementById('menuToggle')?.addEventListener('click', () => {
            AppState.sidebarCollapsed = !AppState.sidebarCollapsed;
            document.querySelector('.sidebar').classList.toggle('collapsed', AppState.sidebarCollapsed);
        });

        // Navigation clicks
        document.querySelectorAll('.nav-item[data-page]').forEach(item => {
            item.addEventListener('click', () => {
                this.navigate(item.dataset.page);
            });
        });

        // Global Search
        const topSearchBar = document.querySelector('.top-app-bar .search-bar input');
        if (topSearchBar) {
            topSearchBar.addEventListener('input', (e) => {
                this.performGlobalSearch(e.target.value);
            });
        }
    },

    performGlobalSearch: function (query) {
        AppState.globalQuery = query.toLowerCase();
        if (['documents', 'expedientes', 'search'].includes(AppState.currentPage)) {
            this.renderPage();
        }
    },

    // Modal close on overlay click
    document.querySelectorAll('.modal-overlay').forEach(overlay => {
        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) {
                this.closeModals();
            }
        });
    });
},

    navigate: function (page) {
        AppState.currentPage = page;

// Update active nav item
document.querySelectorAll('.nav-item').forEach(item => {
    item.classList.toggle('active', item.dataset.page === page);
});

// Render page content
this.renderPage();
    },

render: function () {
    this.renderPage();
},

renderPage: function () {
    const contentArea = document.getElementById('pageContent');
    const renderer = PageRenderers[AppState.currentPage];

    if (renderer && contentArea) {
        contentArea.innerHTML = renderer();
    }
},

// Modal Handlers
openUploadModal: function () {
    document.getElementById('uploadModal').classList.add('active');
},

closeModals: function () {
    document.querySelectorAll('.modal-overlay').forEach(m => m.classList.remove('active'));
},

openNewUserModal: function () {
    const modal = document.getElementById('userModal');
    const title = document.getElementById('userModalTitle');
    const idField = document.getElementById('userId');
    const roleSelect = document.getElementById('userRole');

    // Populate Roles
    roleSelect.innerHTML = MockData.roles.map(r => `<option value="${r.name}">${r.name}</option>`).join('');

    // Reset form
    title.textContent = 'Nuevo Usuario';
    idField.value = '';
    document.getElementById('userName').value = '';
    document.getElementById('userEmail').value = '';
    document.getElementById('userRole').value = 'Usuario';
    document.getElementById('userStatus').value = 'active';

    modal.classList.add('active');
},

saveUser: function () {
    const modal = document.getElementById('userModal');
    const idStr = document.getElementById('userId').value;
    const id = idStr ? parseInt(idStr) : null;

    const name = document.getElementById('userName').value;
    const email = document.getElementById('userEmail').value;
    const role = document.getElementById('userRole').value;
    const status = document.getElementById('userStatus').value;

    if (!name || !email) {
        alert('Nombre y correo son obligatorios');
        return;
    }

    const userData = {
        name,
        email,
        role,
        status,
        initials: name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase()
    };

    if (id) {
        const user = MockData.users.find(u => u.id === id);
        if (user) Object.assign(user, userData);
    } else {
        MockData.users.push({
            id: MockData.users.length + 100,
            ...userData
        });
    }

    modal.classList.remove('active');
    const toast = document.getElementById('toast');
    document.getElementById('toastMessage').textContent = id ? 'Usuario actualizado' : 'Usuario creado';
    toast.style.display = 'block';
    setTimeout(() => toast.style.display = 'none', 3000);

    if (AppState.adminActiveTab === 'users') {
        this.renderPage();
    }
},

openAdvancedSearch: function () {
    this.navigate('search');
},

// Document Actions
viewDocument: function (id) {
    const doc = MockData.documents.find(d => d.id === id);
    if (!doc) return;

    AppState.currentDocumentId = id;

    let expedienteInfo = '';
    if (doc.expedienteId) {
        const exp = MockData.expedientes.find(e => e.id === doc.expedienteId);
        if (exp) {
            expedienteInfo = `
                    <div class="card mb-24" style="cursor:pointer" onclick="App.viewExpediente(${exp.id})">
                        <div class="card-content">
                            <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant);margin-bottom:4px">Expediente Relacionado</div>
                            <div style="font-weight:500;color:var(--md-sys-color-primary)">${exp.number}</div>
                            <div style="font-size:13px">${exp.title}</div>
                        </div>
                    </div>
                 `;
        }
    }

    const customFieldsHtml = doc.customValues ? Object.entries(doc.customValues).map(([key, value]) => `
            <div style="margin-bottom:12px">
                <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">${key}</div>
                <div style="font-size:14px;color:var(--md-sys-color-on-surface)">${value}</div>
            </div>
        `).join('') : '<div style="font-size:13px;color:var(--md-sys-color-on-surface-variant);font-style:italic">Sin metadatos específicos</div>';

    const content = `
            <div class="page-header">
                <div class="flex items-center gap-16">
                    <button class="icon-button" onclick="App.navigate('documents')">
                        <span class="material-icons">arrow_back</span>
                    </button>
                    <div style="flex:1;min-width:0">
                        <div class="flex items-center gap-8">
                            <h1 class="page-title" style="font-size:20px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis" title="${doc.title}">${doc.title}</h1>
                            <span class="chip ${getStatusClass(doc.status)}">${getStatusLabel(doc.status)}</span>
                        </div>
                         <div style="font-size:13px;color:var(--md-sys-color-on-surface-variant)">v${doc.version} • ${doc.type.toUpperCase()} • Modificado el ${formatDate(doc.date)} por ${doc.author}</div>
                    </div>
                </div>
                <div class="flex gap-8">
                    <button class="btn btn-secondary" title="Imprimir">
                        <span class="material-icons">print</span>
                    </button>
                    <button class="btn btn-secondary" title="Compartir">
                        <span class="material-icons">share</span>
                    </button>
                    <button class="btn btn-primary" title="Descargar">
                        <span class="material-icons">download</span> Descargar
                    </button>
                </div>
            </div>

            <div class="grid" style="grid-template-columns: 1fr 320px; gap:24px; height: calc(100vh - 180px);">
                <!-- Document Preview (Left) -->
                <div class="card" style="margin:0;display:flex;flex-direction:column;overflow:hidden">
                    <div class="card-header" style="padding:12px 16px;background:var(--md-sys-color-surface-variant)">
                        <span style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">Vista Previa</span>
                         <div class="flex gap-8">
                            <button class="icon-button" style="width:24px;height:24px"><span class="material-icons" style="font-size:18px">zoom_in</span></button>
                             <button class="icon-button" style="width:24px;height:24px"><span class="material-icons" style="font-size:18px">zoom_out</span></button>
                        </div>
                    </div>
                    <div style="flex:1;background:#525659;display:flex;align-items:center;justify-content:center;position:relative">
                        <!-- Simulate PDF/Doc Preview -->
                        <div style="width:80%;height:90%;background:white;box-shadow:0 4px 8px rgba(0,0,0,0.3);padding:48px;display:flex;flex-direction:column;gap:16px;overflow:hidden">
                            <div style="width:40%;height:24px;background:#E0E0E0;border-radius:4px"></div>
                            <div style="width:100%;height:1px;background:#EEE;margin:16px 0"></div>
                            ${Array(12).fill(0).map(() => `<div style="width:${Math.floor(Math.random() * 40) + 60}%;height:12px;background:#F5F5F5;border-radius:2px"></div>`).join('')}
                            <div style="flex:1"></div>
                            <div style="display:flex;justify-content:center"><div style="width:100px;height:30px;border:2px dashed #CCC;border-radius:4px;display:flex;align-items:center;justify-content:center;color:#CCC;font-size:10px">FIRMA</div></div>
                        </div>
                    </div>
                </div>

                <!-- Metadata Sidebar (Right) -->
                 <div style="overflow-y:auto;padding-right:4px">
                    ${expedienteInfo}

                    <div class="card mb-24">
                        <div class="card-header">
                            <span class="card-title">Detalles</span>
                            <button class="icon-button" title="Editar Metadatos"><span class="material-icons">edit</span></button>
                        </div>
                        <div class="card-content">
                            <div style="margin-bottom:12px">
                                <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">Clasificación</div>
                                <div class="chip" style="margin-top:4px">${doc.classification}</div>
                            </div>
                            <div style="margin-bottom:12px">
                                <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">Autor</div>
                                <div style="font-size:14px;color:var(--md-sys-color-on-surface)">${doc.author}</div>
                            </div>
                            <div style="margin-bottom:12px">
                                <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">Fecha Creación</div>
                                <div style="font-size:14px;color:var(--md-sys-color-on-surface)">${formatDate(doc.date)}</div>
                            </div>
                             <div style="margin-bottom:12px">
                                <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">Tipo de Archivo</div>
                                <div class="flex items-center gap-8">
                                    <span class="material-icons" style="font-size:16px;color:var(--md-sys-color-secondary)">${getDocumentIcon(doc.type)}</span>
                                    <span style="font-size:14px;text-transform:uppercase">${doc.type}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="card mb-24">
                        <div class="card-header">
                            <span class="card-title">Datos Específicos</span>
                        </div>
                        <div class="card-content">
                            ${customFieldsHtml}
                        </div>
                    </div>

                    <div class="card mb-24">
                        <div class="card-header">
                            <span class="card-title">Descripción</span>
                        </div>
                        <div class="card-content">
                            <p style="font-size:13px;line-height:1.5;color:var(--md-sys-color-on-surface-variant)">
                                ${doc.description || 'Sin descripción disponible.'}
                            </p>
                            ${doc.tags ? `
                                <div class="flex gap-8 flex-wrap mt-16">
                                     ${doc.tags.split(',').map(tag => `<span class="chip" style="font-size:11px;height:22px">${tag.trim()}</span>`).join('')}
                                </div>
                            ` : ''}
                        </div>
                    </div>
                 </div>
            </div>
        `;

    document.getElementById('pageContent').innerHTML = content;
},

approveWorkflow: function (id) {
    const workflow = MockData.workflows.find(w => w.id === id);
    if (!workflow) return;

    workflow.status = 'approved';

    const toast = document.getElementById('toast');
    document.getElementById('toastMessage').textContent = 'Flujo aprobado correctamente';
    toast.style.display = 'block';
    setTimeout(() => toast.style.display = 'none', 3000);

    if (AppState.currentPage === 'workflows') {
        this.renderPage();
    } else if (AppState.currentWorkflowId) {
        this.viewWorkflow(AppState.currentWorkflowId);
    }
},

rejectWorkflow: function (id) {
    const workflow = MockData.workflows.find(w => w.id === id);
    if (!workflow) return;

    workflow.status = 'rejected';

    const toast = document.getElementById('toast');
    document.getElementById('toastMessage').textContent = 'Flujo rechazado';
    toast.style.display = 'block';
    setTimeout(() => toast.style.display = 'none', 3000);

    if (AppState.currentPage === 'workflows') {
        this.renderPage();
    } else if (AppState.currentWorkflowId) {
        this.viewWorkflow(AppState.currentWorkflowId);
    }
},

viewWorkflow: function (id) {
    const workflow = MockData.workflows.find(w => w.id === id);
    if (!workflow) return;

    AppState.currentWorkflowId = id;

    const content = `
            <div class="page-header">
                <div class="flex items-center gap-16">
                    <button class="icon-button" onclick="App.navigate('workflows')">
                        <span class="material-icons">arrow_back</span>
                    </button>
                    <div>
                        <h1 class="page-title">${workflow.title}</h1>
                        <p class="page-subtitle">Solicitado por ${workflow.requester} • ${formatDate(workflow.date)}</p>
                    </div>
                </div>
                <div class="flex gap-8">
                    ${workflow.status === 'pending' ? `
                        <button class="btn btn-secondary" onclick="App.rejectWorkflow(${workflow.id})">
                            <span class="material-icons">close</span> Rechazar
                        </button>
                        <button class="btn btn-primary" onclick="App.approveWorkflow(${workflow.id})">
                            <span class="material-icons">check</span> Aprobar
                        </button>
                    ` : ''}
                </div>
            </div>

            <div class="grid" style="grid-template-columns: 1fr 350px; gap:24px">
                <div class="flex flex-column gap-24">
                    <div class="card">
                        <div class="card-header">
                            <span class="card-title">Información del Flujo</span>
                        </div>
                        <div class="card-content">
                            <div class="grid grid-2">
                                <div>
                                    <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">Tipo de Flujo</div>
                                    <div style="font-weight:500;display:flex;items-center;gap:8px">
                                        <span class="material-icons" style="font-size:18px">${getWorkflowIcon(workflow.type)}</span>
                                        ${workflow.type.charAt(0).toUpperCase() + workflow.type.slice(1)}
                                    </div>
                                </div>
                                <div>
                                    <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">Prioridad</div>
                                    <span class="chip ${workflow.priority === 'high' ? 'error' : workflow.priority === 'medium' ? 'warning' : ''}">${getPriorityLabel(workflow.priority)}</span>
                                </div>
                                <div>
                                    <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">Estado Actual</div>
                                    <span class="chip ${workflow.status}">${getWorkflowStatusLabel(workflow.status)}</span>
                                </div>
                                <div>
                                    <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">Fecha de Solicitud</div>
                                    <div>${formatDate(workflow.date)}</div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="card">
                        <div class="card-header">
                            <span class="card-title">Historial / Pasos</span>
                        </div>
                        <div class="card-content">
                            <div class="timeline" style="padding-left:16px;position:relative">
                                <div style="position:absolute;left:23px;top:8px;bottom:8px;width:2px;background:var(--md-sys-color-outline-variant)"></div>
                                
                                <div class="timeline-item" style="position:relative;margin-bottom:24px;padding-left:32px">
                                    <div style="position:absolute;left:-4px;top:0;width:10px;height:10px;border-radius:50%;background:var(--md-sys-color-primary)"></div>
                                    <div style="font-weight:500;font-size:14px">Inicio del Flujo</div>
                                    <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">${workflow.requester} • ${formatDate(workflow.date)} 09:30</div>
                                </div>

                                <div class="timeline-item" style="position:relative;margin-bottom:24px;padding-left:32px">
                                    <div style="position:absolute;left:-4px;top:0;width:10px;height:10px;border-radius:50%;background:${workflow.status !== 'pending' ? 'var(--md-sys-color-primary)' : 'var(--md-sys-color-outline)'}"></div>
                                    <div style="font-weight:500;font-size:14px">Revisión de Gerencia</div>
                                    <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">
                                        ${workflow.status === 'approved' ? 'Aprobado por María García' : workflow.status === 'rejected' ? 'Rechazado por María García' : 'Pendiente de revisión'}
                                    </div>
                                </div>

                                <div class="timeline-item" style="position:relative;padding-left:32px">
                                    <div style="position:absolute;left:-4px;top:0;width:10px;height:10px;border-radius:50%;background:var(--md-sys-color-outline)"></div>
                                    <div style="font-weight:500;font-size:14px">Finalización / Archivo</div>
                                    <div style="font-size:12px;color:var(--md-sys-color-on-surface-variant)">Pendiente completitud de pasos previos</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="flex flex-column gap-24">
                    <div class="card">
                        <div class="card-header">
                            <span class="card-title">Documento Asociado</span>
                        </div>
                        <div class="card-content">
                            <div class="list-item" style="padding:12px;background:var(--md-sys-color-surface-variant);border-radius:8px;cursor:pointer" onclick="App.viewDocument(1)">
                                <div class="document-icon pdf">
                                    <span class="material-icons">picture_as_pdf</span>
                                </div>
                                <div class="list-item-content">
                                    <div class="list-item-title" style="font-size:13px">Contrato de Servicios...</div>
                                    <div class="list-item-subtitle">v2.1.0 • 1.2 MB</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;

    document.getElementById('pageContent').innerHTML = content;
},

filterDocuments: function (filter) {
    AppState.currentDocumentFilter = filter;

    // Update active filter chip
    document.querySelectorAll('.filter-chip').forEach(chip => {
        const isMatch = chip.onclick.toString().includes(`'${filter}'`);
        chip.classList.toggle('active', isMatch);
    });

    this.renderPage();
},

saveDocument: function () {
    const title = document.getElementById('upDocTitle').value;
    const typeId = document.getElementById('upDocType').value;
    const seriesId = document.getElementById('upDocSeries').value;
    const expedienteId = document.getElementById('upDocExpediente').value;
    const classification = document.getElementById('upDocClassification').value;
    const date = document.getElementById('upDocDate').value;
    const tags = document.getElementById('upDocTags').value;
    const description = document.getElementById('upDocDesc').value;

    if (!title || !typeId) {
        alert('El título y tipo documental son obligatorios');
        return;
    }

    const typeMap = { '1': 'pdf', '2': 'xls', '3': 'pdf', '4': 'doc', '5': 'pdf', '6': 'doc', '7': 'pdf', '8': 'doc' };

    const newDoc = {
        id: MockData.documents.length + 1,
        title,
        type: typeMap[typeId] || 'pdf',
        status: 'active',
        classification,
        date,
        author: AppState.user.name,
        version: '1.0.0',
        description,
        tags,
        expedienteId: expedienteId ? parseInt(expedienteId) : null,
        seriesId: seriesId ? parseInt(seriesId) : null
    };

    MockData.documents.unshift(newDoc);

    this.closeModals();

    const toast = document.getElementById('toast');
    document.getElementById('toastMessage').textContent = 'Documento cargado correctamente';
    toast.style.display = 'block';
    setTimeout(() => toast.style.display = 'none', 3000);

    if (AppState.currentPage === 'documents') {
        this.renderPage();
    }
},



// Signature
signDocument: function () {
    alert('Documento firmado digitalmente con certificado:\n\nTitular: María García\nCUIL: 27-12345678-9\nCertificador: ENCODE S.A.\n\nSellado de tiempo aplicado.');
},

// Login
showLogin: function () {
    document.getElementById('loginPage').classList.remove('hidden');
    document.getElementById('appContainer').classList.add('hidden');
},

login: function () {
    document.getElementById('loginPage').classList.add('hidden');
    document.getElementById('appContainer').classList.remove('hidden');
    this.navigate('dashboard');
},

// Admin Tab Navigation
setAdminTab: function (tab) {
    AppState.adminActiveTab = tab;
    this.renderPage();
},

// Upload Modal Functions
setUploadSource: function (source) {
    AppState.uploadSource = source;
    // Update tabs
    document.querySelectorAll('.upload-source-tab').forEach(t => {
        t.classList.toggle('active', t.dataset.source === source);
    });
    // Show/hide content
    document.getElementById('uploadFileArea').style.display = source === 'file' ? 'block' : 'none';
    document.getElementById('uploadScannerArea').style.display = source === 'scanner' ? 'block' : 'none';
},

onDocTypeChange: function (selectElement) {
    const typeId = parseInt(selectElement.value);
    const container = document.getElementById('dynamicFieldsContainer');

    if (!typeId || !container) {
        if (container) container.innerHTML = '';
        return;
    }

    const docType = MockData.documentTypes.find(dt => dt.id === typeId);
    if (docType) {
        container.innerHTML = this.renderDynamicFields(docType);
    } else {
        container.innerHTML = '';
    }
},

renderDynamicFields: function (docType) {
    if (!docType.fields || docType.fields.length === 0) {
        return '';
    }

    let html = '<div class="dynamic-fields-section"><div class="dynamic-fields-title"><span class="material-icons">input</span> Campos del Tipo Documental: ' + docType.name + '</div><div class="dynamic-fields-grid">';

    docType.fields.forEach(field => {
        const required = field.required ? ' *' : '';
        html += `<div class="form-group" style="margin:0">`;
        html += `<label class="form-label">${field.label}${required}</label>`;

        switch (field.type) {
            case 'select':
                html += `<select class="form-input form-select" ${field.required ? 'required' : ''}>`;
                html += `<option value="">Seleccione...</option>`;
                field.options.forEach(opt => {
                    html += `<option value="${opt}">${opt}</option>`;
                });
                html += `</select>`;
                break;
            case 'textarea':
                html += `<textarea class="form-input form-textarea" rows="3" placeholder="Ingrese ${field.label.toLowerCase()}" ${field.required ? 'required' : ''}></textarea>`;
                break;
            case 'date':
                html += `<input type="date" class="form-input" ${field.required ? 'required' : ''}>`;
                break;
            case 'number':
                html += `<input type="number" class="form-input" placeholder="Ingrese ${field.label.toLowerCase()}" ${field.required ? 'required' : ''}>`;
                break;
            default:
                html += `<input type="text" class="form-input" placeholder="Ingrese ${field.label.toLowerCase()}" ${field.required ? 'required' : ''}>`;
        }

        html += `</div>`;
    });

    html += '</div></div>';
    return html;
},

simulateScan: function () {
    const preview = document.getElementById('scanPreview');
    const scanBtn = document.getElementById('scanBtn');

    if (preview && scanBtn) {
        scanBtn.disabled = true;
        scanBtn.innerHTML = '<span class="material-icons">hourglass_empty</span> Escaneando...';
        preview.innerHTML = '<div class="scan-progress"><span class="material-icons rotating">sync</span><p>Escaneando documento...</p></div>';

        setTimeout(() => {
            preview.innerHTML = '<div class="scan-complete"><span class="material-icons">check_circle</span><p>Documento escaneado exitosamente</p><p style="font-size:12px;margin-top:8px">documento_escaneado.pdf (1.2 MB)</p></div>';
            scanBtn.disabled = false;
            scanBtn.innerHTML = '<span class="material-icons">refresh</span> Escanear de Nuevo';
        }, 2000);
    }
},

// Retention Policy & Workflow
openPolicyModal: function (id) {
    const modal = document.getElementById('policyModal');
    const title = document.getElementById('policyModalTitle');
    const idField = document.getElementById('policyId');

    // Reset form
    document.getElementById('policyName').value = '';
    document.getElementById('policyDesc').value = '';
    document.getElementById('policyYears').value = '';
    document.getElementById('policyAction').value = 'archive';

    if (id) {
        const policy = MockData.retentionPolicies.find(p => p.id === id);
        if (policy) {
            title.textContent = 'Editar Política';
            idField.value = policy.id;
            document.getElementById('policyName').value = policy.name;
            document.getElementById('policyDesc').value = policy.description;
            document.getElementById('policyYears').value = policy.years;
            document.getElementById('policyAction').value = policy.action;
        }
    } else {
        title.textContent = 'Nueva Política';
        idField.value = '';
    }

    modal.classList.add('active');
},

savePolicy: function () {
    const modal = document.getElementById('policyModal');
    modal.classList.remove('active');

    const toast = document.getElementById('toast');
    const msg = document.getElementById('toastMessage');
    const id = document.getElementById('policyId').value;

    msg.textContent = id ? 'Política actualizada correctamente' : 'Nueva política creada';
    toast.style.display = 'block';
    setTimeout(() => toast.style.display = 'none', 3000);

    // In a real app, update MockData
    this.renderPage();
},

openWorkflowEditor: function (id) {
    const modal = document.getElementById('workflowModal');
    const subtitle = document.getElementById('workflowEditorSubtitle');
    const idField = document.getElementById('workflowPolicyId');
    const policy = MockData.retentionPolicies.find(p => p.id === id);

    if (!policy) return;

    subtitle.textContent = `Política: ${policy.name}`;
    idField.value = policy.id;

    this.renderWorkflowSteps(policy.workflow || []);

    modal.classList.add('active');
},

renderWorkflowSteps: function (steps) {
    const container = document.getElementById('workflowStepsList');
    if (!container) return;

    if (!steps || steps.length === 0) {
        container.innerHTML = '<div style="padding:24px;text-align:center;color:var(--md-sys-color-on-surface-variant)">No hay pasos definidos. Agregue uno para comenzar.</div>';
        return;
    }

    container.innerHTML = steps.map((step, index) => `
            <div class="workflow-editor-item" data-index="${index}">
                <div class="workflow-editor-handle"><span class="material-icons">drag_indicator</span></div>
                <div class="workflow-editor-idx">${index + 1}</div>
                <div style="flex:1;display:grid;grid-template-columns:2fr 1.5fr 1fr 1fr;gap:12px;align-items:center">
                    <input type="text" class="form-input form-input-sm" value="${step.name}" placeholder="Nombre del paso">
                    <select class="form-input form-select-sm">
                        <option value="Usuario" ${step.role === 'Usuario' ? 'selected' : ''}>Usuario</option>
                        <option value="Gestor Documental" ${step.role === 'Gestor Documental' ? 'selected' : ''}>Gestor Documental</option>
                        <option value="Gerente" ${step.role === 'Gerente' ? 'selected' : ''}>Gerente</option>
                        <option value="Sistema" ${step.role === 'Sistema' ? 'selected' : ''}>Sistema</option>
                        <option value="Comité" ${step.role === 'Comité' ? 'selected' : ''}>Comité</option>
                        <option value="Contador" ${step.role === 'Contador' ? 'selected' : ''}>Contador</option>
                        <option value="RRHH" ${step.role === 'RRHH' ? 'selected' : ''}>RRHH</option>
                    </select>
                     <select class="form-input form-select-sm">
                        <option value="review" ${step.action === 'review' ? 'selected' : ''}>Revisar</option>
                        <option value="approve" ${step.action === 'approve' ? 'selected' : ''}>Aprobar</option>
                        <option value="sign" ${step.action === 'sign' ? 'selected' : ''}>Firmar</option>
                        <option value="archive" ${step.action === 'archive' ? 'selected' : ''}>Archivar</option>
                        <option value="create" ${step.action === 'create' ? 'selected' : ''}>Crear</option>
                        <option value="delete" ${step.action === 'delete' ? 'selected' : ''}>Destruir</option>
                    </select>
                    <input type="text" class="form-input form-input-sm" value="${step.sla}" placeholder="SLA">
                </div>
                <button class="icon-button delete-step-btn" onclick="App.removeWorkflowStep(${index})" title="Eliminar paso">
                    <span class="material-icons" style="color:var(--md-sys-color-error)">delete</span>
                </button>
            </div>
        `).join('');
},

addWorkflowStep: function () {
    const currentSteps = this.getWorkflowStepsFromDOM();
    currentSteps.push({ order: currentSteps.length + 1, name: 'Nuevo Paso', role: 'Gestor Documental', action: 'review', sla: '1 día' });
    this.renderWorkflowSteps(currentSteps);
},

removeWorkflowStep: function (index) {
    const currentSteps = this.getWorkflowStepsFromDOM();
    currentSteps.splice(index, 1);
    currentSteps.forEach((s, i) => s.order = i + 1);
    this.renderWorkflowSteps(currentSteps);
},

getWorkflowStepsFromDOM: function () {
    const items = document.querySelectorAll('.workflow-editor-item');
    return Array.from(items).map((item, index) => {
        const inputs = item.querySelectorAll('input, select');
        return {
            order: index + 1,
            name: inputs[0].value,
            role: inputs[1].value,
            action: inputs[2].value,
            sla: inputs[3].value
        };
    });
},

saveWorkflow: function () {
    const id = parseInt(document.getElementById('workflowPolicyId').value);
    const policy = MockData.retentionPolicies.find(p => p.id === id);

    if (policy) {
        policy.workflow = this.getWorkflowStepsFromDOM();

        document.getElementById('workflowModal').classList.remove('active');
        const toast = document.getElementById('toast');
        const msg = document.getElementById('toastMessage');
        msg.textContent = 'Flujo de trabajo actualizado';
        toast.style.display = 'block';
        setTimeout(() => toast.style.display = 'none', 3000);

        this.renderPage();
    }
},

// Document Types
// Document Types
openDocTypeModal: function (id) {
    const modal = document.getElementById('docTypeModal');
    const title = document.getElementById('docTypeModalTitle');
    const idField = document.getElementById('docTypeId');

    // Reset form
    document.getElementById('docTypeName').value = '';
    document.getElementById('docTypeCode').value = '';
    document.getElementById('docTypeDesc').value = '';

    // Default fields for new type
    let fields = [];

    if (id) {
        const dt = MockData.documentTypes.find(t => t.id === id);
        if (dt) {
            title.textContent = 'Editar Tipo Documental';
            idField.value = dt.id;
            document.getElementById('docTypeName').value = dt.name;
            document.getElementById('docTypeCode').value = dt.code;
            document.getElementById('docTypeDesc').value = dt.description || '';
            fields = dt.fields || [];
        }
    } else {
        title.textContent = 'Nuevo Tipo Documental';
        idField.value = '';
    }

    this.renderDocTypeFields(fields);
    modal.classList.add('active');
},

renderDocTypeFields: function (fields) {
    const container = document.getElementById('docTypeFieldsList');
    if (!container) return;

    if (!fields || fields.length === 0) {
        container.innerHTML = '<div style="padding:16px;text-align:center;color:var(--md-sys-color-on-surface-variant)">Sin campos adicionales</div>';
        return;
    }

    container.innerHTML = fields.map((field, index) => `
            <div class="workflow-editor-item doc-type-field-item">
                <div class="workflow-editor-handle"><span class="material-icons">drag_indicator</span></div>
                <div style="flex:1;display:grid;grid-template-columns:2fr 1.5fr 1fr 0.5fr;gap:12px;align-items:center">
                    <input type="text" class="form-input form-input-sm field-label" value="${field.label}" placeholder="Etiqueta del Campo">
                    <select class="form-input form-select-sm field-type" onchange="App.onFieldTypeChange(this, ${index})">
                        <option value="text" ${field.type === 'text' ? 'selected' : ''}>Texto</option>
                        <option value="number" ${field.type === 'number' ? 'selected' : ''}>Número</option>
                        <option value="date" ${field.type === 'date' ? 'selected' : ''}>Fecha</option>
                        <option value="list" ${field.type === 'list' ? 'selected' : ''}>Lista</option>
                    </select>
                    <div class="checkbox-wrapper" style="margin:0">
                        <input type="checkbox" class="field-required" ${field.required ? 'checked' : ''} style="margin-right:8px">
                        <span style="font-size:13px">Ob.</span>
                    </div>
                     <div style="display:flex;justify-content:center">
                        <input type="hidden" class="field-options" value='${field.options ? JSON.stringify(field.options) : '[]'}'>
                        <button class="icon-button field-config-btn" onclick="App.openListOptionsModal(${index})" style="display:${field.type === 'list' ? 'flex' : 'none'}" title="Configurar opciones">
                            <span class="material-icons">settings</span>
                        </button>
                    </div>
                </div>
                <button class="icon-button delete-step-btn" onclick="App.removeDocTypeField(${index})" title="Eliminar campo">
                    <span class="material-icons" style="color:var(--md-sys-color-error)">delete</span>
                </button>
            </div>
        `).join('');
},

onFieldTypeChange: function (select, index) {
    const row = select.closest('.doc-type-field-item');
    const btn = row.querySelector('.field-config-btn');
    btn.style.display = select.value === 'list' ? 'flex' : 'none';
},

openListOptionsModal: function (index) {
    const row = document.querySelectorAll('.doc-type-field-item')[index];
    const input = row.querySelector('.field-options');
    let options = [];
    try {
        options = JSON.parse(input.value || '[]');
    } catch (e) { options = []; }

    document.getElementById('listOptionsFieldIndex').value = index;
    document.getElementById('listOptionsInput').value = options.join('\n');
    document.getElementById('listOptionsModal').classList.add('active');
},

closeListOptionsModal: function () {
    document.getElementById('listOptionsModal').classList.remove('active');
},

saveListOptions: function () {
    const index = parseInt(document.getElementById('listOptionsFieldIndex').value);
    const text = document.getElementById('listOptionsInput').value;
    const options = text.split('\n').map(s => s.trim()).filter(s => s.length > 0);

    const row = document.querySelectorAll('.doc-type-field-item')[index];
    row.querySelector('.field-options').value = JSON.stringify(options);

    this.closeListOptionsModal();
},

addDocTypeField: function () {
    const currentFields = this.getDocTypeFieldsFromDOM();
    currentFields.push({ label: '', type: 'text', required: false, options: [] });
    this.renderDocTypeFields(currentFields);
},

removeDocTypeField: function (index) {
    const currentFields = this.getDocTypeFieldsFromDOM();
    currentFields.splice(index, 1);
    this.renderDocTypeFields(currentFields);
},

getDocTypeFieldsFromDOM: function () {
    const items = document.querySelectorAll('.doc-type-field-item');
    return Array.from(items).map(item => {
        const optsVal = item.querySelector('.field-options').value;
        return {
            label: item.querySelector('.field-label').value,
            type: item.querySelector('.field-type').value,
            required: item.querySelector('.field-required').checked,
            options: optsVal ? JSON.parse(optsVal) : []
        };
    });
},

saveDocType: function () {
    const modal = document.getElementById('docTypeModal');
    const idStr = document.getElementById('docTypeId').value;
    const id = idStr ? parseInt(idStr) : null;

    const name = document.getElementById('docTypeName').value;
    const fields = this.getDocTypeFieldsFromDOM();

    if (id) {
        const dt = MockData.documentTypes.find(t => t.id === id);
        if (dt) {
            dt.name = name;
            dt.code = document.getElementById('docTypeCode').value;
            dt.description = document.getElementById('docTypeDesc').value;
            dt.fields = fields;
        }
    } else {
        MockData.documentTypes.push({
            id: MockData.documentTypes.length + 100,
            name: name,
            code: document.getElementById('docTypeCode').value,
            description: document.getElementById('docTypeDesc').value,
            fields: fields
        });
    }

    modal.classList.remove('active');
    const toast = document.getElementById('toast');
    document.getElementById('toastMessage').textContent = id ? 'Tipo documental actualizado' : 'Nuevo tipo creado';
    toast.style.display = 'block';
    setTimeout(() => toast.style.display = 'none', 3000);

    this.renderPage();
},

// Document Series
openSeriesModal: function (id = null, parentId = null) {
    const modal = document.getElementById('seriesModal');
    const title = document.getElementById('seriesModalTitle');
    const parentSelect = document.getElementById('seriesParentId');
    const idField = document.getElementById('seriesId');

    // Reset Validation
    document.querySelectorAll('.error-message').forEach(el => {
        el.textContent = '';
        el.classList.remove('active');
    });
    document.querySelectorAll('.form-input.error').forEach(el => el.classList.remove('error'));

    // Populate parent select
    parentSelect.innerHTML = '<option value="">(Ninguna - Serie Raíz)</option>' +
        MockData.documentSeries
            .filter(s => s.id !== id) // Prevent self-parenting loop in UI (simple check)
            .map(s => `<option value="${s.id}">${s.code} - ${s.name}</option>`)
            .join('');

    // Reset fields
    idField.value = '';
    document.getElementById('seriesName').value = '';
    document.getElementById('seriesCode').value = '';
    document.getElementById('seriesDesc').value = '';
    document.getElementById('seriesRetention').value = 5;
    parentSelect.value = '';

    if (id) {
        // Edit existing
        const s = MockData.documentSeries.find(x => x.id === id);
        if (s) {
            title.textContent = 'Editar Serie Documental';
            idField.value = s.id;
            document.getElementById('seriesName').value = s.name;
            document.getElementById('seriesCode').value = s.code;
            document.getElementById('seriesDesc').value = s.description;
            document.getElementById('seriesRetention').value = s.retentionYears;
            parentSelect.value = s.parentId || '';
        }
    } else {
        // New
        title.textContent = 'Nueva Serie Documental';
        if (parentId) {
            parentSelect.value = parentId;
            // Inherit defaults from parent
            const parent = MockData.documentSeries.find(s => s.id === parentId);
            if (parent) {
                document.getElementById('seriesCode').value = parent.code + '-';
                document.getElementById('seriesRetention').value = parent.retentionYears;
            }
        }
    }

    modal.classList.add('active');
},

// Expedientes Logic
openNewExpedienteModal: function () {
    const modal = document.getElementById('expedienteModal');
    const title = document.getElementById('expedienteModalTitle');
    const idField = document.getElementById('expedienteId');

    // Reset form
    idField.value = '';
    document.getElementById('expTitle').value = '';
    document.getElementById('expNumber').value = '';
    document.getElementById('expDescription').value = '';
    document.getElementById('expTags').value = '';
    document.getElementById('expStatus').value = 'active';

    // Populate Selects
    const seriesSelect = document.getElementById('expSeries');
    seriesSelect.innerHTML = '<option value="">Seleccione...</option>' +
        MockData.documentSeries.map(s => `<option value="${s.id}">${s.code} - ${s.name}</option>`).join('');

    const respSelect = document.getElementById('expResponsible');
    respSelect.innerHTML = MockData.users.map(u => `<option value="${u.id}">${u.name}</option>`).join('');

    title.textContent = 'Nuevo Expediente';
    modal.classList.add('active');
},

saveExpediente: function () {
    const modal = document.getElementById('expedienteModal');
    const idStr = document.getElementById('expedienteId').value;
    const id = idStr ? parseInt(idStr) : null;

    const title = document.getElementById('expTitle').value;
    const number = document.getElementById('expNumber').value || `EXP-${new Date().getFullYear()}-${Math.floor(Math.random() * 1000).toString().padStart(4, '0')}`;
    const seriesId = document.getElementById('expSeries').value;
    const responsibleId = document.getElementById('expResponsible').value;
    const responsibleName = document.getElementById('expResponsible').options[document.getElementById('expResponsible').selectedIndex].text;

    if (!title) {
        alert('El título es obligatorio');
        return;
    }

    const expData = {
        title,
        number,
        seriesId,
        responsible: responsibleName,
        status: document.getElementById('expStatus').value,
        description: document.getElementById('expDescription').value,
        tags: document.getElementById('expTags').value,
        priority: document.getElementById('expPriority').value,
        openDate: id ? undefined : new Date().toISOString().split('T')[0], // Keep original date if editing
        documents: id ? undefined : 0
    };

    if (id) {
        const exp = MockData.expedientes.find(e => e.id === id);
        if (exp) Object.assign(exp, expData);
    } else {
        MockData.expedientes.push({
            id: MockData.expedientes.length + 100,
            ...expData,
            documents: 0
        });
    }

    modal.classList.remove('active');
    const toast = document.getElementById('toast');
    document.getElementById('toastMessage').textContent = id ? 'Expediente actualizado' : 'Expediente creado';
    toast.style.display = 'block';
    setTimeout(() => toast.style.display = 'none', 3000);

    if (AppState.currentPage === 'expedientes') {
        this.renderPage();
    } else if (AppState.currentExpedienteId) {
        // Refresh detail view if we are there
        this.viewExpediente(AppState.currentExpedienteId);
    }
},

viewExpediente: function (id) {
    const exp = MockData.expedientes.find(e => e.id === id);
    if (!exp) return;

    AppState.currentExpedienteId = id; // Store current view
    const docs = MockData.documents.filter(d => d.expedienteId === id); // We need to simulate this relationship

    const content = `
            <div class="page-header">
                <div class="flex items-center gap-16">
                    <button class="icon-button" onclick="App.navigate('expedientes')">
                        <span class="material-icons">arrow_back</span>
                    </button>
                    <div>
                        <h1 class="page-title">${exp.number}</h1>
                        <p class="page-subtitle">${exp.title}</p>
                    </div>
                </div>
                <div class="flex gap-8">
                     <button class="btn btn-secondary" onclick="App.editExpediente(${exp.id})">
                        <span class="material-icons">edit</span> Editar
                    </button>
                    <button class="btn btn-primary" onclick="App.openDocSelectionModal(${exp.id})">
                        <span class="material-icons">note_add</span> Agregar Documento
                    </button>
                </div>
            </div>
            
            <div class="stats-grid mb-24">
                <div class="stat-card">
                    <div class="stat-content">
                        <div class="stat-label">Estado</div>
                        <div class="chip ${getStatusClass(exp.status)}">${getStatusLabel(exp.status)}</div>
                    </div>
                </div>
                 <div class="stat-card">
                    <div class="stat-content">
                        <div class="stat-label">Responsable</div>
                        <div class="stat-value" style="font-size:16px">${exp.responsible}</div>
                    </div>
                </div>
                 <div class="stat-card">
                    <div class="stat-content">
                        <div class="stat-label">Fecha Apertura</div>
                         <div class="stat-value" style="font-size:16px">${formatDate(exp.openDate)}</div>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-content">
                        <div class="stat-label">Documentos</div>
                        <div class="stat-value">${docs.length}</div>
                    </div>
                </div>
            </div>

            <div class="card mb-24">
                <div class="card-content">
                    <h3 style="font-size:14px;font-weight:500;margin-bottom:8px;color:var(--md-sys-color-on-surface)">Descripción</h3>
                    <p style="color:var(--md-sys-color-on-surface-variant);margin-bottom:16px;line-height:1.5">${exp.description || 'Sin descripción disponible.'}</p>
                    ${exp.tags ? `
                        <div class="flex gap-8 items-center">
                            <span class="material-icons" style="font-size:18px;color:var(--md-sys-color-outline)">label</span>
                            <div class="flex gap-8 flex-wrap">
                                ${exp.tags.split(',').map(tag => `<span class="chip" style="height:24px;font-size:12px">${tag.trim()}</span>`).join('')}
                            </div>
                        </div>
                    ` : ''}
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <span class="card-title">Documentos del Expediente</span>
                </div>
                <div class="card-content">
                     ${docs.length > 0 ? `
                        <div class="recent-documents">
                            ${docs.map(doc => `
                                <div class="list-item" onclick="App.viewDocument(${doc.id})">
                                    <div class="document-icon ${doc.type}">
                                        <span class="material-icons">${getDocumentIcon(doc.type)}</span>
                                    </div>
                                    <div class="list-item-content">
                                        <div class="list-item-title">${doc.title}</div>
                                        <div class="list-item-subtitle">${doc.author} • ${formatDate(doc.date)}</div>
                                    </div>
                                    <button class="icon-button" onclick="event.stopPropagation(); App.removeDocFromExpediente(${doc.id})">
                                        <span class="material-icons" style="color:var(--md-sys-color-error)">remove_circle_outline</span>
                                    </button>
                                </div>
                            `).join('')}
                        </div>
                     ` : '<div style="padding:32px;text-align:center;color:var(--md-sys-color-on-surface-variant)">No hay documentos en este expediente</div>'}
                </div>
            </div>
        `;

    document.getElementById('pageContent').innerHTML = content;
},

editExpediente: function (id) {
    const exp = MockData.expedientes.find(e => e.id === id);
    if (!exp) return;

    this.openNewExpedienteModal();
    const modal = document.getElementById('expedienteModal');
    const title = document.getElementById('expedienteModalTitle');

    title.textContent = 'Editar Expediente';
    document.getElementById('expedienteId').value = exp.id;
    document.getElementById('expTitle').value = exp.title;
    document.getElementById('expNumber').value = exp.number;
    document.getElementById('expStatus').value = exp.status;
    document.getElementById('expDescription').value = exp.description || '';
    document.getElementById('expTags').value = exp.tags || '';
    document.getElementById('expPriority').value = exp.priority || 'Normal';

    if (exp.seriesId) document.getElementById('expSeries').value = exp.seriesId;

    const responsibleUser = MockData.users.find(u => u.name === exp.responsible);
    if (responsibleUser) {
        document.getElementById('expResponsible').value = responsibleUser.id;
    }
},

openDocSelectionModal: function (expId) {
    AppState.currentExpedienteId = expId;
    const modal = document.getElementById('docSelectionModal');
    const list = document.getElementById('docSelectionList');

    // Show only docs NOT already in this expediente
    const currentDocs = MockData.documents.filter(d => d.expedienteId === expId).map(d => d.id);
    const availableDocs = MockData.documents.filter(d => !currentDocs.includes(d.id));

    list.innerHTML = availableDocs.map(doc => `
            <div class="list-item">
                <div class="checkbox-wrapper">
                     <input type="checkbox" class="doc-select-checkbox" value="${doc.id}">
                </div>
                 <div class="list-item-content">
                    <div class="list-item-title">${doc.title}</div>
                    <div class="list-item-subtitle">${doc.author}</div>
                 </div>
            </div>
        `).join('');

    modal.classList.add('active');
},

addSelectedDocsToExpediente: function () {
    const checkboxes = document.querySelectorAll('.doc-select-checkbox:checked');
    const selectedIds = Array.from(checkboxes).map(cb => parseInt(cb.value));

    selectedIds.forEach(id => {
        const doc = MockData.documents.find(d => d.id === id);
        if (doc) doc.expedienteId = AppState.currentExpedienteId;
    });

    // Update document count in expediente
    const exp = MockData.expedientes.find(e => e.id === AppState.currentExpedienteId);
    if (exp) {
        const count = MockData.documents.filter(d => d.expedienteId === AppState.currentExpedienteId).length;
        exp.documents = count;
    }

    this.closeModals();
    this.viewExpediente(AppState.currentExpedienteId); // Refresh view
},

removeDocFromExpediente: function (docId) {
    if (!confirm('¿Quitar documento del expediente?')) return;

    const doc = MockData.documents.find(d => d.id === docId);
    if (doc) {
        delete doc.expedienteId;
        // Update document count
        const exp = MockData.expedientes.find(e => e.id === AppState.currentExpedienteId);
        if (exp) {
            const count = MockData.documents.filter(d => d.expedienteId === AppState.currentExpedienteId).length;
            exp.documents = count;
        }

        this.viewExpediente(AppState.currentExpedienteId);
    }
},

filterStatsDocs: function (query) {
    // Simple search in the modal
    const list = document.getElementById('docSelectionList');
    const items = list.getElementsByClassName('list-item');
    query = query.toLowerCase();

    Array.from(items).forEach(item => {
        const text = item.textContent.toLowerCase();
        item.style.display = text.includes(query) ? 'flex' : 'none';
    });
}
};

// Initialize App on DOM Ready
document.addEventListener('DOMContentLoaded', () => {
    App.init();
});
