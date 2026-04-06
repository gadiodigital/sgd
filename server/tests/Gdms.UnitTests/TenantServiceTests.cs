using Gdms.UnitTests.TestDoubles;

namespace Gdms.UnitTests;

public sealed class TenantServiceTests
{
    [Fact]
    public async Task CreateAsync_Should_Normalize_Tenant_And_Write_Audit_Event()
    {
        var tenantRepository = new TenantRepositoryStub();
        var auditEventRepository = new AuditEventRepositoryStub();
        var actorUserId = Guid.NewGuid();
        var service = new TenantService(tenantRepository, auditEventRepository);

        var tenant = await service.CreateAsync(
            " acme_legal ",
            " Acme Legal ",
            " juridico ",
            " ar ",
            actorUserId,
            CancellationToken.None);

        Assert.Equal("ACME_LEGAL", tenant.Code);
        Assert.Equal("Acme Legal", tenant.Name);
        Assert.Equal("juridico", tenant.Sector);
        Assert.Equal("AR", tenant.PrimaryCountryCode);
        Assert.Equal("TENANT_CREATED", auditEventRepository.Writes.Single().EventType);
        Assert.Equal(actorUserId, auditEventRepository.Writes.Single().ActorUserId);
        Assert.Same(tenant, tenantRepository.AddedTenant);
    }

    [Fact]
    public async Task ListAsync_Should_Return_Repository_Result()
    {
        var expected = new[]
        {
            new Tenant(Guid.NewGuid(), "ACME", "Acme", "LEGAL", "AR", DateTimeOffset.UtcNow),
            new Tenant(Guid.NewGuid(), "BETA", "Beta", "REAL_ESTATE", "UY", DateTimeOffset.UtcNow)
        };
        var service = new TenantService(
            new TenantRepositoryStub { ListResult = expected },
            new AuditEventRepositoryStub());

        var tenants = await service.ListAsync(CancellationToken.None);

        Assert.Equal(2, tenants.Count);
        Assert.Equal(expected, tenants);
    }
}
