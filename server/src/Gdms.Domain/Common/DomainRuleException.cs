namespace Gdms.Domain.Common;

/// <summary>
/// Represents a violation of an explicit domain invariant.
/// </summary>
public sealed class DomainRuleException : Exception
{
    /// <summary>
    /// Initializes a new exception with the violated rule message.
    /// </summary>
    /// <param name="message">Human readable validation message.</param>
    public DomainRuleException(string message) : base(message)
    {
    }
}
