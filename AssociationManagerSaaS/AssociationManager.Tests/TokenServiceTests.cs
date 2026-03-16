using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Moq;
using Xunit;
using AssociationManager.Auth.Implementations;
using AssociationManager.Shared.Models;

namespace AssociationManager.Tests
{
    public class TokenServiceTests
    {
        private readonly Mock<IConfiguration> _configMock;
        private readonly TokenService _tokenService;
        private const string SecretKey = "ThisIsASecretKeyWithAtLeast32CharactersForTesting!!";

        public TokenServiceTests()
        {
            _configMock = new Mock<IConfiguration>();
            _configMock.Setup(c => c["Jwt:Key"]).Returns(SecretKey);
            _configMock.Setup(c => c["Jwt:Issuer"]).Returns("TestIssuer");
            _configMock.Setup(c => c["Jwt:Audience"]).Returns("TestAudience");
            _configMock.Setup(c => c["Jwt:ExpiryMinutes"]).Returns("60");

            _tokenService = new TokenService(_configMock.Object);
        }

        [Fact]
        public void GenerateAccessToken_ShouldReturnValidJwt()
        {
            // Arrange
            var user = new User { Id = 1, Email = "test@example.com", FullName = "Test User" };
            var roles = new List<string> { "User" };

            // Act
            var token = _tokenService.GenerateAccessToken(user, 10, roles);

            // Assert
            Assert.NotNull(token);
            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(token);

            Assert.Equal("test@example.com", jwtToken.Claims.FirstOrDefault(c => c.Type == ClaimTypes.Email)?.Value);
            Assert.Equal("10", jwtToken.Claims.FirstOrDefault(c => c.Type == "TenantId")?.Value);
        }

        [Fact]
        public void GenerateRefreshToken_ShouldReturnString()
        {
            // Act
            var refreshToken = _tokenService.GenerateRefreshToken();

            // Assert
            Assert.NotNull(refreshToken);
            Assert.NotEmpty(refreshToken);
        }
    }
}
