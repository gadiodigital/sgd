using System.Globalization;
using System.Text;
using System.Text.Json;
using Gdms.Domain.Common;

namespace Gdms.Application.Structure;

/// <summary>
/// Validates and normalizes hierarchy node metadata against a container type schema.
/// </summary>
public sealed class StructureMetadataSchemaValidator
{
    public string NormalizeSchema(string? metadataSchemaJson)
    {
        if (string.IsNullOrWhiteSpace(metadataSchemaJson))
        {
            return "{}";
        }

        try
        {
            using var schema = JsonDocument.Parse(metadataSchemaJson);
            if (schema.RootElement.ValueKind != JsonValueKind.Object)
            {
                throw new DomainRuleException("El esquema de atributos del contenedor debe ser un objeto JSON.");
            }

            foreach (var property in schema.RootElement.EnumerateObject())
            {
                _ = MetadataFieldRule.FromJson(property.Name, property.Value);
            }

            return schema.RootElement.GetRawText();
        }
        catch (JsonException)
        {
            throw new DomainRuleException("El esquema de atributos del contenedor no tiene un formato JSON válido.");
        }
    }

    public string NormalizeMetadata(string? metadataJson, ContainerTypeDefinitionView containerType)
    {
        using var payloadDocument = ParsePayload(metadataJson);
        using var schemaDocument = JsonDocument.Parse(containerType.MetadataSchemaJson);
        var fieldRules = schemaDocument.RootElement
            .EnumerateObject()
            .Select(property => MetadataFieldRule.FromJson(property.Name, property.Value))
            .ToArray();
        var payloadValues = payloadDocument is null
            ? new Dictionary<string, JsonElement>(StringComparer.OrdinalIgnoreCase)
            : payloadDocument.RootElement.EnumerateObject()
                .ToDictionary(property => property.Name, property => property.Value, StringComparer.OrdinalIgnoreCase);

        foreach (var payloadProperty in payloadValues.Keys)
        {
            if (fieldRules.All(rule => !string.Equals(rule.Key, payloadProperty, StringComparison.OrdinalIgnoreCase)))
            {
                throw new DomainRuleException(
                    $"El atributo '{payloadProperty}' no está definido para el tipo de contenedor '{containerType.Code}'.");
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

        return stream.Length == 2 ? "{}" : Encoding.UTF8.GetString(stream.ToArray());
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
                throw new DomainRuleException("Los atributos del nodo deben enviarse como un objeto JSON.");
            }

            return payloadDocument;
        }
        catch (JsonException)
        {
            throw new DomainRuleException("Los atributos del nodo no tienen un formato JSON válido.");
        }
    }

    private static void EnsureRequired(MetadataFieldRule rule)
    {
        if (rule.Required)
        {
            throw new DomainRuleException(
                $"El atributo obligatorio '{rule.DisplayName}' es requerido para continuar.");
        }
    }

    private static void WriteNormalizedValue(Utf8JsonWriter writer, MetadataFieldRule rule, JsonElement value)
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
            case MetadataFieldType.List:
                writer.WriteString(rule.Key, NormalizeList(rule, value));
                return;
            case MetadataFieldType.Json:
                writer.WritePropertyName(rule.Key);
                value.WriteTo(writer);
                return;
            default:
                throw new DomainRuleException(
                    $"El tipo de atributo '{rule.Type}' no está soportado para '{rule.DisplayName}'.");
        }
    }

    private static string NormalizeText(MetadataFieldRule rule, JsonElement value)
    {
        if (value.ValueKind != JsonValueKind.String)
        {
            throw new DomainRuleException($"El atributo '{rule.DisplayName}' debe ser una cadena.");
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
                $"El atributo '{rule.DisplayName}' excede la longitud máxima de {maxLength}.");
        }

        return text;
    }

    private static string NormalizeDate(MetadataFieldRule rule, JsonElement value)
    {
        if (value.ValueKind != JsonValueKind.String)
        {
            throw new DomainRuleException($"El atributo '{rule.DisplayName}' debe enviarse como fecha ISO.");
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
                $"El atributo '{rule.DisplayName}' debe respetar el formato de fecha AAAA-MM-DD.");
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

        throw new DomainRuleException($"El atributo '{rule.DisplayName}' debe ser un entero.");
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

        throw new DomainRuleException($"El atributo '{rule.DisplayName}' debe ser numérico.");
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

        throw new DomainRuleException($"El atributo '{rule.DisplayName}' debe ser booleano.");
    }

    private static string NormalizeList(MetadataFieldRule rule, JsonElement value)
    {
        var text = NormalizeText(rule, value);
        if (text.Length == 0 || rule.Options.Count == 0)
        {
            return text;
        }

        if (!rule.Options.Contains(text, StringComparer.OrdinalIgnoreCase))
        {
            throw new DomainRuleException(
                $"El atributo '{rule.DisplayName}' debe usar una opción configurada.");
        }

        return rule.Options.First(option => string.Equals(option, text, StringComparison.OrdinalIgnoreCase));
    }

    private enum MetadataFieldType
    {
        String,
        Date,
        Integer,
        Number,
        Boolean,
        List,
        Json
    }

    private sealed record MetadataFieldRule(
        string Key,
        string DisplayName,
        MetadataFieldType Type,
        bool Required,
        int? MaxLength,
        IReadOnlyCollection<string> Options)
    {
        public static MetadataFieldRule FromJson(string key, JsonElement definition)
        {
            if (definition.ValueKind != JsonValueKind.Object)
            {
                throw new DomainRuleException(
                    $"La definición del atributo '{key}' debe ser un objeto JSON.");
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
            var options = definition.TryGetProperty("options", out var optionsValue) &&
                optionsValue.ValueKind == JsonValueKind.Array
                    ? optionsValue.EnumerateArray()
                        .Where(item => item.ValueKind == JsonValueKind.String)
                        .Select(item => item.GetString()?.Trim())
                        .Where(item => !string.IsNullOrWhiteSpace(item))
                        .Select(item => item!)
                        .ToArray()
                    : Array.Empty<string>();

            return new MetadataFieldRule(key, label, type, required, maxLength, options);
        }

        private static MetadataFieldType ParseType(string key, string? type)
        {
            return type?.Trim().ToLowerInvariant() switch
            {
                null or "" or "string" => MetadataFieldType.String,
                "date" => MetadataFieldType.Date,
                "integer" => MetadataFieldType.Integer,
                "number" or "decimal" => MetadataFieldType.Number,
                "boolean" => MetadataFieldType.Boolean,
                "list" => MetadataFieldType.List,
                "json" => MetadataFieldType.Json,
                _ => throw new DomainRuleException(
                    $"El tipo '{type}' del atributo '{key}' no está soportado.")
            };
        }
    }
}

/// <summary>
/// Minimal view needed by the metadata validator.
/// </summary>
public sealed record ContainerTypeDefinitionView(string Code, string MetadataSchemaJson);
