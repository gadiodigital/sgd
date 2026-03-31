using System.Text.Json;
using Gdms.Application.Documents;
using Gdms.Domain.Common;
using Xunit;

namespace Gdms.ArchitectureTests;

/// <summary>
/// Verifies core metadata validation and normalization rules.
/// </summary>
public sealed class DocumentMetadataSchemaValidatorTests
{
    private readonly DocumentMetadataSchemaValidator _validator = new();

    /// <summary>
    /// Ensures that valid metadata is normalized according to the catalog schema.
    /// </summary>
    [Fact]
    public void ValidateAndNormalize_Should_Normalize_Strings_And_Dates()
    {
        using var schema = JsonDocument.Parse("""
            {
              "contractNumber": { "type": "string", "required": true, "maxLength": 50, "label": "Numero de contrato" },
              "effectiveDate": { "type": "date", "required": true, "label": "Fecha de vigencia" }
            }
            """);
        var definition = new DocumentTypeDefinition(
            Guid.NewGuid(),
            null,
            "CONTRACT",
            "Contrato",
            "CORPORATE",
            true,
            schema);

        var normalized = _validator.ValidateAndNormalize(
            """{ "contractNumber": "  CM-001  ", "effectiveDate": "2026-03-20" }""",
            definition);

        Assert.Equal("""{"contractNumber":"CM-001","effectiveDate":"2026-03-20"}""", normalized);
    }

    /// <summary>
    /// Ensures that missing required metadata raises an explicit domain error.
    /// </summary>
    [Fact]
    public void ValidateAndNormalize_Should_Reject_Missing_Required_Field()
    {
        using var schema = JsonDocument.Parse("""
            {
              "invoiceNumber": { "type": "string", "required": true, "label": "Numero de comprobante" }
            }
            """);
        var definition = new DocumentTypeDefinition(
            Guid.NewGuid(),
            null,
            "INVOICE",
            "Factura",
            "CORPORATE",
            true,
            schema);

        var exception = Assert.Throws<DomainRuleException>(
            () => _validator.ValidateAndNormalize("""{ }""", definition));

        Assert.Contains("Numero de comprobante", exception.Message);
    }
}
