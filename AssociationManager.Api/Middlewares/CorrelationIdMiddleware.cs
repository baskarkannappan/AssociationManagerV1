using Microsoft.AspNetCore.Http;
using Serilog.Context;
using System;
using System.Threading.Tasks;

namespace AssociationManager.Api.Middlewares;

public class CorrelationIdMiddleware
{
    private readonly RequestDelegate _next;
    private const string CorrelationIdHeader = "X-Correlation-ID";

    public CorrelationIdMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (!context.Request.Headers.TryGetValue(CorrelationIdHeader, out var correlationId))
        {
            correlationId = Guid.NewGuid().ToString();
        }

        // Push to Serilog LogContext so all logs for this request carry the ID
        using (LogContext.PushProperty("CorrelationId", correlationId))
        {
            // Add to response header for client visibility
            context.Response.Headers[CorrelationIdHeader] = correlationId;
            
            await _next(context);
        }
    }
}
