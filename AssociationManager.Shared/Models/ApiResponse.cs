using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string? Message { get; set; }
    public List<string>? Errors { get; set; }

    public static ApiResponse<T> SuccessResponse(T data, string? message = null) => 
        new() { Success = true, Data = data, Message = message };

    public static ApiResponse<T> ErrorResponse(string message, List<string>? errors = null) => 
        new() { Success = false, Message = message, Errors = errors };
}

public class ApiResponse : ApiResponse<object>
{
    public static ApiResponse SuccessResponse(string? message = null) => 
        new() { Success = true, Message = message };

    public static ApiResponse FailureResponse(string message, List<string>? errors = null) => 
        new() { Success = false, Message = message, Errors = errors };
}
