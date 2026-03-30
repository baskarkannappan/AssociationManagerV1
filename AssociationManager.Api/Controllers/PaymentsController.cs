using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentServiceV2 _paymentService;

    public PaymentsController(IPaymentServiceV2 paymentService)
    {
        _paymentService = paymentService;
    }

    [HttpPost("create-order")]
    public async Task<IActionResult> CreateOrder([FromBody] RazorpayOrderRequest request)
    {
        try
        {
            var result = await _paymentService.CreateOrderAsync(request);
            return Ok(ApiResponse<RazorpayOrderResponse>.SuccessResponse(result));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse.FailureResponse(ex.Message));
        }
    }

    [HttpPost("verify")]
    public async Task<IActionResult> VerifyPayment([FromBody] RazorpayVerifyRequest request)
    {
        try
        {
            var result = await _paymentService.VerifySignatureAsync(request);
            if (result)
            {
                return Ok(ApiResponse.SuccessResponse("Payment verified successfully."));
            }
            return BadRequest(ApiResponse.FailureResponse("Invalid payment signature."));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse.FailureResponse(ex.Message));
        }
    }

    [AllowAnonymous]
    [HttpPost("webhook")]
    public async Task<IActionResult> Webhook()
    {
        try
        {
            using var reader = new StreamReader(Request.Body, Encoding.UTF8);
            var payload = await reader.ReadToEndAsync();
            var signature = Request.Headers["X-Razorpay-Signature"].ToString();

            await _paymentService.ProcessWebhookAsync(payload, signature);
            return Ok();
        }
        catch (Exception)
        {
            return Ok(); 
        }
    }

    [HttpGet("history/{invoiceId}")]
    public async Task<IActionResult> GetHistory(int invoiceId)
    {
        try
        {
            var history = await _paymentService.GetPaymentHistoryAsync(invoiceId);
            return Ok(ApiResponse<object>.SuccessResponse(history));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse.FailureResponse(ex.Message));
        }
    }
}
