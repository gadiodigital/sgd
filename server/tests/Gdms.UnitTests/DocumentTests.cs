namespace Gdms.UnitTests;

public sealed class DocumentTests
{
    [Fact]
    public void AddVersion_Should_Assign_Sequential_Version_Number_And_Normalize_Hash()
    {
        var document = Document.Create(Guid.NewGuid(), "contract", "Contrato marco", DateTimeOffset.UtcNow);

        var firstVersion = document.AddVersion(
            "docs/contracts/001.pdf",
            "application/pdf",
            "AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899",
            128,
            Guid.NewGuid(),
            DateTimeOffset.UtcNow);
        var secondVersion = document.AddVersion(
            "docs/contracts/002.pdf",
            "application/pdf",
            "00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF",
            256,
            Guid.NewGuid(),
            DateTimeOffset.UtcNow);

        Assert.Equal(1, firstVersion.VersionNumber);
        Assert.Equal(2, secondVersion.VersionNumber);
        Assert.Equal(
            "aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899",
            firstVersion.FileHashSha256);
        Assert.Equal(2, document.Versions.Count);
    }

    [Fact]
    public void Rehydrate_Should_Order_Versions_By_VersionNumber()
    {
        var tenantId = Guid.NewGuid();
        var version2 = new DocumentVersion(
            Guid.NewGuid(),
            2,
            "docs/contracts/002.pdf",
            "application/pdf",
            "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff",
            256,
            Guid.NewGuid(),
            DateTimeOffset.UtcNow);
        var version1 = new DocumentVersion(
            Guid.NewGuid(),
            1,
            "docs/contracts/001.pdf",
            "application/pdf",
            "aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899",
            128,
            Guid.NewGuid(),
            DateTimeOffset.UtcNow);

        var document = Document.Rehydrate(
            Guid.NewGuid(),
            tenantId,
            "CONTRACT",
            "Contrato marco",
            DocumentStatus.Active,
            DateTimeOffset.UtcNow,
            [version2, version1]);

        Assert.Equal([1, 2], document.Versions.Select(version => version.VersionNumber).ToArray());
    }
}
