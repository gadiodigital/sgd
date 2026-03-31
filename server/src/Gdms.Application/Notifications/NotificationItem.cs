namespace Gdms.Application.Notifications;

/// <summary>
/// Represents an actionable notification surfaced to a tenant inbox.
/// </summary>
public sealed record NotificationItem(
    string Category,
    string Title,
    string Detail,
    string Severity,
    DateTimeOffset OccurredAtUtc);
