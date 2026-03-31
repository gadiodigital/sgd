using Gdms.Domain.Signatures;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines read and write operations for signature envelopes.
/// </summary>
public interface ISignatureEnvelopeRepository
{
    /// <summary>
    /// Lists signature envelopes that belong to a tenant.
    /// </summary>
    Task<IReadOnlyCollection<SignatureEnvelope>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken);

    /// <summary>
    /// Retrieves a signature envelope by identifier.
    /// </summary>
    Task<SignatureEnvelope?> GetByIdAsync(Guid envelopeId, CancellationToken cancellationToken);

    /// <summary>
    /// Persists a new signature envelope.
    /// </summary>
    Task<SignatureEnvelope> AddAsync(SignatureEnvelope envelope, CancellationToken cancellationToken);

    /// <summary>
    /// Marks a signature envelope as completed.
    /// </summary>
    Task CompleteAsync(
        Guid tenantId,
        Guid envelopeId,
        Guid completedByUserId,
        DateTimeOffset completedAtUtc,
        string? externalReference,
        CancellationToken cancellationToken);

    /// <summary>
    /// Marks a signature envelope as cancelled.
    /// </summary>
    Task CancelAsync(
        Guid tenantId,
        Guid envelopeId,
        Guid cancelledByUserId,
        DateTimeOffset cancelledAtUtc,
        string cancellationReason,
        CancellationToken cancellationToken);
}
