namespace Gdms.Contracts.Notifications;

/// <summary>
/// Represents one notification returned by the inbox API.
/// </summary>
public sealed record NotificationResponse(
    string Category,
    string Title,
    string Detail,
    string Severity,
    DateTimeOffset OccurredAtUtc);
