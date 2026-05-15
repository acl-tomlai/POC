using System.Text.RegularExpressions;

namespace Pos.Api.Helpers;

public static partial class SlugRules
{
    public static readonly HashSet<string> Denylist = new(StringComparer.OrdinalIgnoreCase)
    {
        "admin", "api", "me", "signup", "auth"
    };

    [GeneratedRegex("^[a-z0-9-]{3,40}$")]
    private static partial Regex SlugRegex();

    public static bool IsValid(string slug, out string? error)
    {
        if (string.IsNullOrWhiteSpace(slug))
        {
            error = "Slug is required.";
            return false;
        }
        if (!SlugRegex().IsMatch(slug))
        {
            error = "Slug must match ^[a-z0-9-]{3,40}$ (lowercase letters, digits, hyphens; 3-40 chars).";
            return false;
        }
        if (Denylist.Contains(slug))
        {
            error = "Slug is reserved.";
            return false;
        }
        error = null;
        return true;
    }
}
