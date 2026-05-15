namespace Pos.Api.DTOs;

public record ErrorResponse(string Message, string? Details = null);
