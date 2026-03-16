# Testing Design - AssociationManagerSaaS

## Strategy
The testing strategy comprises unit tests, integration tests, and manual verification to ensure high reliability and security.

## Unit Testing
- **Shared Projects**: Validate DTO mappings and logic in `AssociationManager.Shared`.
- **Business Services**: Mock dependencies (`ITenantAccessor`, `IDistributedCache`, `IRepository`) using xUnit and Moq to test business logic isolation.
- **Auth Logic**: Test token generation and validation logic independently.

## Integration Testing
- **API Endpoints**: Use `WebApplicationFactory` to run integration tests against a test SQL database.
- **Multi-tenancy Validation**: Verify that a user from Tenant A cannot see data from Tenant B.
- **Redis Cache**: Test cache hit/miss scenarios and invalidation logic on record updates.
- **SignalR messaging**: Verify that messages are correctly broadcasted to specific tenant groups.

## Security Testing
- **Token Rotation**: Verify that an old refresh token is invalidated as soon as it's rotated.
- **Claim Verification**: Ensure `TenantId` and `UserId` claims are present and correctly parsed.
- **SQL Injection**: Perform manual penetration testing on repository queries.

## Performance Testing
- **Rate Limiting**: Stress test the API to ensure the Redis-backed rate limiter functions correctly.
- **Concurrent Users**: Simulate multiple tenants performing actions simultaneously.

## Deployment Verification
- Smoke tests after CI/CD deployment to ensure gateway routing and database connectivity.
