using System.Collections.Generic;
using System.Threading.Tasks;
using Moq;
using Xunit;
using AssociationManager.Auth.Implementations;
using AssociationManager.Auth.Interfaces;
using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.DTOs;

namespace AssociationManager.Tests
{
    public class AuthServiceTests
    {
        private readonly Mock<IUserService> _userServiceMock;
        private readonly Mock<ITenantService> _tenantServiceMock;
        private readonly Mock<ITokenService> _tokenServiceMock;
        private readonly Mock<IRefreshTokenRepository> _tokenRepoMock;
        private readonly AuthService _authService;

        public AuthServiceTests()
        {
            _userServiceMock = new Mock<IUserService>();
            _tenantServiceMock = new Mock<ITenantService>();
            _tokenServiceMock = new Mock<ITokenService>();
            _tokenRepoMock = new Mock<IRefreshTokenRepository>();

            _authService = new AuthService(
                _userServiceMock.Object,
                _tenantServiceMock.Object,
                _tokenServiceMock.Object,
                _tokenRepoMock.Object
            );
        }

        [Fact]
        public async Task GoogleLoginAsync_ShouldReturnAuthResponse()
        {
            // Arrange
            var user = new User { Id = 1, Email = "test@example.com", FullName = "Test User" };
            var tenants = new List<Tenant> { new Tenant { Id = 10, Name = "Test Tenant", Identifier = "test" } };
            
            _userServiceMock.Setup(s => s.CreateOrUpdateGoogleUserAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>()))
                .ReturnsAsync(user);
            _tenantServiceMock.Setup(s => s.GetUserTenantsAsync(user.Id))
                .ReturnsAsync(tenants);
            _tokenServiceMock.Setup(s => s.GenerateAccessToken(It.IsAny<User>(), It.IsAny<int?>(), It.IsAny<List<string>>()))
                .Returns("mock-access-token");
            _tokenServiceMock.Setup(s => s.GenerateRefreshToken())
                .Returns("mock-refresh-token");

            // Act
            var result = await _authService.GoogleLoginAsync("google-token");

            // Assert
            Assert.NotNull(result);
            Assert.Equal("mock-access-token", result.Token);
            Assert.Equal("mock-refresh-token", result.RefreshToken);
            Assert.Equal(10, result.CurrentTenantId);
            _tokenRepoMock.Verify(r => r.CreateAsync(It.IsAny<RefreshToken>()), Times.Once);
        }
    }
}
