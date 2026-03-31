-- 3. Fix Elections Insert (Ensure 5 params)
CREATE   PROCEDURE assoc.sp_Elections_Insert
    @AssociationId INT,
    @Title NVARCHAR(200),
    @StartDate DATETIME2,
    @EndDate DATETIME2,
    @IsActive BIT
AS
BEGIN
    INSERT INTO assoc.Elections (AssociationId, Title, StartDate, EndDate, IsActive) 
    VALUES (@AssociationId, @Title, @StartDate, @EndDate, @IsActive);
    SELECT SCOPE_IDENTITY();
END;