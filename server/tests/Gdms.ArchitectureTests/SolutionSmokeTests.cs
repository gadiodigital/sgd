using Gdms.Application.Documents;
using Gdms.Application.Evidence;
using Gdms.Application.Identity;
using Gdms.Application.Records;
using Gdms.Application.Reports;
using Gdms.Application.Signatures;
using Gdms.Application.Audit;
using Gdms.Application.Cases;
using Gdms.Domain.Cases;
using Gdms.Domain.Documents;
using Gdms.Domain.Identity;
using Gdms.Domain.Records;
using Gdms.Domain.Signatures;
using Xunit;

namespace Gdms.ArchitectureTests;

/// <summary>
/// Provides a small smoke suite to validate the solution baseline.
/// </summary>
public sealed class SolutionSmokeTests
{
    /// <summary>
    /// Ensures that the core document aggregate can be instantiated.
    /// </summary>
    [Fact]
    public void DocumentAggregate_Should_Start_Without_Versions()
    {
        var document = Document.Create(Guid.NewGuid(), "CONTRACT", "Contrato Marco", DateTimeOffset.UtcNow);

        Assert.Equal("CONTRACT", document.DocumentTypeCode);
        Assert.Empty(document.Versions);
    }

    /// <summary>
    /// Ensures that the application service type is available for dependency injection.
    /// </summary>
    [Fact]
    public void DocumentService_Type_Should_Be_Discoverable()
    {
        Assert.Equal("DocumentService", typeof(DocumentService).Name);
    }

    /// <summary>
    /// Ensures that the document metadata service type is available for dependency injection.
    /// </summary>
    [Fact]
    public void DocumentMetadataService_Type_Should_Be_Discoverable()
    {
        Assert.Equal("DocumentMetadataService", typeof(DocumentMetadataService).Name);
    }

    /// <summary>
    /// Ensures that the audit read service type is available for dependency injection.
    /// </summary>
    [Fact]
    public void AuditEventService_Type_Should_Be_Discoverable()
    {
        Assert.Equal("AuditEventService", typeof(AuditEventService).Name);
    }

    /// <summary>
    /// Ensures that the identity aggregate normalizes emails and keeps role assignments unique.
    /// </summary>
    [Fact]
    public void UserAggregate_Should_Normalize_Email_And_Assign_Roles_Idempotently()
    {
        var role = new Role(Guid.NewGuid(), "TENANT_ADMIN", "Tenant Administrator", "Administrador funcional.");
        var user = User.Create(Guid.NewGuid(), "  Admin@Empresa.com  ", "Admin Empresa", UserStatus.Pending, DateTimeOffset.UtcNow);

        user.AssignRole(role);
        user.AssignRole(role);

        Assert.Equal("admin@empresa.com", user.Email);
        Assert.Single(user.Roles);
    }

    /// <summary>
    /// Ensures that the user application service type is available for dependency injection.
    /// </summary>
    [Fact]
    public void UserService_Type_Should_Be_Discoverable()
    {
        Assert.Equal("UserService", typeof(UserService).Name);
    }

    /// <summary>
    /// Ensures that the authentication application service type is available for dependency injection.
    /// </summary>
    [Fact]
    public void AuthService_Type_Should_Be_Discoverable()
    {
        Assert.Equal("AuthService", typeof(AuthService).Name);
    }

    /// <summary>
    /// Ensures that retention policies normalize their code and preserve disposition metadata.
    /// </summary>
    [Fact]
    public void RetentionPolicy_Should_Normalize_Code()
    {
        var policy = new RetentionPolicy(
            Guid.NewGuid(),
            null,
            "contract_10y",
            "Contrato 10 años",
            3650,
            RetentionDispositionAction.Archive,
            true);

        Assert.Equal("CONTRACT_10Y", policy.Code);
        Assert.Equal(RetentionDispositionAction.Archive, policy.DispositionAction);
    }

    /// <summary>
    /// Ensures that the records management service type is available for dependency injection.
    /// </summary>
    [Fact]
    public void RecordsService_Type_Should_Be_Discoverable()
    {
        Assert.Equal("RecordsService", typeof(RecordsService).Name);
    }

    /// <summary>
    /// Ensures that signature requests normalize email and provider metadata.
    /// </summary>
    [Fact]
    public void SignatureEnvelope_Should_Normalize_Key_Fields()
    {
        var envelope = SignatureEnvelope.Create(
            Guid.NewGuid(),
            Guid.NewGuid(),
            "  Estudio Perez  ",
            "  Firma@Cliente.com  ",
            "digital",
            null,
            null,
            Guid.NewGuid(),
            DateTimeOffset.UtcNow,
            null);

        Assert.Equal("firma@cliente.com", envelope.SignerEmail);
        Assert.Equal("DIGITAL", envelope.SignatureLevel);
        Assert.Equal("INTERNAL", envelope.ProviderCode);
    }

    /// <summary>
    /// Ensures that the signature application service type is available for dependency injection.
    /// </summary>
    [Fact]
    public void SignatureService_Type_Should_Be_Discoverable()
    {
        Assert.Equal("SignatureService", typeof(SignatureService).Name);
    }

    /// <summary>
    /// Ensures that the evidence package application service type is available for dependency injection.
    /// </summary>
    [Fact]
    public void DocumentEvidencePackageService_Type_Should_Be_Discoverable()
    {
        Assert.Equal("DocumentEvidencePackageService", typeof(DocumentEvidencePackageService).Name);
    }

    /// <summary>
    /// Ensures that the reports application service type is available for dependency injection.
    /// </summary>
    [Fact]
    public void ReportsService_Type_Should_Be_Discoverable()
    {
        Assert.Equal("ReportsService", typeof(ReportsService).Name);
    }

    /// <summary>
    /// Ensures that case files normalize code and category.
    /// </summary>
    [Fact]
    public void CaseFile_Should_Normalize_Code_And_Category()
    {
        var caseFile = CaseFile.Create(
            Guid.NewGuid(),
            " exp-2026_001 ",
            "Sucesión Perez",
            "juridico",
            Guid.NewGuid(),
            DateTimeOffset.UtcNow);

        Assert.Equal("EXP-2026_001", caseFile.Code);
        Assert.Equal("JURIDICO", caseFile.Category);
    }

    /// <summary>
    /// Ensures that the case file service type is available for dependency injection.
    /// </summary>
    [Fact]
    public void CaseFileService_Type_Should_Be_Discoverable()
    {
        Assert.Equal("CaseFileService", typeof(CaseFileService).Name);
    }
}
