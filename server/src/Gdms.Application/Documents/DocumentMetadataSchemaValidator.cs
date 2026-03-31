using System.Globalization;
using System.Text;
using System.Text.Json;
using Gdms.Domain.Common;

namespace Gdms.Application.Documents;

/// <summary>
/// Validates and normalizes document metadata using the active document type schema.
/// </summary>
public sealed class DocumentMetadataSchemaValidator
{
    /// <summary>
    /// Validates metadata JSON and returns a normalized JSON object or null when empty.
    /// </summary>
    public string? ValidateAndNormalize(string? metadataJson, DocumentTypeDefinition documentType)
    {
        using var payloadDocument = ParsePayload(metadataJson);
        var fieldRules = ReadFieldRules(documentType);
        var payloadValues = payloadDocument is null
            ? new Dictionary<string, JsonElement>(StringComparer.OrdinalIgnoreCase)
            : payloadDocument.RootElement.EnumerateObject()
                .ToDictionary(property => property.Name, property => property.Value, StringComparer.OrdinalIgnoreCase);

        foreach (var payloadProperty in payloadValues.Keys)
        {
            if (fieldRules.All(rule => !string.Equals(rule.Key, payloadProperty, StringComparison.OrdinalIgnoreCase)))
            {
                throw new DomainRuleException(
                    $"El metadato '{payloadProperty}' no está definido para el tipo documental '{documentType.Code}'.");
            }
        }

        using var stream = new MemoryStream();
        using var writer = new Utf8JsonWriter(stream);
        writer.WriteStartObject();

        foreach (var rule in fieldRules)
        {
            if (!payloadValues.TryGetValue(rule.Key, out var value))
            {
                EnsureRequired(rule);
                continue;
            }

            if (value.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined)
            {
                EnsureRequired(rule);
                continue;
            }

            WriteNormalizedValue(writer, rule, value);
        }

        writer.WriteEndObject();
        writer.Flush();

        return stream.Length == 2 ? null : Encoding.UTF8.GetString(stream.ToArray());
    }

    private static JsonDocument? ParsePayload(string? metadataJson)
    {
        if (string.IsNullOrWhiteSpace(metadataJson))
        {
            return null;
        }

        try
        {
            var payloadDocument = JsonDocument.Parse(metadataJson);
            if (payloadDocument.RootElement.ValueKind != JsonValueKind.Object)
            {
                throw new DomainRuleException("Los metadatos del documento deben enviarse como un objeto JSON.");
            }

            return payloadDocument;
        }
        catch (JsonException)
        {
            throw new DomainRuleException("Los metadatos del documento no tienen un formato JSON válido.");
        }
    }

    private static IReadOnlyCollection<MetadataFieldRule> ReadFieldRules(DocumentTypeDefinition documentType)
    {
        if (documentType.MetadataSchema.RootElement.ValueKind != JsonValueKind.Object)
        {
            throw new DomainRuleException(
                $"El esquema de metadatos del tipo documental '{documentType.Code}' no es un objeto JSON válido.");
        }

        return documentType.MetadataSchema.RootElement
            .EnumerateObject()
            .Select(property => MetadataFieldRule.FromJson(property.Name, property.Value))
            .ToArray();
    }

    private static void EnsureRequired(MetadataFieldRule rule)
    {
        if (rule.Required)
        {
            throw new DomainRuleException(
                $"El metadato obligatorio '{rule.DisplayName}' es requerido para continuar.");
        }
    }

    private static void WriteNormalizedValue(
        Utf8JsonWriter writer,
        MetadataFieldRule rule,
        JsonElement value)
    {
        switch (rule.Type)
        {
            case MetadataFieldType.String:
                writer.WriteString(rule.Key, NormalizeText(rule, value));
                return;
            case MetadataFieldType.Date:
                writer.WriteString(rule.Key, NormalizeDate(rule, value));
                return;
            case MetadataFieldType.Integer:
                writer.WriteNumber(rule.Key, NormalizeInteger(rule, value));
                return;
            case MetadataFieldType.Number:
                writer.WriteNumber(rule.Key, NormalizeNumber(rule, value));
                return;
            case MetadataFieldType.Boolean:
                writer.WriteBoolean(rule.Key, NormalizeBoolean(rule, value));
                return;
            default:
                throw new DomainRuleException(
                    $"El tipo de metadato '{rule.Type}' no está soportado para '{rule.DisplayName}'.");
        }
    }

    private static string NormalizeText(MetadataFieldRule rule, JsonElement value)
    {
        if (value.ValueKind != JsonValueKind.String)
        {
            throw new DomainRuleException($"El metadato '{rule.DisplayName}' debe ser una cadena.");
        }

        var text = value.GetString()?.Trim() ?? string.Empty;
        if (text.Length == 0)
        {
            EnsureRequired(rule);
            return string.Empty;
        }

        if (rule.MaxLength is { } maxLength && text.Length > maxLength)
        {
            throw new DomainRuleException(
                $"El metadato '{rule.DisplayName}' excede la longitud máxima de {maxLength}.");
        }

        return text;
    }

    private static string NormalizeDate(MetadataFieldRule rule, JsonElement value)
    {
        if (value.ValueKind != JsonValueKind.String)
        {
            throw new DomainRuleException($"El metadato '{rule.DisplayName}' debe enviarse como fecha ISO.");
        }

        var text = value.GetString()?.Trim() ?? string.Empty;
        if (text.Length == 0)
        {
            EnsureRequired(rule);
            return string.Empty;
        }

        if (!DateOnly.TryParseExact(text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed))
        {
            throw new DomainRuleException(
                $"El metadato '{rule.DisplayName}' debe respetar el formato de fecha AAAA-MM-DD.");
        }

        return parsed.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
    }

    private static long NormalizeInteger(MetadataFieldRule rule, JsonElement value)
    {
        if (value.ValueKind == JsonValueKind.Number && value.TryGetInt64(out var numericValue))
        {
            return numericValue;
        }

        if (value.ValueKind == JsonValueKind.String &&
            long.TryParse(value.GetString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed))
        {
            return parsed;
        }

        throw new DomainRuleException($"El metadato '{rule.DisplayName}' debe ser un entero.");
    }

    private static decimal NormalizeNumber(MetadataFieldRule rule, JsonElement value)
    {
        if (value.ValueKind == JsonValueKind.Number && value.TryGetDecimal(out var decimalValue))
        {
            return decimalValue;
        }

        if (value.ValueKind == JsonValueKind.String &&
            decimal.TryParse(value.GetString(), NumberStyles.Number, CultureInfo.InvariantCulture, out var parsed))
        {
            return parsed;
        }

        throw new DomainRuleException($"El metadato '{rule.DisplayName}' debe ser numérico.");
    }

    private static bool NormalizeBoolean(MetadataFieldRule rule, JsonElement value)
    {
        if (value.ValueKind == JsonValueKind.True)
        {
            return true;
        }

        if (value.ValueKind == JsonValueKind.False)
        {
            return false;
        }

        if (value.ValueKind == JsonValueKind.String &&
            bool.TryParse(value.GetString(), out var parsed))
        {
            return parsed;
        }

        throw new DomainRuleException($"El metadato '{rule.DisplayName}' debe ser booleano.");
    }

    private enum MetadataFieldType
    {
        String,
        Date,
        Integer,
        Number,
        Boolean
    }

    private sealed record MetadataFieldRule(
        string Key,
        string DisplayName,
        MetadataFieldType Type,
        bool Required,
        int? MaxLength)
    {
        public static MetadataFieldRule FromJson(string key, JsonElement definition)
        {
            if (definition.ValueKind != JsonValueKind.Object)
            {
                throw new DomainRuleException(
                    $"La definición del metadato '{key}' debe ser un objeto JSON.");
            }

            var type = definition.TryGetProperty("type", out var typeValue)
                ? ParseType(key, typeValue.GetString())
                : MetadataFieldType.String;
            var required = definition.TryGetProperty("required", out var requiredValue) &&
                requiredValue.ValueKind is JsonValueKind.True or JsonValueKind.False &&
                requiredValue.GetBoolean();
            var maxLength = definition.TryGetProperty("maxLength", out var maxLengthValue) &&
                maxLengthValue.ValueKind == JsonValueKind.Number &&
                maxLengthValue.TryGetInt32(out var parsedMaxLength)
                    ? parsedMaxLength
                    : (int?)null;
            var label = definition.TryGetProperty("label", out var labelValue) &&
                labelValue.ValueKind == JsonValueKind.String &&
                !string.IsNullOrWhiteSpace(labelValue.GetString())
                    ? labelValue.GetString()!.Trim()
                    : key;

            return new MetadataFieldRule(key, label, type, required, maxLength);
        }

        private static MetadataFieldType ParseType(string key, string? type)
        {
            return type?.Trim().ToLowerInvariant() switch
            {
                null or "" or "string" => MetadataFieldType.String,
                "date" => MetadataFieldType.Date,
                "integer" => MetadataFieldType.Integer,
                "number" => MetadataFieldType.Number,
                "boolean" => MetadataFieldType.Boolean,
                _ => throw new DomainRuleException(
                    $"El tipo '{type}' del metadato '{key}' no está soportado.")
            };
        }
    }
}
