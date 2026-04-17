CREATE   PROCEDURE assoc.sp_AssociationProfile_Upsert
    @AssociationId INT,
    @RegistrationNumber NVARCHAR(100),
    @RegistrationDate DATETIME2,
    @Address NVARCHAR(MAX),
    @City NVARCHAR(100),
    @State NVARCHAR(100),
    @Pincode NVARCHAR(20),
    @ContactEmail NVARCHAR(255),
    @ContactPhone NVARCHAR(50),
    @Logo VARBINARY(MAX) = NULL
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.AssociationProfile WHERE AssociationId = @AssociationId)
    BEGIN
        UPDATE assoc.AssociationProfile SET 
            RegistrationNumber = @RegistrationNumber, 
            RegistrationDate = @RegistrationDate,
            Address = @Address, City = @City, State = @State, Pincode = @Pincode,
            ContactEmail = @ContactEmail, ContactPhone = @ContactPhone,
            Logo = @Logo
        WHERE AssociationId = @AssociationId;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.AssociationProfile (AssociationId, RegistrationNumber, RegistrationDate, Address, City, State, Pincode, ContactEmail, ContactPhone, Logo)
        VALUES (@AssociationId, @RegistrationNumber, @RegistrationDate, @Address, @City, @State, @Pincode, @ContactEmail, @ContactPhone, @Logo);
    END
END;