CREATE TABLE [assoc].[AssociationProfile] (
    [AssociationId]      INT             NOT NULL,
    [RegistrationNumber] NVARCHAR (100)  NULL,
    [RegistrationDate]   DATETIME        NULL,
    [Address]            NVARCHAR (500)  NULL,
    [City]               NVARCHAR (100)  NULL,
    [State]              NVARCHAR (100)  NULL,
    [Pincode]            NVARCHAR (20)   NULL,
    [ContactEmail]       NVARCHAR (255)  NULL,
    [ContactPhone]       NVARCHAR (50)   NULL,
    [Logo]               VARBINARY (MAX) NULL,
    PRIMARY KEY CLUSTERED ([AssociationId] ASC),
    FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId])
);

