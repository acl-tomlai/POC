namespace Pos.Api.Helpers;

public class AppException : Exception
{
    public int StatusCode { get; }
    public string? Details { get; }

    public AppException(string message, int statusCode = 400, string? details = null)
        : base(message)
    {
        StatusCode = statusCode;
        Details = details;
    }
}

public class NotFoundException : AppException
{
    public NotFoundException(string message) : base(message, 404) { }
}

public class ForbiddenException : AppException
{
    public ForbiddenException(string message) : base(message, 403) { }
}

public class ConflictException : AppException
{
    public ConflictException(string message) : base(message, 409) { }
}
