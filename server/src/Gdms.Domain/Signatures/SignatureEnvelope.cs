using Gdms.Domain.Common;

namespace Gdms.Domain.Signatures;

/// <summary>
/// Represents a tenant-scoped request for an electronic or digital signature.
/// </summary>
public sealed class SignatureEnvelope
{
    private static readonly string[] AllowedSignatureLevels = ["ELECTRONIC", "DIGITAL"];

    private SignatureEnvelope(
        Guid id,
        Guid tenantId,
        Guid documentId,
        string signerDisplayName,
        string signerEmail,
        string signatureLevel,
        string providerCode,
        string? externalReference,
        SignatureEnvelopeStatus status,
        Guid? requestedByUserId,
        DateTimeOffset requestedAtUtc,
        DateTimeOffset? dueAtUtc,
        Guid? completedByUserId,
        DateTimeOffset? completedAtUtc,
        Guid? cancelledByUserId,
        DateTimeOffset? cancelledAtUtc,
        string? cancellationReason)
    {
        Id = id;
        TenantId = tenantId;
        DocumentId = documentId;
        SignerDisplayName = signerDisplayName;
        SignerEmail = signerEmail;
        SignatureLevel = signatureLevel;
        ProviderCode = providerCode;
        ExternalReference = externalReference;
        Status = status;
        RequestedByUserId = requestedByUserId;
        RequestedAtUtc = requestedAtUtc;
        DueAtUtc = dueAtUtc;
        CompletedByUserId = completedByUserId;
        CompletedAtUtc = completedAtUtc;
        CancelledByUserId = cancelledByUserId;
        CancelledAtUtc = cancelledAtUtc;
        CancellationReason = cancellationReason;
    }

    public Guid Id { get; }
    public Guid TenantId { get; }
    public Guid DocumentId { get; }
    public string SignerDisplayName { get; }
    public string SignerEmail { get; }
    public string SignatureLevel { get; }
    public string ProviderCode { get; }
    public string? ExternalReference { get; private set; }
    public SignatureEnvelopeStatus Status { get; private set; }
    public Guid? RequestedByUserId { get; }
    public DateTimeOffset RequestedAtUtc { get; }
    public DateTimeOffset? DueAtUtc { get; }
    public Guid? CompletedByUserId { get; private set; }
    public DateTimeOffset? CompletedAtUtc { get; private set; }
    public Guid? CancelledByUserId { get; private set; }
    public DateTimeOffset? CancelledAtUtc { get; private set; }
    public string? CancellationReason { get; private set; }

    /// <summary>
    /// Creates a new pending signature envelope for a document.
    /// </summary>
    public static SignatureEnvelope Create(
        Guid tenantId,
        Guid documentId,
        string signerDisplayName,
        string signerEmail,
        string signatureLevel,
        string? providerCode,
        string? externalReference,
        Guid? requestedByUserId,
        DateTimeOffset requestedAtUtc,
        DateTimeOffset? dueAtUtc)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant es obligatorio para solicitar firma.");
        }

        if (documentId == Guid.Empty)
        {
            throw new DomainRuleException("El documento es obligatorio para solicitar firma.");
        }

        return new SignatureEnvelope(
            Guid.NewGuid(),
            tenantId,
            documentId,
            NormalizeSignerDisplayName(signerDisplayName),
            NormalizeSignerEmail(signerEmail),
            NormalizeSignatureLevel(signatureLevel),
            NormalizeProviderCode(providerCode),
            NormalizeExternalReference(externalReference),
            SignatureEnvelopeStatus.Pending,
            requestedByUserId,
            requestedAtUtc,
            dueAtUtc,
            null,
            null,
            null,
            null,
            null);
    }

    /// <summary>
    /// Rehydrates an existing signature envelope from persistence.
    /// </summary>
    public static SignatureEnvelope Rehydrate(
        Guid id,
        Guid tenantId,
        Guid documentId,
        string signerDisplayName,
        string signerEmail,
        string signatureLevel,
        string providerCode,
        string? externalReference,
        SignatureEnvelopeStatus status,
        Guid? requestedByUserId,
        DateTimeOffset requestedAtUtc,
        DateTimeOffset? dueAtUtc,
        Guid? completedByUserId,
        DateTimeOffset? completedAtUtc,
        Guid? cancelledByUserId,
        DateTimeOffset? cancelledAtUtc,
        string? cancellationReason)
    {
        return new SignatureEnvelope(
            id,
            tenantId,
            documentId,
            signerDisplayName,
            signerEmail,
            signatureLevel,
            providerCode,
            externalReference,
            status,
            requestedByUserId,
            requestedAtUtc,
            dueAtUtc,
            completedByUserId,
            completedAtUtc,
            cancelledByUserId,
            cancelledAtUtc,
            NormalizeOptionalCancellationReason(cancellationReason));
    }

    /// <summary>
    /// Marks the envelope as completed with signature evidence metadata.
    /// </summary>
    public void Complete(Guid completedByUserId, DateTimeOffset completedAtUtc, string? externalReference)
    {
        if (Status == SignatureEnvelopeStatus.Signed)
        {
            throw new DomainRuleException("La solicitud de firma ya se encuentra completada.");
        }

        if (Status == SignatureEnvelopeStatus.Cancelled)
        {
            throw new DomainRuleException("No se puede completar una solicitud de firma cancelada.");
        }

        if (completedByUserId == Guid.Empty)
        {
            throw new DomainRuleException("El usuario que confirma la firma es obligatorio.");
        }

        Status = SignatureEnvelopeStatus.Signed;
        CompletedByUserId = completedByUserId;
        CompletedAtUtc = completedAtUtc;
        ExternalReference = NormalizeExternalReference(externalReference);
    }

    /// <summary>
    /// Cancels a pending signature request with a recorded reason.
    /// </summary>
    public void Cancel(Guid cancelledByUserId, DateTimeOffset cancelledAtUtc, string reason)
    {
        if (Status == SignatureEnvelopeStatus.Signed)
        {
            throw new DomainRuleException("No se puede cancelar una solicitud de firma ya completada.");
        }

        if (Status == SignatureEnvelopeStatus.Cancelled)
        {
            throw new DomainRuleException("La solicitud de firma ya se encuentra cancelada.");
        }

        if (cancelledByUserId == Guid.Empty)
        {
            throw new DomainRuleException("El usuario que cancela la firma es obligatorio.");
        }

        Status = SignatureEnvelopeStatus.Cancelled;
        CancelledByUserId = cancelledByUserId;
        CancelledAtUtc = cancelledAtUtc;
        CancellationReason = NormalizeCancellationReason(reason);
    }

    private static string NormalizeSignerDisplayName(string value)
    {
        var normalized = value?.Trim() ?? string.Empty;
        if (normalized.Length < 3)
        {
            throw new DomainRuleException("El nombre del firmante debe ser descriptivo.");
        }

        return normalized;
    }

    private static string NormalizeSignerEmail(string value)
    {
        var normalized = value?.Trim().ToLowerInvariant() ?? string.Empty;
        if (normalized.Length < 5 || !normalized.Contains('@'))
        {
            throw new DomainRuleException("El email del firmante es obligatorio y debe ser válido.");
        }

        return normalized;
    }

    private static string NormalizeSignatureLevel(string value)
    {
        var normalized = value?.Trim().ToUpperInvariant() ?? string.Empty;
        if (!AllowedSignatureLevels.Contains(normalized))
        {
            throw new DomainRuleException("El nivel de firma debe ser ELECTRONIC o DIGITAL.");
        }

        return normalized;
    }

    private static string NormalizeProviderCode(string? value)
    {
        var normalized = value?.Trim().ToUpperInvariant();
        return string.IsNullOrWhiteSpace(normalized) ? "INTERNAL" : normalized;
    }

    private static string? NormalizeExternalReference(string? value)
    {
        var normalized = value?.Trim();
        return string.IsNullOrWhiteSpace(normalized) ? null : normalized;
    }

    private static string NormalizeCancellationReason(string? value)
    {
        var normalized = value?.Trim() ?? string.Empty;
        if (normalized.Length < 5)
        {
            throw new DomainRuleException("El motivo de cancelacion debe ser descriptivo.");
        }

        return normalized;
    }

    private static string? NormalizeOptionalCancellationReason(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return NormalizeCancellationReason(value);
    }
}
