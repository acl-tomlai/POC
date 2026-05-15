using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Pos.Api.DTOs;
using Pos.Api.Helpers;

namespace Pos.Api.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (AppException ex)
        {
            await WriteAsync(context, ex.StatusCode, ex.Message, ex.Details);
        }
        catch (AuthorizationFailedException ex)
        {
            await WriteAsync(context, 403, "Forbidden.", ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception while processing {Path}", context.Request.Path);
            await WriteAsync(context, 500, "An unexpected error occurred.", null);
        }
    }

    private static async Task WriteAsync(HttpContext context, int statusCode, string message, string? details)
    {
        if (context.Response.HasStarted) return;
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/json";
        var payload = new ErrorResponse(message, details);
        await context.Response.WriteAsync(JsonSerializer.Serialize(payload,
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }));
    }
}

public class AuthorizationFailedException : Exception
{
    public AuthorizationFailedException(string message) : base(message) { }
}
