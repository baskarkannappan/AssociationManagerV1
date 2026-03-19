using AssociationManager.Data;
using AssociationManager.Data.Repositories;
using AssociationManager.Services.Implementations;
using AssociationManager.Shared.Models;
using System;
using System.Threading.Tasks;

/*
    Manual Verification Script for Hybrid Pricing
*/

var dbConnectionFactory = new DbConnectionFactory(null); // Will use fallback connection string
var subRepo = new SubscriptionRepository(dbConnectionFactory);
var assetRepo = new AssetRepository(dbConnectionFactory, null);
var subService = new SubscriptionService(subRepo, assetRepo);

int testAssociationId = 1; // Assuming Association 1 exists
int testPlanId = 1; // 'Starter' plan ($50 base + $0.50 per asset)

Console.WriteLine("--- Hybrid Pricing Verification ---");

// 1. Subscribe Association 1 to Plan 1
Console.WriteLine("Subscribing Association 1 to Starter Plan...");
await subService.SubscribeAsync(testAssociationId, testPlanId);

// 2. Count Assets
int count = await assetRepo.CountAsync(1, testAssociationId);
Console.WriteLine($"Active Assets for Association 1: {count}");

// 3. Calculate Bill
decimal bill = await subService.CalculateNextBillAsync(testAssociationId);
Console.WriteLine($"Calculated Next Bill: ${bill}");

decimal expected = 50.00m + (count * 0.50m);
if (bill == expected)
{
    Console.WriteLine("SUCCESS: Calculation matches expected value.");
}
else
{
    Console.WriteLine($"FAILURE: Expected ${expected}, but got ${bill}.");
}
