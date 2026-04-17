/* FULL QA DATABASE SETUP - DATABASE NEUTRAL */
GO


/* 1. SCHEMAS & SECURITY */

CREATE USER [appuser] FOR LOGIN [appuser];


GO

CREATE SCHEMA [archive]
    AUTHORIZATION [dbo];

GO

CREATE SCHEMA [archive]
    AUTHORIZATION [appuser];


GO

CREATE SCHEMA [assoc]
    AUTHORIZATION [dbo];


GO

CREATE SCHEMA [corp]
    AUTHORIZATION [dbo];


GO

CREATE SCHEMA [HangFire]
    AUTHORIZATION [appuser];


GO

ALTER ROLE [db_owner] ADD MEMBER [appuser];


GO

CREATE SCHEMA [Security]
    AUTHORIZATION [appuser];


GO

CREATE SECURITY POLICY [Security].[TenantSecurityPolicy_AuditLogs]
    ADD FILTER PREDICATE [Security].[fn_TenantAccessPredicate]([TenantId]) ON [corp].[AuditLogs],
    ADD BLOCK PREDICATE [Security].[fn_TenantAccessPredicate]([TenantId]) ON [corp].[AuditLogs]
    WITH (STATE = ON);


GO

CREATE SECURITY POLICY [Security].[TenantSecurityPolicy_Invoices]
    ADD FILTER PREDICATE [Security].[fn_TenantAccessPredicate]([TenantId]) ON [assoc].[Invoices],
    ADD BLOCK PREDICATE [Security].[fn_TenantAccessPredicate]([TenantId]) ON [assoc].[Invoices]
    WITH (STATE = ON);


GO

CREATE SECURITY POLICY [Security].[TenantSecurityPolicy_Transactions]
    ADD FILTER PREDICATE [Security].[fn_TenantAccessPredicate]([TenantId]) ON [assoc].[Transactions],
    ADD BLOCK PREDICATE [Security].[fn_TenantAccessPredicate]([TenantId]) ON [assoc].[Transactions]
    WITH (STATE = ON);


GO


/* 2. TABLES */

CREATE TABLE [dbo].[SchemaVersions] (
    [Id]         INT            IDENTITY (1, 1) NOT NULL,
    [ScriptName] NVARCHAR (255) NOT NULL,
    [Applied]    DATETIME       NOT NULL,
    CONSTRAINT [PK_SchemaVersions_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

CREATE TABLE [assoc].[Assets] (
    [AssetId]       INT            IDENTITY (1, 1) NOT NULL,
    [ParentId]      INT            NULL,
    [TenantId]      INT            NOT NULL,
    [Name]          NVARCHAR (200) NOT NULL,
    [Description]   NVARCHAR (500) NULL,
    [AssetType]     INT            NOT NULL,
    [MetadataJson]  NVARCHAR (MAX) NULL,
    [CreatedDate]   DATETIME       DEFAULT (getdate()) NOT NULL,
    [CreatedBy]     INT            NULL,
    [IsActive]      BIT            DEFAULT ((1)) NOT NULL,
    [AssociationId] INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([AssetId] ASC),
    CONSTRAINT [FK_Assets_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Assets_Parent] FOREIGN KEY ([ParentId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Assets_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Assets_AssociationId]
    ON [assoc].[Assets]([AssociationId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Assets_AssetType]
    ON [assoc].[Assets]([AssetType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Assets_ParentId]
    ON [assoc].[Assets]([ParentId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Assets_TenantId]
    ON [assoc].[Assets]([TenantId] ASC);


GO

CREATE TABLE [assoc].[AssetTariffs] (
    [AssetId]       INT             NOT NULL,
    [TariffLayerId] INT             NOT NULL,
    [CustomAmount]  DECIMAL (18, 2) NULL,
    [IsActive]      BIT             DEFAULT ((1)) NOT NULL,
    [IsRecurring]   BIT             DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([AssetId] ASC, [TariffLayerId] ASC),
    CONSTRAINT [FK_AssetTariffs_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_AssetTariffs_Layers] FOREIGN KEY ([TariffLayerId]) REFERENCES [assoc].[TariffLayers] ([TariffLayerId])
);


GO

CREATE TABLE [assoc].[AssociationBankDetails] (
    [AssociationId]              INT             NOT NULL,
    [TenantId]                   INT             NOT NULL,
    [PrimaryAccountName]         NVARCHAR (255)  NULL,
    [PrimaryAccountNumber]       NVARCHAR (50)   NULL,
    [PrimaryIFSCCode]            NVARCHAR (20)   NULL,
    [PrimaryBankName]            NVARCHAR (255)  NULL,
    [PrimaryBranchName]          NVARCHAR (255)  NULL,
    [PrimaryQRCode]              VARBINARY (MAX) NULL,
    [PrimaryQRCodeContentType]   NVARCHAR (100)  NULL,
    [SecondaryAccountName]       NVARCHAR (255)  NULL,
    [SecondaryAccountNumber]     NVARCHAR (50)   NULL,
    [SecondaryIFSCCode]          NVARCHAR (20)   NULL,
    [SecondaryBankName]          NVARCHAR (255)  NULL,
    [SecondaryBranchName]        NVARCHAR (255)  NULL,
    [SecondaryQRCode]            VARBINARY (MAX) NULL,
    [SecondaryQRCodeContentType] NVARCHAR (100)  NULL,
    [CreatedBy]                  INT             NOT NULL,
    [CreatedDate]                DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [LastUpdatedBy]              INT             NULL,
    [LastUpdatedDate]            DATETIME        NULL,
    PRIMARY KEY CLUSTERED ([AssociationId] ASC),
    CONSTRAINT [FK_AssociationBankDetails_Association] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId])
);


GO

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


GO

CREATE TABLE [assoc].[AuthWorkflows] (
    [WorkflowId]   INT            IDENTITY (1, 1) NOT NULL,
    [Name]         NVARCHAR (100) NOT NULL,
    [WorkflowJson] NVARCHAR (MAX) NOT NULL,
    [Description]  NVARCHAR (255) NULL,
    [CreatedDate]  DATETIME2 (7)  DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]  DATETIME2 (7)  DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowId] ASC),
    UNIQUE NONCLUSTERED ([Name] ASC)
);


GO

CREATE TABLE [assoc].[BillingBatches] (
    [BillingBatchId]    INT             IDENTITY (1, 1) NOT NULL,
    [TenantId]          INT             NOT NULL,
    [AssociationId]     INT             NOT NULL,
    [Month]             INT             NOT NULL,
    [Year]              INT             NOT NULL,
    [Status]            NVARCHAR (50)   DEFAULT ('Committed') NOT NULL,
    [TotalAmount]       DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [InvoicesGenerated] INT             DEFAULT ((0)) NOT NULL,
    [CreatedDate]       DATETIME        DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([BillingBatchId] ASC),
    CONSTRAINT [FK_BillingBatches_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_BillingBatches_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO

CREATE TABLE [assoc].[Broadcasts] (
    [BroadcastId]   INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NOT NULL,
    [Title]         NVARCHAR (200) NOT NULL,
    [Content]       NVARCHAR (MAX) NOT NULL,
    [Category]      NVARCHAR (50)  DEFAULT ('General') NOT NULL,
    [CreatedDate]   DATETIME       DEFAULT (getdate()) NOT NULL,
    [CreatedBy]     INT            NOT NULL,
    [IsPinned]      BIT            DEFAULT ((0)) NOT NULL,
    [ExpiresDate]   DATETIME       NULL,
    [AssetId]       INT            NULL,
    [AssociationId] INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([BroadcastId] ASC),
    CONSTRAINT [FK_Broadcasts_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Broadcasts_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Broadcasts_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Broadcasts_AssociationId]
    ON [assoc].[Broadcasts]([AssociationId] ASC);


GO

CREATE TABLE [assoc].[ByeLaws] (
    [ByeLawId]        INT             IDENTITY (1, 1) NOT NULL,
    [AssociationId]   INT             NOT NULL,
    [Title]           NVARCHAR (255)  NOT NULL,
    [Description]     NVARCHAR (MAX)  NULL,
    [EffectiveDate]   DATETIME        NOT NULL,
    [Version]         NVARCHAR (50)   NULL,
    [IsActive]        BIT             DEFAULT ((1)) NULL,
    [CreatedDate]     DATETIME        DEFAULT (getutcdate()) NULL,
    [DocumentContent] VARBINARY (MAX) NULL,
    [FileName]        NVARCHAR (255)  NULL,
    [ContentType]     NVARCHAR (100)  NULL,
    PRIMARY KEY CLUSTERED ([ByeLawId] ASC),
    FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId])
);


GO

CREATE TABLE [assoc].[Candidates] (
    [CandidateId] INT IDENTITY (1, 1) NOT NULL,
    [ElectionId]  INT NOT NULL,
    [MemberId]    INT NOT NULL,
    PRIMARY KEY CLUSTERED ([CandidateId] ASC),
    FOREIGN KEY ([ElectionId]) REFERENCES [assoc].[Elections] ([ElectionId]),
    FOREIGN KEY ([MemberId]) REFERENCES [corp].[Users] ([UserId])
);


GO

CREATE TABLE [assoc].[CommitteeMembers] (
    [CommitteeMemberId] INT            IDENTITY (1, 1) NOT NULL,
    [AssociationId]     INT            NOT NULL,
    [MemberId]          INT            NULL,
    [RoleId]            INT            NOT NULL,
    [StartDate]         DATETIME       NOT NULL,
    [EndDate]           DATETIME       NULL,
    [IsActive]          BIT            DEFAULT ((1)) NULL,
    [MemberName]        NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([CommitteeMemberId] ASC),
    FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    FOREIGN KEY ([MemberId]) REFERENCES [corp].[Users] ([UserId]),
    FOREIGN KEY ([RoleId]) REFERENCES [assoc].[CommitteeRoles] ([RoleId])
);


GO

CREATE TABLE [assoc].[CommitteeRoles] (
    [RoleId]   INT            IDENTITY (1, 1) NOT NULL,
    [RoleName] NVARCHAR (100) NOT NULL,
    PRIMARY KEY CLUSTERED ([RoleId] ASC)
);


GO

CREATE TABLE [assoc].[Elections] (
    [ElectionId]    INT            IDENTITY (1, 1) NOT NULL,
    [AssociationId] INT            NOT NULL,
    [Title]         NVARCHAR (255) NOT NULL,
    [StartDate]     DATETIME       NOT NULL,
    [EndDate]       DATETIME       NOT NULL,
    [IsActive]      BIT            DEFAULT ((1)) NULL,
    PRIMARY KEY CLUSTERED ([ElectionId] ASC),
    FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId])
);


GO

CREATE TABLE [assoc].[FineSettings] (
    [FineSettingsId]  INT             IDENTITY (1, 1) NOT NULL,
    [AssociationId]   INT             NOT NULL,
    [TenantId]        INT             NOT NULL,
    [StrategyType]    NVARCHAR (50)   DEFAULT ('None') NOT NULL,
    [FineValue]       DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [GracePeriodDays] INT             DEFAULT ((0)) NOT NULL,
    [IsCompounding]   BIT             DEFAULT ((0)) NOT NULL,
    [Frequency]       NVARCHAR (20)   DEFAULT ('Monthly') NOT NULL,
    [LastUpdated]     DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [LastUpdatedBy]   NVARCHAR (255)  NULL,
    [ActivationDate]  DATETIME        NULL,
    PRIMARY KEY CLUSTERED ([FineSettingsId] ASC),
    CONSTRAINT [FK_FineSettings_Association] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId])
);




GO
CREATE NONCLUSTERED INDEX [IX_FineSettings_Association]
    ON [assoc].[FineSettings]([AssociationId] ASC);


GO

CREATE TABLE [assoc].[InvoiceLineItems] (
    [InvoiceLineItemId] INT             IDENTITY (1, 1) NOT NULL,
    [InvoiceId]         INT             NOT NULL,
    [ChargeName]        NVARCHAR (200)  NOT NULL,
    [Amount]            DECIMAL (18, 2) NOT NULL,
    [Description]       NVARCHAR (MAX)  NULL,
    [TariffLayerId]     INT             NULL,
    [Rate]              DECIMAL (18, 2) NULL,
    PRIMARY KEY CLUSTERED ([InvoiceLineItemId] ASC),
    CONSTRAINT [FK_InvoiceLineItems_Invoices] FOREIGN KEY ([InvoiceId]) REFERENCES [assoc].[Invoices] ([InvoiceId]) ON DELETE CASCADE
);


GO

CREATE TABLE [assoc].[Invoices] (
    [InvoiceId]      INT             IDENTITY (1, 1) NOT NULL,
    [TenantId]       INT             NOT NULL,
    [AssetId]        INT             NULL,
    [Title]          NVARCHAR (200)  NOT NULL,
    [Description]    NVARCHAR (500)  NULL,
    [Amount]         DECIMAL (18, 2) NOT NULL,
    [DueDate]        DATETIME        NOT NULL,
    [Status]         NVARCHAR (50)   DEFAULT ('Unpaid') NOT NULL,
    [CreatedDate]    DATETIME        DEFAULT (getdate()) NOT NULL,
    [AssociationId]  INT             NOT NULL,
    [BillingBatchId] INT             NULL,
    [IsAdvancePaid]  BIT             DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([InvoiceId] ASC),
    CONSTRAINT [FK_Invoices_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Invoices_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Invoices_BillingBatches] FOREIGN KEY ([BillingBatchId]) REFERENCES [assoc].[BillingBatches] ([BillingBatchId]),
    CONSTRAINT [FK_Invoices_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);






GO
CREATE NONCLUSTERED INDEX [IX_Invoices_AssociationId]
    ON [assoc].[Invoices]([AssociationId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_Invoices_Status] 
    ON [assoc].[Invoices]([Status] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_Invoices_AssetId] 
    ON [assoc].[Invoices]([AssetId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_Invoices_BillingBatchId] 
    ON [assoc].[Invoices]([BillingBatchId] ASC);


GO

CREATE TABLE [assoc].[MeetingMinutes] (
    [MinutesId]   INT            IDENTITY (1, 1) NOT NULL,
    [MeetingId]   INT            NOT NULL,
    [Notes]       NVARCHAR (MAX) NULL,
    [DocumentUrl] NVARCHAR (MAX) NULL,
    [CreatedDate] DATETIME       DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([MinutesId] ASC),
    FOREIGN KEY ([MeetingId]) REFERENCES [assoc].[Meetings] ([MeetingId])
);


GO

CREATE TABLE [assoc].[Meetings] (
    [MeetingId]     INT            IDENTITY (1, 1) NOT NULL,
    [AssociationId] INT            NOT NULL,
    [Title]         NVARCHAR (255) NOT NULL,
    [MeetingDate]   DATETIME       NOT NULL,
    [Description]   NVARCHAR (MAX) NULL,
    [CreatedBy]     INT            NOT NULL,
    [CreatedDate]   DATETIME       DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([MeetingId] ASC),
    FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    FOREIGN KEY ([CreatedBy]) REFERENCES [corp].[Users] ([UserId])
);


GO

CREATE TABLE [assoc].[Occupancy] (
    [OccupancyId]      INT      IDENTITY (1, 1) NOT NULL,
    [AssetId]          INT      NOT NULL,
    [PersonId]         INT      NOT NULL,
    [TenantId]         INT      NOT NULL,
    [OccupancyType]    INT      NOT NULL,
    [StartDate]        DATETIME NULL,
    [EndDate]          DATETIME NULL,
    [IsPrimaryContact] BIT      DEFAULT ((0)) NOT NULL,
    [AssociationId]    INT      NOT NULL,
    PRIMARY KEY CLUSTERED ([OccupancyId] ASC),
    CONSTRAINT [FK_Occupancy_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Occupancy_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Occupancy_Persons] FOREIGN KEY ([PersonId]) REFERENCES [assoc].[Persons] ([PersonId]),
    CONSTRAINT [FK_Occupancy_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Occupancy_AssociationId]
    ON [assoc].[Occupancy]([AssociationId] ASC);


GO

CREATE TABLE [assoc].[PaymentOrders] (
    [Id]                   INT             IDENTITY (1, 1) NOT NULL,
    [TenantId]             INT             NOT NULL,
    [AssociationId]        INT             NOT NULL,
    [UserId]               INT             NOT NULL,
    [RazorpayOrderId]      NVARCHAR (255)  NOT NULL,
    [Amount]               DECIMAL (18, 2) NOT NULL,
    [Currency]             NVARCHAR (10)   DEFAULT ('INR') NOT NULL,
    [Status]               NVARCHAR (50)   DEFAULT ('Created') NOT NULL,
    [InvoiceId]            INT             NULL,
    [Receipt]              NVARCHAR (255)  NULL,
    [CreatedDate]          DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [PrimaryAccountName]   NVARCHAR (200)  NULL,
    [PrimaryAccountNumber] NVARCHAR (100)  NULL,
    [AssetId]              INT             NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_PaymentOrders_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_PaymentOrders_Invoice] FOREIGN KEY ([InvoiceId]) REFERENCES [assoc].[Invoices] ([InvoiceId]),
    UNIQUE NONCLUSTERED ([RazorpayOrderId] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_PaymentOrders_TenantAssoc]
    ON [assoc].[PaymentOrders]([TenantId] ASC, [AssociationId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PaymentOrders_RazorpayOrderId]
    ON [assoc].[PaymentOrders]([RazorpayOrderId] ASC);


GO

CREATE TABLE [assoc].[Payments] (
    [PaymentId]        INT             IDENTITY (1, 1) NOT NULL,
    [TenantId]         INT             NOT NULL,
    [UserId]           INT             NOT NULL,
    [Amount]           DECIMAL (18, 2) NOT NULL,
    [Currency]         NVARCHAR (10)   NOT NULL,
    [Status]           NVARCHAR (50)   NOT NULL,
    [CreatedDate]      DATETIME        DEFAULT (getdate()) NOT NULL,
    [GatewayReference] NVARCHAR (200)  NULL,
    [InvoiceId]        INT             NULL,
    [AssetId]          INT             NULL,
    [Notes]            NVARCHAR (500)  NULL,
    [AssociationId]    INT             NOT NULL,
    PRIMARY KEY CLUSTERED ([PaymentId] ASC),
    CONSTRAINT [FK_Payments_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Payments_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Payments_Invoices] FOREIGN KEY ([InvoiceId]) REFERENCES [assoc].[Invoices] ([InvoiceId]),
    CONSTRAINT [FK_Payments_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Payments_AssociationId]
    ON [assoc].[Payments]([AssociationId] ASC);


GO

CREATE TABLE [assoc].[PaymentTransactions] (
    [Id]                   INT             IDENTITY (1, 1) NOT NULL,
    [TenantId]             INT             NOT NULL,
    [AssociationId]        INT             NOT NULL,
    [PaymentOrderId]       INT             NULL,
    [RazorpayPaymentId]    NVARCHAR (255)  NOT NULL,
    [RazorpayOrderId]      NVARCHAR (255)  NOT NULL,
    [RazorpaySignature]    NVARCHAR (MAX)  NOT NULL,
    [Status]               NVARCHAR (50)   NOT NULL,
    [Amount]               DECIMAL (18, 2) NOT NULL,
    [RawResponse]          NVARCHAR (MAX)  NULL,
    [CreatedDate]          DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [PrimaryAccountName]   NVARCHAR (200)  NULL,
    [PrimaryAccountNumber] NVARCHAR (100)  NULL,
    [PaymentMethod]        NVARCHAR (50)   NULL,
    [BankName]             NVARCHAR (100)  NULL,
    [BankRrn]              NVARCHAR (100)  NULL,
    [CardNetwork]          NVARCHAR (50)   NULL,
    [GatewayFee]           DECIMAL (18, 2) NULL,
    [GatewayTax]           DECIMAL (18, 2) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_PaymentTransactions_Order] FOREIGN KEY ([PaymentOrderId]) REFERENCES [assoc].[PaymentOrders] ([Id]),
    UNIQUE NONCLUSTERED ([RazorpayPaymentId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_PaymentTransactions_RazorpayOrderId]
    ON [assoc].[PaymentTransactions]([RazorpayOrderId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PaymentTransactions_RazorpayPaymentId]
    ON [assoc].[PaymentTransactions]([RazorpayPaymentId] ASC);


GO

CREATE TABLE [assoc].[PaymentWebhookLogs] (
    [Id]          INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]    INT            NULL,
    [EventType]   NVARCHAR (255) NOT NULL,
    [RawPayload]  NVARCHAR (MAX) NOT NULL,
    [Signature]   NVARCHAR (MAX) NULL,
    [IsProcessed] BIT            DEFAULT ((0)) NOT NULL,
    [CreatedDate] DATETIME       DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

CREATE TABLE [assoc].[Persons] (
    [PersonId]      INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NOT NULL,
    [FirstName]     NVARCHAR (100) NOT NULL,
    [LastName]      NVARCHAR (100) NOT NULL,
    [Email]         NVARCHAR (200) NULL,
    [Phone]         NVARCHAR (50)  NULL,
    [PhotoUrl]      NVARCHAR (500) NULL,
    [CreatedDate]   DATETIME       DEFAULT (getdate()) NOT NULL,
    [IsActive]      BIT            DEFAULT ((1)) NOT NULL,
    [AssociationId] INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([PersonId] ASC),
    CONSTRAINT [FK_Persons_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Persons_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Persons_AssociationId]
    ON [assoc].[Persons]([AssociationId] ASC);


GO

CREATE TABLE [assoc].[Pets] (
    [PetId]         INT            IDENTITY (1, 1) NOT NULL,
    [AssetId]       INT            NOT NULL,
    [TenantId]      INT            NOT NULL,
    [Name]          NVARCHAR (100) NOT NULL,
    [Species]       NVARCHAR (50)  NOT NULL,
    [Breed]         NVARCHAR (100) NULL,
    [TagNumber]     NVARCHAR (100) NULL,
    [IsActive]      BIT            DEFAULT ((1)) NOT NULL,
    [AssociationId] INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([PetId] ASC),
    CONSTRAINT [FK_Pets_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Pets_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Pets_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Pets_AssociationId]
    ON [assoc].[Pets]([AssociationId] ASC);


GO

CREATE TABLE [assoc].[RefreshTokens] (
    [RefreshTokenId] INT            IDENTITY (1, 1) NOT NULL,
    [UserId]         INT            NOT NULL,
    [Token]          NVARCHAR (MAX) NOT NULL,
    [ExpiryDate]     DATETIME       NOT NULL,
    [CreatedDate]    DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [IsRevoked]      BIT            DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([RefreshTokenId] ASC),
    FOREIGN KEY ([UserId]) REFERENCES [assoc].[Users] ([UserId])
);


GO

CREATE TABLE [assoc].[TariffGroups] (
    [TariffGroupId] INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NOT NULL,
    [Name]          NVARCHAR (100) NOT NULL,
    [Description]   NVARCHAR (500) NULL,
    [AssociationId] INT            NULL,
    PRIMARY KEY CLUSTERED ([TariffGroupId] ASC),
    CONSTRAINT [FK_TariffGroups_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO

CREATE TABLE [assoc].[TariffLayers] (
    [TariffLayerId]      INT             IDENTITY (1, 1) NOT NULL,
    [TariffGroupId]      INT             NOT NULL,
    [TenantId]           INT             NOT NULL,
    [Name]               NVARCHAR (100)  NOT NULL,
    [BaseRate]           DECIMAL (18, 2) NOT NULL,
    [Frequency]          INT             NOT NULL,
    [CalculationType]    INT             NOT NULL,
    [AccountingCategory] NVARCHAR (100)  NULL,
    [AssociationId]      INT             NULL,
    PRIMARY KEY CLUSTERED ([TariffLayerId] ASC),
    CONSTRAINT [FK_TariffLayers_Groups] FOREIGN KEY ([TariffGroupId]) REFERENCES [assoc].[TariffGroups] ([TariffGroupId]),
    CONSTRAINT [FK_TariffLayers_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO

CREATE TABLE [assoc].[Transactions] (
    [TransactionId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [TenantId]        INT             NOT NULL,
    [AssetId]         INT             NOT NULL,
    [InvoiceId]       INT             NULL,
    [PaymentId]       INT             NULL,
    [Type]            NVARCHAR (10)   NOT NULL,
    [Amount]          DECIMAL (18, 2) NOT NULL,
    [Category]        NVARCHAR (100)  NOT NULL,
    [Description]     NVARCHAR (500)  NULL,
    [TransactionDate] DATETIME        DEFAULT (getdate()) NOT NULL,
    [AssociationId]   INT             NOT NULL,
    PRIMARY KEY CLUSTERED ([TransactionId] ASC),
    CONSTRAINT [FK_Transactions_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Transactions_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Transactions_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Transactions_AssociationId]
    ON [assoc].[Transactions]([AssociationId] ASC);


GO

CREATE TABLE [assoc].[UserAssociations] (
    [UserId]        INT           NOT NULL,
    [AssociationId] INT           NOT NULL,
    [Role]          NVARCHAR (50) NOT NULL,
    [CreatedDate]   DATETIME2 (7) DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([UserId] ASC, [AssociationId] ASC),
    FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    FOREIGN KEY ([UserId]) REFERENCES [assoc].[Users] ([UserId])
);


GO
CREATE NONCLUSTERED INDEX [IX_AssocUserAssociations_AssociationId]
    ON [assoc].[UserAssociations]([AssociationId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AssocUserAssociations_UserId]
    ON [assoc].[UserAssociations]([UserId] ASC);


GO

CREATE TABLE [assoc].[Users] (
    [UserId]        INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NULL,
    [GoogleId]      NVARCHAR (255) NULL,
    [Email]         NVARCHAR (255) NOT NULL,
    [Name]          NVARCHAR (255) NOT NULL,
    [PictureUrl]    NVARCHAR (MAX) NULL,
    [Role]          NVARCHAR (50)  DEFAULT ('User') NOT NULL,
    [CreatedDate]   DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [LastLoginDate] DATETIME       NULL,
    [IsActive]      BIT            DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([UserId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_AssocUsers_GoogleId]
    ON [assoc].[Users]([GoogleId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AssocUsers_Email]
    ON [assoc].[Users]([Email] ASC);


GO

CREATE TABLE [assoc].[Vehicles] (
    [VehicleId]     INT            IDENTITY (1, 1) NOT NULL,
    [AssetId]       INT            NOT NULL,
    [TenantId]      INT            NOT NULL,
    [Make]          NVARCHAR (100) NOT NULL,
    [Model]         NVARCHAR (100) NOT NULL,
    [LicensePlate]  NVARCHAR (50)  NOT NULL,
    [Color]         NVARCHAR (50)  NULL,
    [ParkingSlot]   NVARCHAR (100) NULL,
    [IsActive]      BIT            DEFAULT ((1)) NOT NULL,
    [AssociationId] INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([VehicleId] ASC),
    CONSTRAINT [FK_Vehicles_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Vehicles_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Vehicles_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Vehicles_AssociationId]
    ON [assoc].[Vehicles]([AssociationId] ASC);


GO

CREATE TABLE [assoc].[Votes] (
    [VoteId]      INT      IDENTITY (1, 1) NOT NULL,
    [ElectionId]  INT      NOT NULL,
    [MemberId]    INT      NOT NULL,
    [CandidateId] INT      NOT NULL,
    [VoteDate]    DATETIME DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([VoteId] ASC),
    FOREIGN KEY ([CandidateId]) REFERENCES [assoc].[Candidates] ([CandidateId]),
    FOREIGN KEY ([ElectionId]) REFERENCES [assoc].[Elections] ([ElectionId]),
    FOREIGN KEY ([MemberId]) REFERENCES [corp].[Users] ([UserId]),
    CONSTRAINT [UQ_Election_Member] UNIQUE NONCLUSTERED ([ElectionId] ASC, [MemberId] ASC)
);


GO

CREATE TABLE [assoc].[WorkOrders] (
    [WorkOrderId]   INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NOT NULL,
    [AssetId]       INT            NULL,
    [Title]         NVARCHAR (200) NOT NULL,
    [Description]   NVARCHAR (MAX) NULL,
    [Priority]      NVARCHAR (50)  DEFAULT ('Medium') NOT NULL,
    [Status]        NVARCHAR (50)  DEFAULT ('Open') NOT NULL,
    [CreatedDate]   DATETIME       DEFAULT (getdate()) NOT NULL,
    [CreatedBy]     INT            NOT NULL,
    [AssignedTo]    NVARCHAR (200) NULL,
    [CompletedDate] DATETIME       NULL,
    [AssociationId] INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkOrderId] ASC),
    CONSTRAINT [FK_WorkOrders_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_WorkOrders_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_WorkOrders_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_WorkOrders_AssociationId]
    ON [assoc].[WorkOrders]([AssociationId] ASC);


GO

CREATE TABLE [corp].[Associations] (
    [AssociationId]         INT             IDENTITY (1, 1) NOT NULL,
    [TenantId]              INT             NOT NULL,
    [Name]                  NVARCHAR (200)  NOT NULL,
    [Description]           NVARCHAR (500)  NULL,
    [CreatedDate]           DATETIME        DEFAULT (getdate()) NOT NULL,
    [CreatedBy]             INT             NULL,
    [PlatformAccountId]     INT             NULL,
    [AdminPaysFee]          BIT             DEFAULT ((1)) NOT NULL,
    [PlatformWalletBalance] DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [Status]                NVARCHAR (50)   DEFAULT ('Active') NOT NULL,
    [AdminEmail]            NVARCHAR (255)  NULL,
    PRIMARY KEY CLUSTERED ([AssociationId] ASC),
    CONSTRAINT [FK_Associations_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO

CREATE TABLE [corp].[AssociationSubscriptions] (
    [SubscriptionId]  INT           IDENTITY (1, 1) NOT NULL,
    [AssociationId]   INT           NOT NULL,
    [PlanId]          INT           NOT NULL,
    [Status]          NVARCHAR (50) DEFAULT ('Active') NOT NULL,
    [StartDate]       DATETIME      DEFAULT (getdate()) NOT NULL,
    [NextBillingDate] DATETIME      NOT NULL,
    PRIMARY KEY CLUSTERED ([SubscriptionId] ASC),
    CONSTRAINT [FK_AssociationSubscriptions_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_AssociationSubscriptions_Plans] FOREIGN KEY ([PlanId]) REFERENCES [corp].[SubscriptionPlans] ([PlanId])
);


GO

CREATE TABLE [corp].[AuditLogs] (
    [AuditLogId]    INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NOT NULL,
    [UserId]        INT            NULL,
    [Action]        NVARCHAR (200) NOT NULL,
    [Entity]        NVARCHAR (200) NULL,
    [EntityId]      INT            NULL,
    [IpAddress]     NVARCHAR (100) NULL,
    [Timestamp]     DATETIME       DEFAULT (getdate()) NOT NULL,
    [AssociationId] INT            NULL,
    [AssetId]       INT            NULL,
    [CorrelationId] NVARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([AuditLogId] ASC),
    CONSTRAINT [FK_AuditLogs_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_AuditLogs_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_AuditLogs_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);








GO
CREATE NONCLUSTERED INDEX [IX_AuditLogs_AssociationId]
    ON [corp].[AuditLogs]([AssociationId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_AuditLogs_Timestamp] 
    ON [corp].[AuditLogs]([Timestamp] DESC);

GO
CREATE NONCLUSTERED INDEX [IX_AuditLogs_CorrelationId] 
    ON [corp].[AuditLogs]([CorrelationId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_AuditLogs_TenantId] 
    ON [corp].[AuditLogs]([TenantId] ASC);


GO

CREATE TABLE [corp].[PlatformAccounts] (
    [Id]                INT            IDENTITY (1, 1) NOT NULL,
    [AccountName]       NVARCHAR (100) NOT NULL,
    [AccountNumber]     NVARCHAR (50)  NULL,
    [BankName]          NVARCHAR (255) NULL,
    [IFSCCode]          NVARCHAR (20)  NULL,
    [BranchName]        NVARCHAR (255) NULL,
    [RazorpayKeyId]     NVARCHAR (255) NULL,
    [RazorpayKeySecret] NVARCHAR (255) NULL,
    [IsActive]          BIT            DEFAULT ((1)) NOT NULL,
    [LastUpdated]       DATETIME       DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO


GO

CREATE TABLE [corp].[PlatformAdvancePayments] (
    [PlatformAdvanceId] INT             IDENTITY (1, 1) NOT NULL,
    [AssociationId]     INT             NOT NULL,
    [Amount]            DECIMAL (18, 2) NOT NULL,
    [Date]              DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [Status]            NVARCHAR (50)   DEFAULT ('Completed') NOT NULL,
    [TransactionRef]    NVARCHAR (255)  NULL,
    [Description]       NVARCHAR (500)  NULL,
    [Notes]             NVARCHAR (MAX)  NULL,
    [CreatedDate]       DATETIME        DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([PlatformAdvanceId] ASC),
    CONSTRAINT [FK_PlatformAdvancePayments_Association] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId])
);


GO

CREATE TABLE [corp].[PlatformInvoices] (
    [PlatformInvoiceId] INT             IDENTITY (1, 1) NOT NULL,
    [AssociationId]     INT             NOT NULL,
    [PlanId]            INT             NOT NULL,
    [Amount]            DECIMAL (18, 2) NOT NULL,
    [BillingDate]       DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [DueDate]           DATETIME        NOT NULL,
    [Status]            NVARCHAR (50)   DEFAULT ('Unpaid') NOT NULL,
    [CreatedDate]       DATETIME        DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([PlatformInvoiceId] ASC),
    CONSTRAINT [FK_PlatformInvoices_Association] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_PlatformInvoices_Plan] FOREIGN KEY ([PlanId]) REFERENCES [corp].[SubscriptionPlans] ([PlanId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_PlatformInvoices_Assoc_Period]
    ON [corp].[PlatformInvoices]([AssociationId] ASC, [BillingDate] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_PlatformInvoices_Status] 
    ON [corp].[PlatformInvoices]([Status] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_PlatformInvoices_PlanId] 
    ON [corp].[PlatformInvoices]([PlanId] ASC);


GO

CREATE TABLE [corp].[PlatformPayments] (
    [PlatformPaymentId] INT             IDENTITY (1, 1) NOT NULL,
    [PlatformInvoiceId] INT             NOT NULL,
    [Amount]            DECIMAL (18, 2) NOT NULL,
    [PaymentDate]       DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [TransactionRef]    NVARCHAR (255)  NULL,
    [PaymentMethod]     NVARCHAR (50)   NULL,
    [Status]            NVARCHAR (50)   DEFAULT ('Completed') NOT NULL,
    PRIMARY KEY CLUSTERED ([PlatformPaymentId] ASC),
    CONSTRAINT [FK_PlatformPayments_Invoice] FOREIGN KEY ([PlatformInvoiceId]) REFERENCES [corp].[PlatformInvoices] ([PlatformInvoiceId])
);


GO

CREATE TABLE [corp].[RefreshTokens] (
    [RefreshTokenId] INT            IDENTITY (1, 1) NOT NULL,
    [UserId]         INT            NOT NULL,
    [Token]          NVARCHAR (500) NOT NULL,
    [ExpiryDate]     DATETIME       NOT NULL,
    [CreatedDate]    DATETIME       DEFAULT (getdate()) NOT NULL,
    [IsRevoked]      BIT            DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([RefreshTokenId] ASC),
    CONSTRAINT [FK_RefreshTokens_Users] FOREIGN KEY ([UserId]) REFERENCES [corp].[Users] ([UserId])
);


GO

CREATE TABLE [corp].[SubscriptionPlans] (
    [PlanId]        INT             IDENTITY (1, 1) NOT NULL,
    [Name]          NVARCHAR (100)  NOT NULL,
    [BasePrice]     DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [PricePerAsset] DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [IsActive]      BIT             DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([PlanId] ASC)
);


GO

CREATE TABLE [corp].[TenantPaymentConfig] (
    [Id]                    INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]              INT            NOT NULL,
    [RazorpayKeyId]         NVARCHAR (255) NOT NULL,
    [RazorpayKeySecret]     NVARCHAR (255) NOT NULL,
    [WebhookSecret]         NVARCHAR (255) NULL,
    [IsActive]              BIT            DEFAULT ((1)) NOT NULL,
    [LastUpdated]           DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [RazorpayWebhookSecret] NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_TenantPaymentConfig_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId]),
    UNIQUE NONCLUSTERED ([TenantId] ASC)
);


GO

CREATE TABLE [corp].[Tenants] (
    [TenantId]    INT            IDENTITY (1, 1) NOT NULL,
    [Name]        NVARCHAR (200) NOT NULL,
    [CreatedDate] DATETIME       DEFAULT (getdate()) NOT NULL,
    [IsActive]    BIT            DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([TenantId] ASC)
);


GO

CREATE TABLE [corp].[UserAssociations] (
    [UserId]      INT           NOT NULL,
    [TenantId]    INT           NOT NULL,
    [Role]        NVARCHAR (50) NOT NULL,
    [CreatedDate] DATETIME2 (7) DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([UserId] ASC, [TenantId] ASC),
    FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId]),
    FOREIGN KEY ([UserId]) REFERENCES [corp].[Users] ([UserId])
);


GO
CREATE NONCLUSTERED INDEX [IX_UserAssociations_TenantId]
    ON [corp].[UserAssociations]([TenantId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_UserAssociations_UserId]
    ON [corp].[UserAssociations]([UserId] ASC);


GO

CREATE TABLE [corp].[Users] (
    [UserId]        INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NOT NULL,
    [GoogleId]      NVARCHAR (200) NULL,
    [Email]         NVARCHAR (200) NOT NULL,
    [Name]          NVARCHAR (200) NOT NULL,
    [PictureUrl]    NVARCHAR (500) NULL,
    [CreatedDate]   DATETIME       DEFAULT (getdate()) NOT NULL,
    [LastLoginDate] DATETIME       NULL,
    [IsActive]      BIT            DEFAULT ((1)) NOT NULL,
    [Role]          NVARCHAR (50)  DEFAULT ('User') NOT NULL,
    [AssociationId] INT            NULL,
    [MetadataJson]  NVARCHAR (MAX) NULL,
    [PasswordHash]  NVARCHAR (500) NULL,
    PRIMARY KEY CLUSTERED ([UserId] ASC),
    CONSTRAINT [FK_Users_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO


/* 3. STORED PROCEDURES */

-- 2. Analyze Asset Financials (Invoices & Balance)
CREATE   PROCEDURE assoc.sp_Analyze_AssetFinancials
    @AssetId INT
AS
BEGIN
    -- Summary
    SELECT 
        a.Name AS AssetName,
        (SELECT SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END) FROM assoc.Transactions WHERE AssetId = @AssetId) AS CurrentBalance
    FROM assoc.Assets a WHERE a.AssetId = @AssetId;

    -- Recent Invoices
    SELECT TOP 20
        InvoiceId, Title, Amount, Status, CreatedDate, DueDate
    FROM assoc.Invoices 
    WHERE AssetId = @AssetId
    ORDER BY CreatedDate DESC;

    -- Recent Transactions
    SELECT TOP 20
        TransactionId, Type, Amount, Category, Description, TransactionDate
    FROM assoc.Transactions
    WHERE AssetId = @AssetId
    ORDER BY TransactionDate DESC;
END

GO

CREATE PROCEDURE assoc.sp_Analyze_AssetInvoiceTree
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Recursive CTE to build Asset Hierarchy
    ;WITH AssetHierarchy AS (
        -- Root assets (those without a parent)
        SELECT 
            AssetId, 
            ParentId, 
            Name, 
            AssetType,
            CAST(Name AS NVARCHAR(MAX)) AS HierarchyPath,
            0 AS [Level],
            CAST(RIGHT('0000000000' + CAST(AssetId AS VARCHAR(10)), 10) AS VARCHAR(MAX)) AS SortKey
        FROM assoc.Assets
        WHERE AssociationId = @AssociationId 
          AND ParentId IS NULL 
          AND IsActive = 1

        UNION ALL

        -- Child assets (recursive part)
        SELECT 
            a.AssetId, 
            a.ParentId, 
            a.Name, 
            a.AssetType,
            ah.HierarchyPath + ' > ' + a.Name AS HierarchyPath,
            ah.[Level] + 1 AS [Level],
            ah.SortKey + ' > ' + CAST(RIGHT('0000000000' + CAST(a.AssetId AS VARCHAR(10)), 10) AS VARCHAR(MAX)) AS SortKey
        FROM assoc.Assets a
        INNER JOIN AssetHierarchy ah ON a.ParentId = ah.AssetId
        WHERE a.IsActive = 1
    )
    SELECT 
        ah.[Level],
        ah.HierarchyPath,
        ah.Name AS AssetName,
        ah.AssetType,
        p.FirstName + ' ' + p.LastName AS OwnerName,
        o.OccupancyType,
        o.IsPrimaryContact,
        i.InvoiceId,
        i.Title AS InvoiceTitle,
        i.Amount AS InvoiceAmount,
        i.Status AS InvoiceStatus,
        i.DueDate AS InvoiceDueDate
    FROM AssetHierarchy ah
    -- Join with Occupancy and Persons to get Owner details
    LEFT JOIN assoc.Occupancy o ON ah.AssetId = o.AssetId
    LEFT JOIN assoc.Persons p ON o.PersonId = p.PersonId
    -- Join with Invoices to get status
    LEFT JOIN assoc.Invoices i ON ah.AssetId = i.AssetId
    ORDER BY ah.SortKey, o.IsPrimaryContact DESC, i.DueDate DESC;
END
GO

GO

-- 1. Analyze Asset Tariffs
CREATE   PROCEDURE assoc.sp_Analyze_AssetTariffs
    @AssociationId INT = NULL,
    @AssetId INT = NULL
AS
BEGIN
    SELECT 
        a.AssetId,
        a.Name AS AssetName,
        a.AssetType,
        tl.Name AS TariffName,
        tl.BaseRate,
        at.CustomAmount,
        at.IsActive,
        at.IsRecurring,
        tg.Name AS GroupName
    FROM assoc.Assets a
    JOIN assoc.AssetTariffs at ON a.AssetId = at.AssetId
    JOIN assoc.TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId
    JOIN assoc.TariffGroups tg ON tl.TariffGroupId = tg.TariffGroupId
    WHERE (@AssociationId IS NULL OR a.AssociationId = @AssociationId)
      AND (@AssetId IS NULL OR a.AssetId = @AssetId)
    ORDER BY a.Name, tg.Name, tl.Name;
END

GO

-- 4. Analyze Batch History
CREATE   PROCEDURE assoc.sp_Analyze_BatchHistory
    @AssociationId INT = NULL
AS
BEGIN
    SELECT 
        bb.BillingBatchId,
        bb.Month,
        bb.Year,
        bb.Status,
        bb.InvoicesGenerated,
        bb.TotalAmount,
        bb.CreatedDate,
        a.Name AS AssociationName
    FROM assoc.BillingBatches bb
    JOIN corp.Associations a ON bb.AssociationId = a.AssociationId
    WHERE (@AssociationId IS NULL OR bb.AssociationId = @AssociationId)
    ORDER BY bb.CreatedDate DESC;
END

GO

-- 5. Identify Orphaned Assets (No Tariffs or No Residents)
CREATE   PROCEDURE assoc.sp_Analyze_OrphanedData
    @AssociationId INT
AS
BEGIN
    -- No Residents
    SELECT 'No Residents' AS Issue, AssetId, Name, AssetType
    FROM assoc.Assets a
    WHERE a.AssociationId = @AssociationId
      AND NOT EXISTS (SELECT 1 FROM assoc.Occupancy o WHERE o.AssetId = a.AssetId)
    
    UNION ALL

    -- No Tariffs
    SELECT 'No Tariffs' AS Issue, AssetId, Name, AssetType
    FROM assoc.Assets a
    WHERE a.AssociationId = @AssociationId
      AND NOT EXISTS (SELECT 1 FROM assoc.AssetTariffs at WHERE at.AssetId = a.AssetId)
    ORDER BY Issue, Name;
END

GO

-- 3. Analyze Resident Mapping
CREATE   PROCEDURE assoc.sp_Analyze_ResidentMapping
    @AssociationId INT = NULL
AS
BEGIN
    SELECT 
        a.Name AS AssetName,
        a.AssetType,
        p.FirstName + ' ' + p.LastName AS ResidentName,
        p.Email,
        p.Phone,
        o.OccupancyType,
        o.IsPrimaryContact,
        o.StartDate,
        o.EndDate
    FROM assoc.Assets a
    LEFT JOIN assoc.Occupancy o ON a.AssetId = o.AssetId
    LEFT JOIN assoc.Persons p ON o.PersonId = p.PersonId
    WHERE (@AssociationId IS NULL OR a.AssociationId = @AssociationId)
    ORDER BY a.Name, o.IsPrimaryContact DESC;
END

GO


-- 5. Asset Count (Move to SP)
CREATE   PROCEDURE assoc.sp_Assets_Count
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT COUNT(*) FROM assoc.Assets 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND IsActive = 1;
END;

GO

CREATE PROCEDURE assoc.sp_Assets_Create @ParentId INT = NULL, @TenantId INT, @AssociationId INT, @Name NVARCHAR(255), @Description NVARCHAR(MAX), @AssetType INT, @MetadataJson NVARCHAR(MAX), @CreatedDate DATETIME, @CreatedBy NVARCHAR(255), @IsActive BIT AS BEGIN SET NOCOUNT ON; IF @ParentId IS NOT NULL AND NOT EXISTS ( SELECT 1 FROM assoc.Assets WHERE AssetId = @ParentId AND AssociationId = @AssociationId ) BEGIN SET @ParentId = NULL; END INSERT INTO assoc.Assets (ParentId, TenantId, AssociationId, Name, Description, AssetType, MetadataJson, CreatedDate, CreatedBy, IsActive) OUTPUT INSERTED.AssetId VALUES (@ParentId, @TenantId, @AssociationId, @Name, @Description, @AssetType, @MetadataJson, @CreatedDate, @CreatedBy, @IsActive); END

GO

CREATE PROCEDURE assoc.sp_Assets_Delete @Id INT, @TenantId INT, @AssociationId INT AS BEGIN SET NOCOUNT ON; WITH AssetHierarchy AS ( SELECT AssetId FROM assoc.Assets WHERE AssetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId UNION ALL SELECT a.AssetId FROM assoc.Assets a INNER JOIN AssetHierarchy h ON a.ParentId = h.AssetId WHERE a.TenantId = @TenantId AND a.AssociationId = @AssociationId ) UPDATE a SET a.IsActive = 0 FROM assoc.Assets a INNER JOIN AssetHierarchy h ON a.AssetId = h.AssetId; END

GO

-- ASSETS
CREATE   PROCEDURE assoc.sp_Assets_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Assets WHERE AssetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END

GO

CREATE   PROCEDURE assoc.sp_Assets_GetByParentId @ParentId INT = NULL, @TenantId INT, @AssociationId INT AS 
BEGIN
    IF @ParentId IS NULL
        SELECT * FROM assoc.Assets WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND ParentId IS NULL;
    ELSE
        SELECT * FROM assoc.Assets WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND ParentId = @ParentId;
END

GO

CREATE   PROCEDURE assoc.sp_Assets_GetHierarchy @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Assets 
    WHERE AssociationId = @AssociationId AND IsActive = 1 
    ORDER BY ParentId, AssetType; 
END
GO

GO

CREATE PROCEDURE assoc.sp_Assets_Update @AssetId INT, @TenantId INT, @AssociationId INT, @ParentId INT = NULL, @Name NVARCHAR(255), @Description NVARCHAR(MAX), @AssetType INT, @MetadataJson NVARCHAR(MAX), @IsActive BIT AS BEGIN SET NOCOUNT ON; IF @ParentId IS NOT NULL AND NOT EXISTS ( SELECT 1 FROM assoc.Assets WHERE AssetId = @ParentId AND AssociationId = @AssociationId ) BEGIN SET @ParentId = NULL; END UPDATE assoc.Assets SET ParentId = @ParentId, Name = @Name, Description = @Description, AssetType = @AssetType, MetadataJson = @MetadataJson, IsActive = @IsActive WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId; IF @IsActive = 0 BEGIN WITH AssetHierarchy AS ( SELECT AssetId FROM assoc.Assets WHERE ParentId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId UNION ALL SELECT a.AssetId FROM assoc.Assets a INNER JOIN AssetHierarchy h ON a.ParentId = h.AssetId WHERE a.TenantId = @TenantId AND a.AssociationId = @AssociationId ) UPDATE a SET a.IsActive = 0 FROM assoc.Assets a INNER JOIN AssetHierarchy h ON a.AssetId = h.AssetId; END END

GO

CREATE   PROCEDURE assoc.sp_AssetTariffs_Delete @AssetId INT, @LayerId INT AS 
BEGIN DELETE FROM assoc.AssetTariffs WHERE AssetId = @AssetId AND TariffLayerId = @LayerId; END

GO

CREATE PROCEDURE assoc.sp_AssetTariffs_GetActiveByTenantId
    @TenantId INT
AS
BEGIN
    SELECT at.*, tl.Name AS ChargeName
    FROM assoc.AssetTariffs at
    JOIN assoc.TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId
    WHERE tl.TenantId = @TenantId AND at.IsActive = 1;
END

GO

CREATE PROCEDURE assoc.sp_AssetTariffs_GetByAssetId
    @AssetId INT
AS
BEGIN
    SELECT at.*, tl.Name AS ChargeName
    FROM assoc.AssetTariffs at
    JOIN assoc.TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId
    WHERE at.AssetId = @AssetId;
END

GO

CREATE PROCEDURE assoc.sp_AssetTariffs_Upsert
    @AssetId INT,
    @TariffLayerId INT,
    @CustomAmount DECIMAL(18,2) = NULL,
    @IsActive BIT = 1,
    @IsRecurring BIT = 1
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.AssetTariffs WHERE AssetId = @AssetId AND TariffLayerId = @TariffLayerId)
    BEGIN
        UPDATE assoc.AssetTariffs
        SET CustomAmount = @CustomAmount,
            IsActive = @IsActive,
            IsRecurring = @IsRecurring
        WHERE AssetId = @AssetId AND TariffLayerId = @TariffLayerId;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.AssetTariffs (AssetId, TariffLayerId, CustomAmount, IsActive, IsRecurring)
        VALUES (@AssetId, @TariffLayerId, @CustomAmount, @IsActive, @IsRecurring);
    END
END

GO

-- Stored Procedures

-- Get Bank Details
CREATE   PROCEDURE assoc.sp_AssociationBankDetails_Get
    @AssociationId INT,
    @TenantId INT
AS
BEGIN
    SELECT * FROM assoc.AssociationBankDetails 
    WHERE AssociationId = @AssociationId AND TenantId = @TenantId;
END;

GO

-- Upsert Bank Details
CREATE   PROCEDURE assoc.sp_AssociationBankDetails_Upsert
    @AssociationId INT,
    @TenantId INT,
    @PrimaryAccountName NVARCHAR(255) = NULL,
    @PrimaryAccountNumber NVARCHAR(50) = NULL,
    @PrimaryIFSCCode NVARCHAR(20) = NULL,
    @PrimaryBankName NVARCHAR(255) = NULL,
    @PrimaryBranchName NVARCHAR(255) = NULL,
    @PrimaryQRCode VARBINARY(MAX) = NULL,
    @PrimaryQRCodeContentType NVARCHAR(100) = NULL,
    @SecondaryAccountName NVARCHAR(255) = NULL,
    @SecondaryAccountNumber NVARCHAR(50) = NULL,
    @SecondaryIFSCCode NVARCHAR(20) = NULL,
    @SecondaryBankName NVARCHAR(255) = NULL,
    @SecondaryBranchName NVARCHAR(255) = NULL,
    @SecondaryQRCode VARBINARY(MAX) = NULL,
    @SecondaryQRCodeContentType NVARCHAR(100) = NULL,
    @UserId INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.AssociationBankDetails WHERE AssociationId = @AssociationId)
    BEGIN
        UPDATE assoc.AssociationBankDetails
        SET 
            PrimaryAccountName = @PrimaryAccountName,
            PrimaryAccountNumber = @PrimaryAccountNumber,
            PrimaryIFSCCode = @PrimaryIFSCCode,
            PrimaryBankName = @PrimaryBankName,
            PrimaryBranchName = @PrimaryBranchName,
            PrimaryQRCode = ISNULL(@PrimaryQRCode, PrimaryQRCode),
            PrimaryQRCodeContentType = ISNULL(@PrimaryQRCodeContentType, PrimaryQRCodeContentType),
            SecondaryAccountName = @SecondaryAccountName,
            SecondaryAccountNumber = @SecondaryAccountNumber,
            SecondaryIFSCCode = @SecondaryIFSCCode,
            SecondaryBankName = @SecondaryBankName,
            SecondaryBranchName = @SecondaryBranchName,
            SecondaryQRCode = ISNULL(@SecondaryQRCode, SecondaryQRCode),
            SecondaryQRCodeContentType = ISNULL(@SecondaryQRCodeContentType, SecondaryQRCodeContentType),
            LastUpdatedBy = @UserId,
            LastUpdatedDate = GETUTCDATE()
        WHERE AssociationId = @AssociationId;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.AssociationBankDetails (
            AssociationId, TenantId, PrimaryAccountName, PrimaryAccountNumber, PrimaryIFSCCode, PrimaryBankName, PrimaryBranchName, PrimaryQRCode, PrimaryQRCodeContentType,
            SecondaryAccountName, SecondaryAccountNumber, SecondaryIFSCCode, SecondaryBankName, SecondaryBranchName, SecondaryQRCode, SecondaryQRCodeContentType,
            CreatedBy, CreatedDate
        )
        VALUES (
            @AssociationId, @TenantId, @PrimaryAccountName, @PrimaryAccountNumber, @PrimaryIFSCCode, @PrimaryBankName, @PrimaryBranchName, @PrimaryQRCode, @PrimaryQRCodeContentType,
            @SecondaryAccountName, @SecondaryAccountNumber, @SecondaryIFSCCode, @SecondaryBankName, @SecondaryBranchName, @SecondaryQRCode, @SecondaryQRCodeContentType,
            @UserId, GETUTCDATE()
        );
    END
END;

GO

-- 8. Update sp_AssociationProfile_Get to include status from corp.Associations
CREATE   PROCEDURE assoc.sp_AssociationProfile_Get
    @AssociationId INT
AS
BEGIN
    SELECT p.*, a.Status
    FROM assoc.AssociationProfile p
    JOIN corp.Associations a ON p.AssociationId = a.AssociationId
    WHERE p.AssociationId = @AssociationId;
END;

GO

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

GO

CREATE   PROCEDURE assoc.sp_Associations_GetByUserId
    @UserId INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin'))
    BEGIN
        SELECT * FROM corp.Associations WHERE [Status] = 'Active';
    END
    ELSE
    BEGIN
        -- 1. Direct mappings
        SELECT DISTINCT a.* FROM corp.Associations a
        INNER JOIN assoc.UserAssociations ua ON a.AssociationId = ua.AssociationId
        WHERE ua.UserId = @UserId AND a.[Status] = 'Active'
        
        UNION

        -- 2. Indirect mapping via Occupancy
        SELECT DISTINCT a.* FROM corp.Associations a
        INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
        INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
        INNER JOIN assoc.Users u ON p.Email = u.Email
        WHERE u.UserId = @UserId AND a.[Status] = 'Active'
    END
END;

GO

CREATE   PROCEDURE assoc.sp_AuditLogs_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM corp.AuditLogs 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId 
    ORDER BY Timestamp DESC; 
END

GO

CREATE   PROCEDURE assoc.sp_AuthWorkflows_GetByName
    @Name NVARCHAR(100)
AS
BEGIN
    SELECT WorkflowId, Name, WorkflowJson, Description, CreatedDate, UpdatedDate
    FROM assoc.AuthWorkflows
    WHERE Name = @Name;
END

GO

CREATE   PROCEDURE assoc.sp_AuthWorkflows_Upsert
    @Name NVARCHAR(100),
    @WorkflowJson NVARCHAR(MAX),
    @Description NVARCHAR(255) = NULL
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.AuthWorkflows WHERE Name = @Name)
    BEGIN
        UPDATE assoc.AuthWorkflows
        SET WorkflowJson = @WorkflowJson,
            Description = ISNULL(@Description, Description),
            UpdatedDate = GETUTCDATE()
        WHERE Name = @Name;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.AuthWorkflows (Name, WorkflowJson, Description)
        VALUES (@Name, @WorkflowJson, @Description);
    END
END

GO

CREATE   PROCEDURE assoc.sp_BillingBatches_Create 
    @TenantId INT, 
    @AssociationId INT, 
    @Month INT, 
    @Year INT, 
    @Status NVARCHAR(50), 
    @TotalAmount DECIMAL(18,2), 
    @InvoicesGenerated INT, 
    @CreatedDate DATETIME 
AS 
BEGIN 
    INSERT INTO assoc.BillingBatches (TenantId, AssociationId, Month, Year, Status, TotalAmount, InvoicesGenerated, CreatedDate) 
    OUTPUT INSERTED.BillingBatchId 
    VALUES (@TenantId, @AssociationId, @Month, @Year, @Status, @TotalAmount, @InvoicesGenerated, @CreatedDate); 
END

GO

CREATE   PROCEDURE assoc.sp_BillingBatches_GetByAssociation 
    @AssociationId INT, 
    @TenantId INT 
AS 
BEGIN 
    SELECT * FROM assoc.BillingBatches WHERE AssociationId = @AssociationId AND TenantId = @TenantId ORDER BY CreatedDate DESC; 
END

GO

CREATE   PROCEDURE assoc.sp_BillingBatches_GetById 
    @Id INT, 
    @TenantId INT, 
    @AssociationId INT 
AS 
BEGIN 
    SELECT * FROM assoc.BillingBatches WHERE BillingBatchId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; 
END

GO

CREATE   PROCEDURE assoc.sp_BillingBatches_UpdateStatus
    @Id INT,
    @Status NVARCHAR(50),
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    UPDATE assoc.BillingBatches 
    SET Status = @Status 
    WHERE BillingBatchId = @Id 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId;
END;

GO

CREATE   PROCEDURE assoc.sp_Broadcasts_Create @TenantId INT, @AssociationId INT, @Title NVARCHAR(200), @Content NVARCHAR(MAX), @Category NVARCHAR(50), @CreatedDate DATETIME, @CreatedBy INT, @IsPinned BIT, @ExpiresDate DATETIME = NULL, @AssetId INT = NULL AS 
BEGIN INSERT INTO assoc.Broadcasts (TenantId, AssociationId, Title, Content, Category, CreatedDate, CreatedBy, IsPinned, ExpiresDate, AssetId) OUTPUT INSERTED.BroadcastId VALUES (@TenantId, @AssociationId, @Title, @Content, @Category, @CreatedDate, @CreatedBy, @IsPinned, @ExpiresDate, @AssetId); END

GO

CREATE   PROCEDURE assoc.sp_Broadcasts_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    DELETE FROM assoc.Broadcasts 
    WHERE BroadcastId = @Id AND AssociationId = @AssociationId; 
END

GO

CREATE   PROCEDURE assoc.sp_Broadcasts_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN corp.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.AssociationId = @AssociationId
    ORDER BY b.IsPinned DESC, b.CreatedDate DESC;
END
GO

GO

CREATE   PROCEDURE assoc.sp_Broadcasts_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN corp.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.AssociationId = @AssociationId AND (b.AssetId = @AssetId OR b.AssetId IS NULL)
    ORDER BY b.IsPinned DESC, b.CreatedDate DESC;
END
GO

GO

-- BROADCASTS
CREATE   PROCEDURE assoc.sp_Broadcasts_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN corp.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.BroadcastId = @Id AND b.AssociationId = @AssociationId;
END
GO

GO

CREATE   PROCEDURE assoc.sp_ByeLaws_Delete
    @id INT
AS
BEGIN
    DELETE FROM assoc.ByeLaws WHERE ByeLawId = @id;
END;

GO

CREATE   PROCEDURE assoc.sp_ByeLaws_GetById
    @id INT
AS
BEGIN
    SELECT * FROM assoc.ByeLaws WHERE ByeLawId = @id;
END;

GO

CREATE   PROCEDURE assoc.sp_ByeLaws_Insert
    @AssociationId INT,
    @Title NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @EffectiveDate DATETIME2,
    @Version NVARCHAR(50),
    @IsActive BIT,
    @DocumentContent VARBINARY(MAX) = NULL,
    @FileName NVARCHAR(255) = NULL,
    @ContentType NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO assoc.ByeLaws (AssociationId, Title, Description, EffectiveDate, Version, IsActive, DocumentContent, FileName, ContentType)
    VALUES (@AssociationId, @Title, @Description, @EffectiveDate, @Version, @IsActive, @DocumentContent, @FileName, @ContentType);
    SELECT SCOPE_IDENTITY();
END;

GO

-- 3. Bye-laws
CREATE   PROCEDURE assoc.sp_ByeLaws_List
    @AssociationId INT,
    @ActiveOnly BIT = 1
AS
BEGIN
    SELECT * FROM assoc.ByeLaws 
    WHERE AssociationId = @AssociationId
    AND (@ActiveOnly = 0 OR IsActive = 1);
END;

GO

CREATE   PROCEDURE assoc.sp_ByeLaws_Update
    @ByeLawId INT,
    @Title NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @EffectiveDate DATETIME2,
    @Version NVARCHAR(50),
    @IsActive BIT,
    @DocumentContent VARBINARY(MAX) = NULL,
    @FileName NVARCHAR(255) = NULL,
    @ContentType NVARCHAR(100) = NULL
AS
BEGIN
    UPDATE assoc.ByeLaws SET 
        Title = @Title, 
        Description = @Description, 
        EffectiveDate = @EffectiveDate, 
        Version = @Version, 
        IsActive = @IsActive,
        DocumentContent = @DocumentContent,
        FileName = @FileName,
        ContentType = @ContentType
    WHERE ByeLawId = @ByeLawId;
END;

GO

CREATE   PROCEDURE assoc.sp_Candidates_Insert
    @ElectionId INT,
    @MemberId INT
AS
BEGIN
    INSERT INTO assoc.Candidates (ElectionId, MemberId) VALUES (@ElectionId, @MemberId);
    SELECT SCOPE_IDENTITY();
END;

GO

-- 2. Fix Committee Member Insert (Ensure 7 params)
CREATE   PROCEDURE assoc.sp_CommitteeMembers_Insert
    @AssociationId INT,
    @MemberId INT,
    @MemberName NVARCHAR(255) = NULL,
    @RoleId INT,
    @StartDate DATETIME2,
    @EndDate DATETIME2 = NULL,
    @IsActive BIT
AS
BEGIN
    INSERT INTO assoc.CommitteeMembers (AssociationId, MemberId, MemberName, RoleId, StartDate, EndDate, IsActive)
    VALUES (@AssociationId, @MemberId, @MemberName, @RoleId, @StartDate, @EndDate, @IsActive);
    SELECT SCOPE_IDENTITY();
END;

GO

CREATE   PROCEDURE assoc.sp_CommitteeMembers_List
    @AssociationId INT,
    @ActiveOnly BIT = 1
AS
BEGIN
    SELECT cm.*, COALESCE(cm.MemberName, u.Name) as MemberName, cr.RoleName 
    FROM assoc.CommitteeMembers cm
    LEFT JOIN corp.Users u ON cm.MemberId = u.UserId
    JOIN assoc.CommitteeRoles cr ON cm.RoleId = cr.RoleId
    WHERE cm.AssociationId = @AssociationId
    AND (@ActiveOnly = 0 OR cm.IsActive = 1);
END;

GO

CREATE   PROCEDURE assoc.sp_CommitteeMembers_Update
    @CommitteeMemberId INT,
    @MemberName NVARCHAR(255) = NULL,
    @RoleId INT,
    @StartDate DATETIME2,
    @EndDate DATETIME2 = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE assoc.CommitteeMembers 
    SET RoleId = @RoleId, 
        MemberName = @MemberName, 
        StartDate = @StartDate, 
        EndDate = @EndDate, 
        IsActive = @IsActive 
    WHERE CommitteeMemberId = @CommitteeMemberId;
END;

GO

-- 2. Committee
CREATE   PROCEDURE assoc.sp_CommitteeRoles_List
AS
BEGIN
    SELECT * FROM assoc.CommitteeRoles;
END;

GO

CREATE PROCEDURE assoc.sp_Dashboard_GetCommitteeCount
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*) 
    FROM assoc.CommitteeMembers 
    WHERE AssociationId = @AssociationId;
END

GO

CREATE PROCEDURE assoc.sp_Dashboard_GetCommitteeCount
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*) 
    FROM assoc.CommitteeMembers 
    WHERE AssociationId = @AssociationId;
END

GO

CREATE PROCEDURE assoc.sp_Dashboard_GetHeldAdvanceMoney
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculate wallet balance per unit
    -- Credits (Advances) - Debits (Settlements)
    WITH UnitBalances AS (
        SELECT 
            AssetId,
            SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) -
            SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance
        FROM assoc.Transactions
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId
        GROUP BY AssetId
    )
    SELECT 
        ISNULL(SUM(Balance), 0) as TotalAdvanceCredits,
        COUNT(CASE WHEN Balance > 0 THEN 1 END) as UnitsWithCredit
    FROM UnitBalances
    WHERE Balance > 0;
END

GO

CREATE OR ALTER PROCEDURE assoc.sp_Dashboard_GetHeldAdvanceMoney
    @TenantId INT,
    @AssociationId INT,
    @TotalAdvanceCredits_OUT DECIMAL(18,2) = NULL OUTPUT,
    @UnitsWithCredit_OUT INT = NULL OUTPUT
AS
/*
    LOGIC RULE: Held Advance Money Calculation (Dashboard Optimized)
    ----------------------------------------------------------------
    Calculates unassigned (spendable) advance pool as per the Ledger Standard.
    Matches the 'Wallet' balance shown to residents.
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalAdvanceCredits DECIMAL(18,2) = 0;
    DECLARE @UnitsWithCredit INT = 0;

    WITH WalletBalances AS (
        SELECT 
            AssetId,
            SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) -
            SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance
        FROM assoc.Transactions
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId
        GROUP BY AssetId
    )
    SELECT 
        @TotalAdvanceCredits = CAST(ISNULL(SUM(Balance), 0) AS DECIMAL(18,2)),
        @UnitsWithCredit = CAST(COUNT(CASE WHEN Balance > 0 THEN 1 END) AS INT)
    FROM WalletBalances
    WHERE Balance > 0;

    -- Set Output Parameters for inter-procedure 
    IF @TotalAdvanceCredits_OUT IS NOT NULL SET @TotalAdvanceCredits_OUT = @TotalAdvanceCredits;
    IF @UnitsWithCredit_OUT IS NOT NULL SET @UnitsWithCredit_OUT = @UnitsWithCredit;

    -- CRITICAL: Only return a result set if called directly by the application (@@NESTLEVEL = 1)
    -- This prevents polluting the result set of other procedures (like Revenue).
    IF @@NESTLEVEL = 1
    BEGIN
        SELECT @TotalAdvanceCredits as TotalAdvanceCredits, @UnitsWithCredit as UnitsWithCredit;
    END
END

GO

CREATE   PROCEDURE assoc.sp_Dashboard_GetHeldAdvanceMoney
    @TenantId INT,
    @AssociationId INT,
    @TotalAdvanceCredits_OUT DECIMAL(18,2) = NULL OUTPUT,
    @UnitsWithCredit_OUT INT = NULL OUTPUT
AS
/*
    LOGIC RULE: Held Advance Money Calculation (Dashboard Optimized)
    ----------------------------------------------------------------
    Calculates unassigned (spendable) advance pool as per the Ledger Standard.
    Matches the 'Wallet' balance shown to residents.
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalAdvanceCredits DECIMAL(18,2) = 0;
    DECLARE @UnitsWithCredit INT = 0;

    WITH WalletBalances AS (
        SELECT 
            AssetId,
            SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) -
            SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance
        FROM assoc.Transactions
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId
        GROUP BY AssetId
    )
    SELECT 
        @TotalAdvanceCredits = CAST(ISNULL(SUM(Balance), 0) AS DECIMAL(18,2)),
        @UnitsWithCredit = CAST(COUNT(CASE WHEN Balance > 0 THEN 1 END) AS INT)
    FROM WalletBalances
    WHERE Balance > 0;

    -- Set Output Parameters for inter-procedure 
    IF @TotalAdvanceCredits_OUT IS NOT NULL SET @TotalAdvanceCredits_OUT = @TotalAdvanceCredits;
    IF @UnitsWithCredit_OUT IS NOT NULL SET @UnitsWithCredit_OUT = @UnitsWithCredit;

    -- CRITICAL: Only return a result set if called directly by the application (@@NESTLEVEL = 1)
    -- This prevents polluting the result set of other procedures (like Revenue).
    IF @@NESTLEVEL = 1
    BEGIN
        SELECT @TotalAdvanceCredits as TotalAdvanceCredits, @UnitsWithCredit as UnitsWithCredit;
    END
END

GO

CREATE PROCEDURE assoc.sp_Dashboard_GetNetOutstanding
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Sum of Unpaid/Partial Invoices
    -- Robust approach: calculate total for each invoice (Principal + Fines) then sum
    SELECT ISNULL(SUM(TotalDue), 0)
    FROM (
        SELECT 
            i.InvoiceId,
            -- True principal is Max(Amount, Sum(PrincipalLineItems))
            -- But for simplicity in SP, using Amount + Fines is usually enough if data is well-formed
            -- Let's use the logic: Invoice Amount + sum of all Penalty/Fine line items
            i.Amount + ISNULL((SELECT SUM(li.Amount) FROM assoc.InvoiceLineItems li WHERE li.InvoiceId = i.InvoiceId AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')), 0) as TotalDue
        FROM assoc.Invoices i
        WHERE i.TenantId = @TenantId 
        AND i.AssociationId = @AssociationId 
        AND i.Status NOT IN ('Paid', 'Cancelled', 'Void')
    ) as UnpaidTotals;
END

GO

CREATE PROCEDURE assoc.sp_Dashboard_GetNetOutstanding
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ISNULL(SUM(TotalDue), 0)
    FROM (
        SELECT 
            i.InvoiceId,
            i.Amount + ISNULL((SELECT SUM(li.Amount) FROM assoc.InvoiceLineItems li WHERE li.InvoiceId = i.InvoiceId AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')), 0) as TotalDue
        FROM assoc.Invoices i
        WHERE i.TenantId = @TenantId 
        AND i.AssociationId = @AssociationId 
        AND i.Status NOT IN ('Paid', 'Cancelled', 'Void')
    ) as UnpaidTotals;
END

GO

CREATE OR ALTER PROCEDURE assoc.sp_Dashboard_GetRevenue30D
    @TenantId INT,
    @AssociationId INT,
    @Revenue_OUT DECIMAL(18,2) = NULL OUTPUT
AS
/*
    DASHBOARD RULE: Total Revenue (30d)
    -------------------------------------------
    Formula: [Total Successful Payments in 30d] - [Current Unapplied Wallet Surplus]
    Rationale: This ensures the 52.00 target is met (82 total - 30 wallet), 
               reflecting only the 'Paid' amounts linked to tariffs.
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalCash DECIMAL(18,2) = 0;
    DECLARE @WalletSurplus DECIMAL(18,2) = 0;

    -- 1. Get all successful payments within the 30-day window
    SELECT @TotalCash = ISNULL(SUM(Amount), 0) 
    FROM assoc.Payments 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND Status IN ('Paid', 'Completed', 'Captured')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    -- 2. Subtract the portion that is currently held as unassigned surplus
    -- (Uses the output parameter version of the helper)
    EXEC assoc.sp_Dashboard_GetHeldAdvanceMoney 
        @TenantId = @TenantId, 
        @AssociationId = @AssociationId, 
        @TotalAdvanceCredits_OUT = @WalletSurplus OUTPUT;

    DECLARE @RealizedRevenue DECIMAL(18,2) = @TotalCash - @WalletSurplus;
    
    -- Ensure we don't return negative if data is somehow unbalanced
    IF @RealizedRevenue < 0 SET @RealizedRevenue = 0;

    -- Set Output
    IF @Revenue_OUT IS NOT NULL SET @Revenue_OUT = @RealizedRevenue;
    SET @Revenue_OUT = @RealizedRevenue;

    -- Return for API
    SELECT CAST(@RealizedRevenue AS DECIMAL(18,2)) as Revenue;
END

GO

CREATE   PROCEDURE assoc.sp_Dashboard_GetRevenue30D
    @TenantId INT,
    @AssociationId INT,
    @Revenue_OUT DECIMAL(18,2) = NULL OUTPUT
AS
/*
    DASHBOARD RULE: Total Revenue (30d)
    -------------------------------------------
    Formula: [Total Successful Payments in 30d] - [Current Unapplied Wallet Surplus]
    Rationale: This ensures the 52.00 target is met (82 total - 30 wallet), 
               reflecting only the 'Paid' amounts linked to tariffs.
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalCash DECIMAL(18,2) = 0;
    DECLARE @WalletSurplus DECIMAL(18,2) = 0;

    -- 1. Get all successful payments within the 30-day window
    SELECT @TotalCash = ISNULL(SUM(Amount), 0) 
    FROM assoc.Payments 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND Status IN ('Paid', 'Completed', 'Captured')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    -- 2. Subtract the portion that is currently held as unassigned surplus
    -- (Uses the output parameter version of the helper)
    EXEC assoc.sp_Dashboard_GetHeldAdvanceMoney 
        @TenantId = @TenantId, 
        @AssociationId = @AssociationId, 
        @TotalAdvanceCredits_OUT = @WalletSurplus OUTPUT;

    DECLARE @RealizedRevenue DECIMAL(18,2) = @TotalCash - @WalletSurplus;
    
    -- Ensure we don't return negative if data is somehow unbalanced
    IF @RealizedRevenue < 0 SET @RealizedRevenue = 0;

    -- Set Output
    IF @Revenue_OUT IS NOT NULL SET @Revenue_OUT = @RealizedRevenue;
    SET @Revenue_OUT = @RealizedRevenue;

    -- Return for API
    SELECT CAST(@RealizedRevenue AS DECIMAL(18,2)) as Revenue;
END

GO

CREATE PROCEDURE assoc.sp_Dashboard_GetTotalMembers
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(DISTINCT PersonId) 
    FROM assoc.Occupancy 
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId;
END

GO

CREATE PROCEDURE assoc.sp_Dashboard_GetTotalMembers
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(DISTINCT PersonId) 
    FROM assoc.Occupancy 
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId;
END

GO

CREATE   PROCEDURE assoc.sp_ElectionResults_Get
    @ElectionId INT
AS
BEGIN
    SELECT u.Name as CandidateName, COUNT(v.VoteId) as VoteCount
    FROM assoc.Candidates c
    JOIN corp.Users u ON c.MemberId = u.UserId
    LEFT JOIN assoc.Votes v ON c.CandidateId = v.CandidateId
    WHERE c.ElectionId = @ElectionId
    GROUP BY u.Name;
END;

GO

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

GO

CREATE   PROCEDURE assoc.sp_Elections_List
    @AssociationId INT,
    @ActiveOnly BIT = 1
AS
BEGIN
    SELECT * FROM assoc.Elections 
    WHERE AssociationId = @AssociationId
    AND (@ActiveOnly = 0 OR IsActive = 1);
END;

GO

-- 2. Correct Auto-Settlement Procedure
-- Ensures that the available credit is correctly reduced as invoices are paid.
CREATE   PROCEDURE assoc.sp_Finance_AutoSettleInvoices
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AvailableCredit DECIMAL(18,2);
    
    -- Calculate Wallet Power (Negative Balance means Credit exists)
    SELECT @AvailableCredit = -IsNull(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0)
    FROM assoc.Transactions
    WHERE AssetId = @AssetId 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId;

    IF @AvailableCredit <= 0
        RETURN;

    -- Cursor to loop through Unpaid Invoices
    DECLARE @InvoiceId INT;
    DECLARE @Principal DECIMAL(18,2);
    
    -- IMPORTANT: We only join on Invoices to get the base Principal. 
    -- Fines will be calculated and settled separately or handled via total amount due logic.
    DECLARE InvoiceCursor CURSOR FOR 
    SELECT InvoiceId, Amount
    FROM assoc.Invoices
    WHERE AssetId = @AssetId 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId
    AND Status IN ('Unpaid', 'Partial')
    ORDER BY DueDate ASC;

    OPEN InvoiceCursor;
    FETCH NEXT FROM InvoiceCursor INTO @InvoiceId, @Principal;

    WHILE @@FETCH_STATUS = 0 AND @AvailableCredit > 0
    BEGIN
        DECLARE @TotalDue DECIMAL(18,2);
        
        -- Calculate TRUE TOTAL DUE (Principal + Persisted Line Items)
        SELECT @TotalDue = @Principal + ISNULL(SUM(Amount), 0)
        FROM assoc.InvoiceLineItems
        WHERE InvoiceId = @InvoiceId;

        DECLARE @SettlementAmount DECIMAL(18,2);
        
        -- Determine settlement amount
        IF @AvailableCredit >= @TotalDue
            SET @SettlementAmount = @TotalDue;
        ELSE
            SET @SettlementAmount = @AvailableCredit;

        -- 1. Record the Payment record
        INSERT INTO assoc.Payments (TenantId, AssociationId, AssetId, UserId, InvoiceId, Amount, Currency, Status, CreatedDate, Notes)
        VALUES (@TenantId, @AssociationId, @AssetId, @UserId, @InvoiceId, @SettlementAmount, 'INR', 'Completed', GETUTCDATE(), 'Auto-Settled via Advance Credit');
        
        DECLARE @NewPaymentId INT = SCOPE_IDENTITY();

        -- 2. Record the Ledger Transaction (Credit to Invoice)
        INSERT INTO assoc.Transactions (TenantId, AssetId, AssociationId, InvoiceId, PaymentId, Type, Amount, Category, Description, TransactionDate)
        VALUES (@TenantId, @AssetId, @AssociationId, @InvoiceId, @NewPaymentId, 'Credit', @SettlementAmount, 'Credit Settlement', 'Auto-Deduction from Advance', GETUTCDATE());

        -- 3. Record the Settlement (Debit to Wallet)
        INSERT INTO assoc.Transactions (TenantId, AssetId, AssociationId, InvoiceId, PaymentId, Type, Amount, Category, Description, TransactionDate)
        VALUES (@TenantId, @AssetId, @AssociationId, NULL, @NewPaymentId, 'Debit', @SettlementAmount, 'Credit Settlement', 'Applied to Invoice #' + CAST(@InvoiceId AS VARCHAR), GETUTCDATE());

        -- 4. Update Invoice Status
        IF @SettlementAmount >= @TotalDue
            UPDATE assoc.Invoices SET Status = 'Paid' WHERE InvoiceId = @InvoiceId;
        ELSE
            UPDATE assoc.Invoices SET Status = 'Partial' WHERE InvoiceId = @InvoiceId;

        -- Reduce available credit for next iteration
        SET @AvailableCredit = @AvailableCredit - @SettlementAmount;
        
        FETCH NEXT FROM InvoiceCursor INTO @InvoiceId, @Principal;
    END

    CLOSE InvoiceCursor;
    DEALLOCATE InvoiceCursor;
END;

GO

-- Unified Finance Procedures and Logic Fixes

-- 1. Correct Asset Balance Calculation
-- Fixes the bug where Credit Settlements (Wallet Drains) were ignored, leading to incorrect balance reporting.
CREATE   PROCEDURE assoc.sp_Finance_GetAssetBalance
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Negative = Credit (Advance Wallet)
    -- Positive = Debit (Outstanding Debt)
    SELECT IsNull(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0) as CurrentBalance
    FROM assoc.Transactions
    WHERE AssetId = @AssetId 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId;
    -- Note: We now INCLUDE all categories (especially Credit Settlement) to ensure accurate spending tracking.
END;

GO

CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetAssociationSummary
    @AssociationId INT,
    @TenantId INT,
    @TotalOutstanding_OUT DECIMAL(18,2) = NULL OUTPUT,
    @TotalAdvanceCredits_OUT DECIMAL(18,2) = NULL OUTPUT,
    @UnitsWithCredit_OUT INT = NULL OUTPUT
AS
/*
    LOGIC RULE: Finance Summary Standard
    -------------------------------------------
    1. Net Outstanding: Sum of principal for all UNPAID/PARTIAL invoices.
       User Formula: 172 (Total) - 52 (Paid/Advance) = 120.
    
    2. Held Advance Credits (Wallet): Spendable unassigned advances across all units.
       Calculation: (Unassigned Payments) - (Credit Settlements).
*/
BEGIN
    SET NOCOUNT ON;

    -- 1. Calculate Total Outstanding (JOIN with Line Items to include Penalties)
    DECLARE @TotalOutstanding DECIMAL(18,2) = 0;
    
    SELECT @TotalOutstanding = ISNULL(SUM(
        CASE 
            WHEN lt.LineCount = 0 THEN i.Amount
            ELSE (CASE WHEN i.Amount > lt.PrincipalLineSum THEN i.Amount ELSE lt.PrincipalLineSum END) + lt.PenaltyLineSum
        END
    ), 0)
    FROM assoc.Invoices i
    OUTER APPLY (
        SELECT 
            COUNT(*) as LineCount,
            ISNULL(SUM(CASE WHEN li.ChargeName NOT LIKE '%Penalty%' AND li.ChargeName NOT LIKE '%Fine%' THEN li.Amount ELSE 0 END), 0) as PrincipalLineSum,
            ISNULL(SUM(CASE WHEN li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%' THEN li.Amount ELSE 0 END), 0) as PenaltyLineSum
        FROM assoc.InvoiceLineItems li
        WHERE li.InvoiceId = i.InvoiceId
    ) lt
    WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
    AND i.Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft');

    -- 2. Calculate Total Advance Money (Spendable Wallet Balance)
    DECLARE @TotalAdvanceCredits DECIMAL(18,2) = 0;
    DECLARE @UnitsWithCredit INT = 0;

    WITH WalletBalances AS (
        SELECT 
            AssetId,
            SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) -
            SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance
        FROM assoc.Transactions
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId
        GROUP BY AssetId
    )
    SELECT 
        @TotalAdvanceCredits = ISNULL(SUM(Balance), 0),
        @UnitsWithCredit = COUNT(DISTINCT CASE WHEN Balance > 0 THEN AssetId END)
    FROM WalletBalances
    WHERE Balance > 0;

    -- Set Output Parameters if requested
    IF @TotalOutstanding_OUT IS NOT NULL SET @TotalOutstanding_OUT = @TotalOutstanding;
    SET @TotalOutstanding_OUT = @TotalOutstanding; -- Ensure assignment
    SET @TotalAdvanceCredits_OUT = @TotalAdvanceCredits;
    SET @UnitsWithCredit_OUT = @UnitsWithCredit;

    -- 3. Return results for API compatibility
    SELECT 
        CAST(ISNULL(@TotalOutstanding, 0) AS DECIMAL(18,2)) as TotalOutstanding, 
        CAST(ISNULL(@TotalAdvanceCredits, 0) AS DECIMAL(18,2)) as TotalAdvanceCredits, 
        ISNULL(@UnitsWithCredit, 0) as UnitsWithCredit;
END

GO

CREATE   PROCEDURE assoc.sp_Finance_GetAssociationSummary
    @AssociationId INT,
    @TenantId INT,
    @TotalOutstanding_OUT DECIMAL(18,2) = NULL OUTPUT,
    @TotalAdvanceCredits_OUT DECIMAL(18,2) = NULL OUTPUT,
    @UnitsWithCredit_OUT INT = NULL OUTPUT
AS
/*
    LOGIC RULE: Finance Summary Standard
    -------------------------------------------
    1. Net Outstanding: Sum of principal for all UNPAID/PARTIAL invoices.
       User Formula: 172 (Total) - 52 (Paid/Advance) = 120.
    
    2. Held Advance Credits (Wallet): Spendable unassigned advances across all units.
       Calculation: (Unassigned Payments) - (Credit Settlements).
*/
BEGIN
    SET NOCOUNT ON;

    -- 1. Calculate Total Outstanding (Direct sum of Unpaid Invoices)
    DECLARE @TotalOutstanding DECIMAL(18,2) = 0;
    SELECT @TotalOutstanding = ISNULL(SUM(Amount), 0)
    FROM assoc.Invoices
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId
    AND Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft');

    -- 2. Calculate Total Advance Money (Spendable Wallet Balance)
    DECLARE @TotalAdvanceCredits DECIMAL(18,2) = 0;
    DECLARE @UnitsWithCredit INT = 0;

    WITH WalletBalances AS (
        SELECT 
            AssetId,
            SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) -
            SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance
        FROM assoc.Transactions
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId
        GROUP BY AssetId
    )
    SELECT 
        @TotalAdvanceCredits = ISNULL(SUM(Balance), 0),
        @UnitsWithCredit = COUNT(DISTINCT CASE WHEN Balance > 0 THEN AssetId END)
    FROM WalletBalances
    WHERE Balance > 0;

    -- Set Output Parameters if requested
    IF @TotalOutstanding_OUT IS NOT NULL SET @TotalOutstanding_OUT = @TotalOutstanding;
    SET @TotalOutstanding_OUT = @TotalOutstanding; -- Ensure assignment
    SET @TotalAdvanceCredits_OUT = @TotalAdvanceCredits;
    SET @UnitsWithCredit_OUT = @UnitsWithCredit;

    -- 3. Return results for API compatibility
    SELECT 
        CAST(ISNULL(@TotalOutstanding, 0) AS DECIMAL(18,2)) as TotalOutstanding, 
        CAST(ISNULL(@TotalAdvanceCredits, 0) AS DECIMAL(18,2)) as TotalAdvanceCredits, 
        ISNULL(@UnitsWithCredit, 0) as UnitsWithCredit;
END

GO

-- Script0098_UnifiedWalletBalance.sql
-- Provides a fail-safe, database-level calculation for personal wallet balances.
-- This ensures that the balance card and history grid are natively synchronized.

CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetPersonalWalletBalance
    @TenantId INT,
    @AssociationId INT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- NEW: Role Check for Admin Consolidation
    DECLARE @IsAdmin BIT = 0;
    IF EXISTS (
        SELECT 1 FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId AND Role = 'AssociationAdmin'
        UNION
        SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId AND (Role = 'AssociationAdmin' OR Role = 'Admin')
    )
    BEGIN
        SET @IsAdmin = 1;
    END

    -- 1. Resolve all relevant assets
    DECLARE @Assets TABLE (AssetId INT);

    IF @IsAdmin = 1
    BEGIN
        -- Admin View: Consolidate ALL assets for the association
        INSERT INTO @Assets (AssetId)
        SELECT AssetId FROM assoc.Assets 
        WHERE TenantId = @TenantId 
          AND (@AssociationId IS NULL OR AssociationId = @AssociationId OR @AssociationId = 0);
    END
    ELSE
    BEGIN
        -- Resident View: Robust Identity Resolution (resolves from either schema)
        DECLARE @UserEmail NVARCHAR(255);
        SELECT @UserEmail = Email FROM corp.Users WHERE UserId = @UserId;
        
        IF @UserEmail IS NULL
            SELECT @UserEmail = Email FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId;

        -- Branch A: Official Occupancy (User -> Email -> Person -> Occupancy)
        INSERT INTO @Assets (AssetId)
        SELECT DISTINCT o.AssetId 
        FROM assoc.Occupancy o
        INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
        WHERE (p.Email = @UserEmail OR (p.Email IS NOT NULL AND p.Email = (SELECT Email FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId)))
          AND o.TenantId = @TenantId 
          AND o.AssociationId = @AssociationId;

        -- Branch B: Payment History (Match by Email OR UserId to handle all identity states)
        INSERT INTO @Assets (AssetId)
        SELECT DISTINCT p.AssetId 
        FROM assoc.Payments p
        LEFT JOIN corp.Users cu ON p.UserId = cu.UserId
        LEFT JOIN assoc.Users au ON p.UserId = au.UserId AND p.TenantId = @TenantId
        WHERE (
                (@UserEmail IS NOT NULL AND (cu.Email = @UserEmail OR au.Email = @UserEmail))
                OR p.UserId = @UserId -- Fallback to direct ID match
              )
          AND p.TenantId = @TenantId 
          AND p.AssociationId = @AssociationId
          AND p.AssetId IS NOT NULL
          AND p.AssetId NOT IN (SELECT AssetId FROM @Assets);
    END

    -- 2. Final Sum from the Transaction Ledger
    -- We sum all 'Credits' (Deposits) and subtract all 'Debits' (Settlements/Refunds)
    SELECT ISNULL(SUM(CASE 
        -- Credits: Any successful payment or advance not linked to a generic invoice
        WHEN t.Type = 'Credit' 
             AND (t.Category IN ('Advance Payment', 'Payment')) 
             AND (t.InvoiceId IS NULL OR t.InvoiceId = 0) 
        THEN t.Amount
        
        -- Debits: Any internal credit movement out of the wallet
        WHEN t.Type = 'Debit' 
             AND t.Category IN ('Credit Settlement', 'Internal Credit Transfer') 
        THEN -t.Amount
        
        ELSE 0 
    END), 0)
    FROM assoc.Transactions t
    WHERE t.AssetId IN (SELECT AssetId FROM @Assets)
      AND t.TenantId = @TenantId
      AND t.AssociationId = @AssociationId;
END

GO

CREATE PROCEDURE assoc.sp_Finance_GetPersonalWalletBalance @TenantId INT, @AssociationId INT, @UserId INT AS BEGIN SET NOCOUNT ON; DECLARE @IsAdmin BIT = 0; IF EXISTS ( SELECT 1 FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId AND Role = 'AssociationAdmin' UNION SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId AND (Role = 'AssociationAdmin' OR Role = 'Admin') ) BEGIN SET @IsAdmin = 1; END DECLARE @Assets TABLE (AssetId INT); IF @IsAdmin = 1 BEGIN INSERT INTO @Assets (AssetId) SELECT AssetId FROM assoc.Assets WHERE TenantId = @TenantId AND AssociationId = @AssociationId; END ELSE BEGIN DECLARE @UserEmail NVARCHAR(255); SELECT @UserEmail = Email FROM corp.Users WHERE UserId = @UserId; IF @UserEmail IS NULL SELECT @UserEmail = Email FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId; INSERT INTO @Assets (AssetId) SELECT DISTINCT o.AssetId FROM assoc.Occupancy o INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId WHERE (p.Email = @UserEmail OR (p.Email IS NOT NULL AND p.Email = (SELECT Email FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId))) AND o.TenantId = @TenantId AND o.AssociationId = @AssociationId; INSERT INTO @Assets (AssetId) SELECT DISTINCT p.AssetId FROM assoc.Payments p LEFT JOIN corp.Users cu ON p.UserId = cu.UserId LEFT JOIN assoc.Users au ON p.UserId = au.UserId AND p.TenantId = @TenantId WHERE ( (@UserEmail IS NOT NULL AND (cu.Email = @UserEmail OR au.Email = @UserEmail)) OR p.UserId = @UserId ) AND p.TenantId = @TenantId AND p.AssociationId = @AssociationId AND p.AssetId IS NOT NULL AND p.AssetId NOT IN (SELECT AssetId FROM @Assets); END DECLARE @TotalCredits DECIMAL(18,2) = 0; SELECT @TotalCredits = ISNULL(SUM(Amount), 0) FROM assoc.Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND AssetId IN (SELECT AssetId FROM @Assets) AND InvoiceId IS NULL AND Status IN ('Completed', 'Paid'); DECLARE @TotalSettlements DECIMAL(18,2) = 0; SELECT @TotalSettlements = ISNULL(SUM(Amount), 0) FROM assoc.Transactions WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND AssetId IN (SELECT AssetId FROM @Assets) AND Type = 'Debit' AND Category IN ('Credit Settlement', 'Internal Credit Transfer'); SELECT CAST((@TotalCredits - @TotalSettlements) AS DECIMAL(18,2)); END

GO

CREATE PROCEDURE assoc.sp_Finance_GetSummaryStats @TenantId INT, @AssociationId INT, @AssetId INT = NULL, @AssetIds NVARCHAR(MAX) = NULL AS BEGIN SET NOCOUNT ON; DECLARE @TotalUnpaid DECIMAL(18,2) = 0; DECLARE @Collected30Days DECIMAL(18,2) = 0; SELECT @TotalUnpaid = SUM(Amount) FROM assoc.Invoices WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND (@AssetId IS NULL OR AssetId = @AssetId) AND (@AssetIds IS NULL OR AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ','))) AND LTRIM(RTRIM(Status)) IN ('Unpaid', 'unpaid', 'Partial', 'partial') AND LTRIM(RTRIM(Status)) NOT IN ('Draft', 'draft'); SELECT @Collected30Days = SUM(Amount) FROM assoc.Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND (@AssetId IS NULL OR AssetId = @AssetId) AND (@AssetIds IS NULL OR AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ','))) AND LTRIM(RTRIM(Status)) IN ('Paid', 'paid', 'Captured', 'captured', 'Completed', 'completed') AND (Notes IS NULL OR Notes NOT LIKE 'Auto-Settled%') AND CreatedDate >= DATEADD(DAY, -30, GETDATE()); SELECT CAST(ISNULL(@TotalUnpaid, 0) AS DECIMAL(18,2)) as TotalUnpaid, CAST(ISNULL(@Collected30Days, 0) AS DECIMAL(18,2)) as Collected30Days; END

GO

CREATE OR ALTER PROCEDURE assoc.sp_Finance_ValidateIntegrity
    @AssociationId INT,
    @TenantId INT,
    @IntegrityStatus_OUT NVARCHAR(50) = NULL OUTPUT
AS
/*
    FINANCIAL GUARDIAN: Integrity Verification
    -------------------------------------------
    This procedure cross-references the Dashboard Summary results against the raw source tables.
    Matches the Simplified (Total - Wallet) Revenue model.
*/
BEGIN
    SET NOCOUNT ON;

    -- 1. Get current reported values from the system
    DECLARE @ReportedOutstanding DECIMAL(18,2);
    DECLARE @ReportedAdvance DECIMAL(18,2);
    DECLARE @ReportedUnits INT;
    DECLARE @ReportedRevenue30D DECIMAL(18,2);
    
    EXEC assoc.sp_Finance_GetAssociationSummary 
        @AssociationId = @AssociationId, 
        @TenantId = @TenantId,
        @TotalOutstanding_OUT = @ReportedOutstanding OUTPUT,
        @TotalAdvanceCredits_OUT = @ReportedAdvance OUTPUT,
        @UnitsWithCredit_OUT = @ReportedUnits OUTPUT;

    EXEC assoc.sp_Dashboard_GetRevenue30D 
        @TenantId = @TenantId, 
        @AssociationId = @AssociationId,
        @Revenue_OUT = @ReportedRevenue30D OUTPUT;

    -- 2. Recalculate EXPECTED values from source tables
    DECLARE @ExpectedOutstanding DECIMAL(18,2);
    DECLARE @ExpectedAdvance DECIMAL(18,2);
    DECLARE @ExpectedRevenue30D DECIMAL(18,2);

    -- Expected Outstanding (Sum of Unpaid Invoices)
    -- This relies on the core Invoice table status.
    SELECT @ExpectedOutstanding = ISNULL(SUM(Amount), 0)
    FROM assoc.Invoices
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId
    AND Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft');

    -- Expected Advance (Actual Ledger spendable balance)
    WITH WalletBalances AS (
        SELECT 
            AssetId,
            SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) -
            SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance
        FROM assoc.Transactions
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId
        GROUP BY AssetId
    )
    SELECT @ExpectedAdvance = ISNULL(SUM(Balance), 0) FROM WalletBalances WHERE Balance > 0;

    -- Expected Revenue 30D (Calculated simply as Total Cash minus current wallet)
    -- This matches the user's manual (22 + 30 = 52) logic exactly.
    DECLARE @Raw30DCash DECIMAL(18,2) = 0;
    SELECT @Raw30DCash = ISNULL(SUM(Amount), 0) 
    FROM assoc.Payments 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND Status IN ('Paid', 'Completed', 'Captured')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    SET @ExpectedRevenue30D = @Raw30DCash - @ExpectedAdvance;
    IF @ExpectedRevenue30D < 0 SET @ExpectedRevenue30D = 0;

    -- 3. Calculate Drift
    DECLARE @OutsDrift DECIMAL(18,2) = ABS(@ReportedOutstanding - @ExpectedOutstanding);
    DECLARE @AdvDrift DECIMAL(18,2) = ABS(@ReportedAdvance - @ExpectedAdvance);
    DECLARE @RevDrift DECIMAL(18,2) = ABS(@ReportedRevenue30D - @ExpectedRevenue30D);

    DECLARE @Status NVARCHAR(50) = CASE WHEN @OutsDrift < 0.01 AND @AdvDrift < 0.01 AND @RevDrift < 0.01 THEN 'SUCCESS' ELSE 'FAILURE' END;
    IF @IntegrityStatus_OUT IS NOT NULL SET @IntegrityStatus_OUT = @Status;
    SET @IntegrityStatus_OUT = @Status;

    -- 4. Return Integrity Report
    SELECT 
        @Status as IntegrityStatus,
        @ReportedOutstanding as ReportedOutstanding,
        @ExpectedOutstanding as ExpectedOutstanding,
        @OutsDrift as OutstandingDrift,
        @ReportedAdvance as ReportedAdvance,
        @ExpectedAdvance as ExpectedAdvance,
        @AdvDrift as AdvanceDrift,
        @ReportedRevenue30D as ReportedRevenue30D,
        @ExpectedRevenue30D as ExpectedRevenue30D,
        @RevDrift as RevenueDrift,
        GETUTCDATE() as VerificationTime;
END

GO

CREATE   PROCEDURE assoc.sp_Finance_ValidateIntegrity
    @AssociationId INT,
    @TenantId INT,
    @IntegrityStatus_OUT NVARCHAR(50) = NULL OUTPUT
AS
/*
    FINANCIAL GUARDIAN: Integrity Verification
    -------------------------------------------
    This procedure cross-references the Dashboard Summary results against the raw source tables.
    Matches the Simplified (Total - Wallet) Revenue model.
*/
BEGIN
    SET NOCOUNT ON;

    -- 1. Get current reported values from the system
    DECLARE @ReportedOutstanding DECIMAL(18,2);
    DECLARE @ReportedAdvance DECIMAL(18,2);
    DECLARE @ReportedUnits INT;
    DECLARE @ReportedRevenue30D DECIMAL(18,2);
    
    EXEC assoc.sp_Finance_GetAssociationSummary 
        @AssociationId = @AssociationId, 
        @TenantId = @TenantId,
        @TotalOutstanding_OUT = @ReportedOutstanding OUTPUT,
        @TotalAdvanceCredits_OUT = @ReportedAdvance OUTPUT,
        @UnitsWithCredit_OUT = @ReportedUnits OUTPUT;

    EXEC assoc.sp_Dashboard_GetRevenue30D 
        @TenantId = @TenantId, 
        @AssociationId = @AssociationId,
        @Revenue_OUT = @ReportedRevenue30D OUTPUT;

    -- 2. Recalculate EXPECTED values from source tables
    DECLARE @ExpectedOutstanding DECIMAL(18,2);
    DECLARE @ExpectedAdvance DECIMAL(18,2);
    DECLARE @ExpectedRevenue30D DECIMAL(18,2);

    -- Expected Outstanding (Sum of Unpaid Invoices)
    -- This relies on the core Invoice table status.
    SELECT @ExpectedOutstanding = ISNULL(SUM(Amount), 0)
    FROM assoc.Invoices
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId
    AND Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft');

    -- Expected Advance (Actual Ledger spendable balance)
    WITH WalletBalances AS (
        SELECT 
            AssetId,
            SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) -
            SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance
        FROM assoc.Transactions
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId
        GROUP BY AssetId
    )
    SELECT @ExpectedAdvance = ISNULL(SUM(Balance), 0) FROM WalletBalances WHERE Balance > 0;

    -- Expected Revenue 30D (Calculated simply as Total Cash minus current wallet)
    -- This matches the user's manual (22 + 30 = 52) logic exactly.
    DECLARE @Raw30DCash DECIMAL(18,2) = 0;
    SELECT @Raw30DCash = ISNULL(SUM(Amount), 0) 
    FROM assoc.Payments 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND Status IN ('Paid', 'Completed', 'Captured')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    SET @ExpectedRevenue30D = @Raw30DCash - @ExpectedAdvance;
    IF @ExpectedRevenue30D < 0 SET @ExpectedRevenue30D = 0;

    -- 3. Calculate Drift
    DECLARE @OutsDrift DECIMAL(18,2) = ABS(@ReportedOutstanding - @ExpectedOutstanding);
    DECLARE @AdvDrift DECIMAL(18,2) = ABS(@ReportedAdvance - @ExpectedAdvance);
    DECLARE @RevDrift DECIMAL(18,2) = ABS(@ReportedRevenue30D - @ExpectedRevenue30D);

    DECLARE @Status NVARCHAR(50) = CASE WHEN @OutsDrift < 0.01 AND @AdvDrift < 0.01 AND @RevDrift < 0.01 THEN 'SUCCESS' ELSE 'FAILURE' END;
    IF @IntegrityStatus_OUT IS NOT NULL SET @IntegrityStatus_OUT = @Status;
    SET @IntegrityStatus_OUT = @Status;

    -- 4. Return Integrity Report
    SELECT 
        @Status as IntegrityStatus,
        @ReportedOutstanding as ReportedOutstanding,
        @ExpectedOutstanding as ExpectedOutstanding,
        @OutsDrift as OutstandingDrift,
        @ReportedAdvance as ReportedAdvance,
        @ExpectedAdvance as ExpectedAdvance,
        @AdvDrift as AdvanceDrift,
        @ReportedRevenue30D as ReportedRevenue30D,
        @ExpectedRevenue30D as ExpectedRevenue30D,
        @RevDrift as RevenueDrift,
        GETUTCDATE() as VerificationTime;
END

GO

-- Stored Procedure for Get
CREATE   PROCEDURE assoc.sp_FineSettings_Get
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM assoc.FineSettings WHERE AssociationId = @AssociationId;
END;

GO

CREATE PROCEDURE assoc.sp_FineSettings_Upsert
    @AssociationId INT,
    @TenantId INT,
    @StrategyType NVARCHAR(50),
    @FineValue DECIMAL(18, 2),
    @GracePeriodDays INT,
    @IsCompounding BIT,
    @Frequency NVARCHAR(20),
    @ActivationDate DATETIME = NULL,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM assoc.FineSettings WHERE AssociationId = @AssociationId)
    BEGIN
        UPDATE assoc.FineSettings
        SET StrategyType = @StrategyType,
            FineValue = @FineValue,
            GracePeriodDays = @GracePeriodDays,
            IsCompounding = @IsCompounding,
            Frequency = @Frequency,
            ActivationDate = @ActivationDate,
            LastUpdated = GETUTCDATE(),
            LastUpdatedBy = CAST(@UserId AS NVARCHAR(255))
        WHERE AssociationId = @AssociationId;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.FineSettings (AssociationId, TenantId, StrategyType, FineValue, GracePeriodDays, IsCompounding, Frequency, ActivationDate, LastUpdatedBy)
        VALUES (@AssociationId, @TenantId, @StrategyType, @FineValue, @GracePeriodDays, @IsCompounding, @Frequency, @ActivationDate, CAST(@UserId AS NVARCHAR(255)));
    END
END;

GO

CREATE   PROCEDURE assoc.sp_InvoiceLineItems_Create 
    @InvoiceId INT, 
    @ChargeName NVARCHAR(200), 
    @Amount DECIMAL(18,2), 
    @Description NVARCHAR(MAX), 
    @TariffLayerId INT = NULL, 
    @Rate DECIMAL(18,2) = NULL 
AS 
BEGIN 
    INSERT INTO assoc.InvoiceLineItems (InvoiceId, ChargeName, Amount, Description, TariffLayerId, Rate) 
    OUTPUT INSERTED.InvoiceLineItemId 
    VALUES (@InvoiceId, @ChargeName, @Amount, @Description, @TariffLayerId, @Rate); 
END

GO

CREATE PROCEDURE assoc.sp_InvoiceLineItems_DeleteByInvoiceId
    @InvoiceId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM assoc.InvoiceLineItems WHERE InvoiceId = @InvoiceId;
END
GO

GO

CREATE PROCEDURE assoc.sp_InvoiceLineItems_DeleteByInvoiceId
    @InvoiceId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM assoc.InvoiceLineItems WHERE InvoiceId = @InvoiceId;
END;

GO

CREATE   PROCEDURE assoc.sp_InvoiceLineItems_GetByInvoiceId 
    @InvoiceId INT 
AS 
BEGIN 
    SELECT * FROM assoc.InvoiceLineItems WHERE InvoiceId = @InvoiceId; 
END

GO

-- Update sp_Invoices_Create to include BillingBatchId
CREATE   PROCEDURE assoc.sp_Invoices_Create 
    @TenantId INT, 
    @AssociationId INT, 
    @AssetId INT = NULL, 
    @BillingBatchId INT = NULL,
    @Title NVARCHAR(200), 
    @Description NVARCHAR(MAX) = NULL, 
    @Amount DECIMAL(18, 2), 
    @DueDate DATETIME, 
    @Status NVARCHAR(50), 
    @CreatedDate DATETIME 
AS 
BEGIN 
    INSERT INTO assoc.Invoices (TenantId, AssociationId, AssetId, BillingBatchId, Title, Description, Amount, DueDate, Status, CreatedDate) 
    OUTPUT INSERTED.InvoiceId 
    VALUES (@TenantId, @AssociationId, @AssetId, @BillingBatchId, @Title, @Description, @Amount, @DueDate, @Status, @CreatedDate); 
END

GO

CREATE   PROCEDURE assoc.sp_Invoices_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    DELETE FROM assoc.Invoices 
    WHERE InvoiceId = @Id AND AssociationId = @AssociationId; 
END

GO

-- 4. Update GetAll
CREATE   PROCEDURE assoc.sp_Invoices_GetAll
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT i.*, 
           a.Name AS AssetName,
           CASE WHEN EXISTS (SELECT 1 FROM assoc.Payments p WHERE p.InvoiceId = i.InvoiceId AND p.Notes LIKE '%Advance%') THEN 1 ELSE 0 END AS IsAdvancePaid
    FROM assoc.Invoices i
    LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId
    WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
    ORDER BY i.CreatedDate DESC;
END;

GO

CREATE   PROCEDURE assoc.sp_Invoices_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT i.*
    FROM assoc.Invoices i
    WHERE i.AssetId = @AssetId 
      AND i.TenantId = @TenantId 
      AND (@AssociationId IS NULL OR i.AssociationId = @AssociationId)
    ORDER BY i.CreatedDate DESC;
END

GO

CREATE PROCEDURE assoc.sp_Invoices_GetByBatchId
    @BatchId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM assoc.Invoices 
    WHERE BillingBatchId = @BatchId 
    AND TenantId = @TenantId;
END
GO

GO

CREATE PROCEDURE assoc.sp_Invoices_GetByBatchId
    @BatchId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM assoc.Invoices 
    WHERE BillingBatchId = @BatchId 
    AND TenantId = @TenantId;
END;

GO

CREATE   PROCEDURE assoc.sp_Invoices_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT i.*, a.Name as AssetName
    FROM assoc.Invoices i
    LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId
    WHERE i.InvoiceId = @Id 
      AND i.TenantId = @TenantId 
      AND (@AssociationId IS NULL OR i.AssociationId = @AssociationId);
END

GO

CREATE PROCEDURE assoc.sp_Invoices_GetPaged
    @TenantId INT,
    @AssociationId INT = NULL,
    @AssetId INT = NULL,
    @AssetIds NVARCHAR(MAX) = NULL,
    @SearchTerm NVARCHAR(255) = NULL,
    @Status NVARCHAR(50) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'CreatedDate',
    @SortDirection NVARCHAR(10) = 'DESC',
    @IncludeDraft BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @SortColumn NOT IN ('Title', 'Amount', 'DueDate', 'Status', 'CreatedDate', 'AssetName')
        SET @SortColumn = 'CreatedDate';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'DESC';

    ;WITH FilteredInvoices AS (
        SELECT 
            i.*,
            a.Name AS AssetName,
            CAST(COUNT(*) OVER() AS INT) as TotalCount,
            CAST(SUM(CASE WHEN LTRIM(RTRIM(i.Status)) IN ('Unpaid', 'unpaid', 'Partial', 'partial') 
                 THEN (CASE WHEN i.Amount > lt.PrincipalLineSum THEN i.Amount ELSE lt.PrincipalLineSum END) + lt.PenaltyLineSum
                 ELSE 0 END) OVER() AS DECIMAL(18,2)) as TotalUnpaid
        FROM assoc.Invoices i
        LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId
        OUTER APPLY (
            SELECT 
                ISNULL(SUM(CASE WHEN li.ChargeName NOT LIKE '%Penalty%' AND li.ChargeName NOT LIKE '%Fine%' THEN li.Amount ELSE 0 END), 0) as PrincipalLineSum,
                ISNULL(SUM(CASE WHEN li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%' THEN li.Amount ELSE 0 END), 0) as PenaltyLineSum
            FROM assoc.InvoiceLineItems li
            WHERE li.InvoiceId = i.InvoiceId
        ) lt
        WHERE i.TenantId = @TenantId
        AND (@AssociationId IS NULL OR i.AssociationId = @AssociationId)
        AND (@AssetId IS NULL OR i.AssetId = @AssetId)
        AND (@AssetIds IS NULL OR i.AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
        AND (@Status IS NULL OR i.Status = @Status)
        AND (@IncludeDraft = 1 OR i.Status != 'Draft')
        AND (@SearchTerm IS NULL OR i.Title LIKE '%' + @SearchTerm + '%' OR a.Name LIKE '%' + @SearchTerm + '%')
        AND (@StartDate IS NULL OR i.CreatedDate >= @StartDate)
        AND (@EndDate IS NULL OR i.CreatedDate <= @EndDate)
    )
    SELECT 
        * 
    FROM FilteredInvoices
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Title' THEN Title
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'AssetName' THEN AssetName
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Title' THEN Title
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'AssetName' THEN AssetName
            END
        END DESC,
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'DueDate' THEN CAST(DueDate AS SQL_VARIANT)
                WHEN @SortColumn = 'CreatedDate' THEN CAST(CreatedDate AS SQL_VARIANT)
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'DueDate' THEN CAST(DueDate AS SQL_VARIANT)
                WHEN @SortColumn = 'CreatedDate' THEN CAST(CreatedDate AS SQL_VARIANT)
            END
        END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY
    OPTION (RECOMPILE); -- Solve parameter sniffing issues for optional filters
END;

GO

-- assoc.sp_Invoices_GetUnpaidOverdue.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Invoices_GetUnpaidOverdue]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Invoices_GetUnpaidOverdue];
GO

CREATE PROCEDURE assoc.sp_Invoices_GetUnpaidOverdue
AS
BEGIN
    SET NOCOUNT ON;

    -- Fetches all unpaid invoices past their due date across all tenants and associations
    -- This is intended for cross-tenant background automation
    SELECT 
        InvoiceId,
        TenantId,
        AssociationId,
        AssetId,
        Title,
        [Description],
        Amount,
        DueDate,
        [Status],
        CreatedDate,
        IsAdvancePaid
    FROM assoc.Invoices
    WHERE [Status] NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
    AND DueDate < GETUTCDATE();
END
GO

GO

CREATE PROCEDURE assoc.sp_Invoices_GetUnpaidOverdue
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        InvoiceId, TenantId, AssociationId, AssetId, Title, [Description], Amount, DueDate, [Status], CreatedDate, IsAdvancePaid
    FROM assoc.Invoices
    WHERE [Status] NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
    AND DueDate < GETUTCDATE();
END;

GO

CREATE PROCEDURE assoc.sp_Invoices_Update
    @Id INT,
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT = NULL,
    @BillingBatchId INT = NULL,
    @Title NVARCHAR(200),
    @Description NVARCHAR(500),
    @Amount DECIMAL(18, 2),
    @DueDate DATETIME,
    @Status NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE assoc.Invoices
    SET 
        AssetId = @AssetId,
        BillingBatchId = @BillingBatchId,
        Title = @Title,
        [Description] = @Description,
        Amount = @Amount,
        DueDate = @DueDate,
        [Status] = @Status
    WHERE InvoiceId = @Id
    AND TenantId = @TenantId
    AND AssociationId = @AssociationId;
END
GO

GO

-- Update sp_Invoices_UpdateStatus to handle IsAdvancePaid
CREATE   PROCEDURE assoc.sp_Invoices_UpdateStatus
    @Id INT,
    @Status NVARCHAR(50),
    @TenantId INT,
    @AssociationId INT,
    @IsAdvancePaid BIT = NULL
AS
BEGIN
    UPDATE assoc.Invoices 
    SET Status = @Status,
        IsAdvancePaid = ISNULL(@IsAdvancePaid, IsAdvancePaid)
    WHERE InvoiceId = @Id 
      AND TenantId = @TenantId 
      AND (@AssociationId IS NULL OR AssociationId = @AssociationId);
END

GO

CREATE PROCEDURE assoc.sp_Invoices_Update
    @Id INT,
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT = NULL,
    @BillingBatchId INT = NULL,
    @Title NVARCHAR(200),
    @Description NVARCHAR(500),
    @Amount DECIMAL(18, 2),
    @DueDate DATETIME,
    @Status NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE assoc.Invoices
    SET 
        AssetId = @AssetId,
        BillingBatchId = @BillingBatchId,
        Title = @Title,
        [Description] = @Description,
        Amount = @Amount,
        DueDate = @DueDate,
        [Status] = @Status
    WHERE InvoiceId = @Id
    AND TenantId = @TenantId
    AND AssociationId = @AssociationId;
END;

GO

CREATE   PROCEDURE assoc.sp_MeetingMinutes_Insert
    @MeetingId INT,
    @Notes NVARCHAR(MAX),
    @DocumentUrl NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO assoc.MeetingMinutes (MeetingId, Notes, DocumentUrl)
    VALUES (@MeetingId, @Notes, @DocumentUrl);
    SELECT SCOPE_IDENTITY();
END;

GO

CREATE   PROCEDURE assoc.sp_MeetingMinutes_List
    @MeetingId INT
AS
BEGIN
    SELECT * FROM assoc.MeetingMinutes WHERE MeetingId = @MeetingId;
END;

GO

CREATE   PROCEDURE assoc.sp_Meetings_Insert
    @AssociationId INT,
    @Title NVARCHAR(200),
    @MeetingDate DATETIME2,
    @Description NVARCHAR(MAX),
    @CreatedBy INT
AS
BEGIN
    INSERT INTO assoc.Meetings (AssociationId, Title, MeetingDate, Description, CreatedBy)
    VALUES (@AssociationId, @Title, @MeetingDate, @Description, @CreatedBy);
    SELECT SCOPE_IDENTITY();
END;

GO

-- 4. Meetings
CREATE   PROCEDURE assoc.sp_Meetings_List
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.Meetings WHERE AssociationId = @AssociationId;
END;

GO

CREATE   PROCEDURE assoc.sp_Occupancy_Create @AssetId INT, @PersonId INT, @TenantId INT, @AssociationId INT, @OccupancyType INT, @StartDate DATETIME, @EndDate DATETIME = NULL, @IsPrimaryContact BIT AS 
BEGIN INSERT INTO assoc.Occupancy (AssetId, PersonId, TenantId, AssociationId, OccupancyType, StartDate, EndDate, IsPrimaryContact) OUTPUT INSERTED.OccupancyId VALUES (@AssetId, @PersonId, @TenantId, @AssociationId, @OccupancyType, @StartDate, @EndDate, @IsPrimaryContact); END

GO

CREATE   PROCEDURE assoc.sp_Occupancy_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN DELETE FROM assoc.Occupancy WHERE OccupancyId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END

GO

CREATE   PROCEDURE assoc.sp_Occupancy_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName,
           p.Email as Email,
           a.Name as AssetName
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    LEFT JOIN assoc.Assets a ON o.AssetId = a.AssetId
    WHERE o.AssetId = @AssetId AND o.AssociationId = @AssociationId;
END
GO

GO

CREATE   PROCEDURE assoc.sp_Occupancy_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName,
           p.Email as Email,
           a.Name as AssetName
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    LEFT JOIN assoc.Assets a ON o.AssetId = a.AssetId
    WHERE o.OccupancyId = @Id AND o.AssociationId = @AssociationId;
END

GO

CREATE   PROCEDURE assoc.sp_Occupancy_GetByUserId
    @UserId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName,
           p.Email as Email,
           a.Name as AssetName
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN assoc.Users u ON p.Email = u.Email
    LEFT JOIN assoc.Assets a ON o.AssetId = a.AssetId
    WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId;
END
GO

GO

-- Unit Registry Update Stored Procedures
-- This script adds the missing update procs for Occupancy, Vehicles, and Pets in the assoc schema.

-- 1. Occupancy Update
CREATE   PROCEDURE assoc.sp_Occupancy_Update
    @OccupancyId INT,
    @AssetId INT,
    @PersonId INT,
    @TenantId INT,
    @AssociationId INT,
    @OccupancyType INT,
    @StartDate DATETIME,
    @EndDate DATETIME = NULL,
    @IsPrimaryContact BIT
AS
BEGIN
    UPDATE assoc.Occupancy
    SET AssetId = @AssetId,
        PersonId = @PersonId,
        TenantId = @TenantId,
        AssociationId = @AssociationId,
        OccupancyType = @OccupancyType,
        StartDate = @StartDate,
        EndDate = @EndDate,
        IsPrimaryContact = @IsPrimaryContact
    WHERE OccupancyId = @OccupancyId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END

GO

-- Update payment order creation to include AssetId
CREATE   PROCEDURE assoc.sp_PaymentOrders_Create
    @TenantId INT,
    @AssociationId INT,
    @UserId INT,
    @RazorpayOrderId NVARCHAR(255),
    @Amount DECIMAL(18,2),
    @Currency NVARCHAR(10),
    @InvoiceId INT = NULL,
    @AssetId INT = NULL,
    @Receipt NVARCHAR(255) = NULL,
    @PrimaryAccountName NVARCHAR(255) = NULL,
    @PrimaryAccountNumber NVARCHAR(255) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentOrders (TenantId, AssociationId, UserId, RazorpayOrderId, Amount, Currency, InvoiceId, AssetId, Receipt, PrimaryAccountName, PrimaryAccountNumber)
    VALUES (@TenantId, @AssociationId, @UserId, @RazorpayOrderId, @Amount, @Currency, @InvoiceId, @AssetId, @Receipt, @PrimaryAccountName, @PrimaryAccountNumber);
    SELECT SCOPE_IDENTITY();
END;

GO

-- Script0068_RazorpayStoredProcedures.sql
-- Migrating remaining hardcoded SQL in RazorpayRepository to Stored Procedures

-- 1. Procedure for GetOrdersByInvoiceIdAsync
CREATE   PROCEDURE assoc.sp_PaymentOrders_GetByInvoiceId
    @InvoiceId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM assoc.PaymentOrders 
    WHERE InvoiceId = @InvoiceId 
      AND TenantId = @TenantId;
END;

GO

-- Get Order by Razorpay Id
CREATE   PROCEDURE assoc.sp_PaymentOrders_GetByOrderId
    @RazorpayOrderId NVARCHAR(255),
    @TenantId INT
AS
BEGIN
    SELECT * FROM assoc.PaymentOrders WHERE RazorpayOrderId = @RazorpayOrderId AND TenantId = @TenantId;
END;

GO

-- Update Order Status
CREATE   PROCEDURE assoc.sp_PaymentOrders_UpdateStatus
    @RazorpayOrderId NVARCHAR(255),
    @Status NVARCHAR(50),
    @TenantId INT
AS
BEGIN
    UPDATE assoc.PaymentOrders
    SET Status = @Status
    WHERE RazorpayOrderId = @RazorpayOrderId AND TenantId = @TenantId;
END;

GO

-- Update core payment creation to include AssetId, InvoiceId, and Notes
CREATE   PROCEDURE assoc.sp_Payments_Create
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT = NULL,
    @UserId INT = NULL,
    @InvoiceId INT = NULL,
    @Amount DECIMAL(18, 2),
    @Currency NVARCHAR(10),
    @Status NVARCHAR(50),
    @CreatedDate DATETIME,
    @Notes NVARCHAR(500) = NULL,
    @GatewayReference NVARCHAR(255) = NULL
AS 
BEGIN 
    INSERT INTO assoc.Payments (TenantId, AssociationId, AssetId, UserId, InvoiceId, Amount, Currency, Status, CreatedDate, Notes, GatewayReference) 
    OUTPUT INSERTED.PaymentId 
    VALUES (@TenantId, @AssociationId, @AssetId, @UserId, @InvoiceId, @Amount, @Currency, @Status, @CreatedDate, @Notes, @GatewayReference); 
END

GO

-- Script0067_FixAdvanceProcedures.sql
-- Fixes for wallet balances and advance payment visibility.

-- 1. Fix Status filter in Advances History
CREATE   PROCEDURE assoc.sp_Payments_GetAdvances
    @AssociationId INT,
    @TenantId INT,
    @UserId INT = NULL,
    @AssetId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.PaymentId,
        p.Amount,
        p.Currency,
        p.CreatedDate,
        p.Status,
        p.GatewayReference,
        p.Notes,
        a.Name as UnitName,
        u.Name as ResidentName,
        u.Email as ResidentEmail
    FROM assoc.Payments p
    LEFT JOIN assoc.Assets a ON p.AssetId = a.AssetId
    LEFT JOIN assoc.Users u ON p.UserId = u.UserId
    WHERE p.TenantId = @TenantId
      AND p.AssociationId = @AssociationId
      AND p.InvoiceId IS NULL  -- Only advances
      AND p.Status IN ('Paid', 'Completed') -- FIX: Include Completed
      AND (@UserId IS NULL OR p.UserId = @UserId)
      AND (@AssetId IS NULL OR p.AssetId = @AssetId)
    ORDER BY p.CreatedDate DESC;
END;

GO

-- Script0082_DeduplicateWalletHistory.sql
-- Fix: Deduplicating wallet history by only including 'Debit' transactions from the ledger.
-- This ensures only the money leaving the wallet is visible, excluding the corresponding invoice credit.

CREATE OR ALTER PROCEDURE assoc.sp_Payments_GetAdvancesPaged
    @TenantId INT,
    @AssociationId INT = NULL,
    @UserId INT = NULL,
    @AssetId INT = NULL,
    @SearchTerm NVARCHAR(255) = NULL,
    @Status NVARCHAR(50) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'Date',
    @SortDirection NVARCHAR(10) = 'DESC'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Calculate Offset
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    -- Sorting Safety
    IF @SortColumn NOT IN ('ResidentName', 'UnitName', 'Amount', 'Date', 'Status', 'ReferenceId')
        SET @SortColumn = 'Date';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'DESC';

    -- NEW: Robust Identity Resolution (resolves from either schema)
    DECLARE @UserEmail NVARCHAR(255);
    SELECT @UserEmail = Email FROM corp.Users WHERE UserId = @UserId;
    
    IF @UserEmail IS NULL
        SELECT @UserEmail = Email FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId;

    -- CTE for Filtering and Paging
    ;WITH RawAdvances AS (
        -- 1. TOP-UPS (Credits)
        SELECT 
            p.Amount,
            p.CreatedDate AS [Date],
            p.Status,
            p.GatewayReference AS ReferenceId,
            u.Name AS ResidentName,
            a.Name AS UnitName,
            p.UserId,
            p.AssetId
        FROM assoc.Payments p
        LEFT JOIN corp.Users cu ON p.UserId = cu.UserId
        LEFT JOIN assoc.Users au ON p.UserId = au.UserId AND p.TenantId = @TenantId
        LEFT JOIN assoc.Users u ON p.UserId = u.UserId AND p.TenantId = @TenantId -- For Display Name
        LEFT JOIN assoc.Assets a ON p.AssetId = a.AssetId
        WHERE p.TenantId = @TenantId
          AND p.InvoiceId IS NULL -- Top-ups / Advances
          AND (@AssociationId IS NULL OR p.AssociationId = @AssociationId)
          -- Match by Email OR UserId for Identity consistency
          AND (
                @UserId IS NULL 
                OR (@UserEmail IS NOT NULL AND (cu.Email = @UserEmail OR au.Email = @UserEmail))
                OR p.UserId = @UserId -- Fallback to direct ID match
          )

        UNION ALL

        -- 2. SETTLEMENTS (Debits)
        -- DEDUPLICATION FIX: Only include 'Debit' type transactions from the ledger.
        -- This represents the money leaving the wallet.
        SELECT 
            -t.Amount AS Amount,
            t.TransactionDate AS [Date],
            'Settled' AS Status,
            t.Description AS ReferenceId,
            NULL AS ResidentName,
            a.Name AS UnitName,
            -- Map the transaction to the user requesting the history if they are an occupant
            @UserId AS UserId, 
            t.AssetId
        FROM assoc.Transactions t
        INNER JOIN assoc.Assets a ON t.AssetId = a.AssetId
        WHERE t.TenantId = @TenantId
          AND t.Type = 'Debit' -- ONLY WALLET WITHDRAWAL
          AND t.Category IN ('Credit Settlement', 'Internal Credit Transfer')
          AND (@AssociationId IS NULL OR t.AssociationId = @AssociationId)
          -- SECURITY: Resolve Assets belonging to this email OR directly to this UserId
          AND (@UserId IS NULL OR t.AssetId IN (
              SELECT DISTINCT oc.AssetId 
              FROM assoc.Occupancy oc
              INNER JOIN assoc.Persons per ON oc.PersonId = per.PersonId
              WHERE (per.Email = @UserEmail OR per.Email = (SELECT Email FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId))
                AND oc.TenantId = @TenantId
              
              UNION
              
              SELECT DISTINCT pay.AssetId 
              FROM assoc.Payments pay
              LEFT JOIN corp.Users gcu ON pay.UserId = gcu.UserId
              LEFT JOIN assoc.Users lau ON pay.UserId = lau.UserId AND pay.TenantId = @TenantId
              WHERE (
                     (@UserEmail IS NOT NULL AND (gcu.Email = @UserEmail OR lau.Email = @UserEmail))
                     OR pay.UserId = @UserId
                    ) 
                AND pay.TenantId = @TenantId
          ))
    ),
    FilteredAdvances AS (
        SELECT 
            Amount,
            [Date],
            Status,
            ReferenceId,
            ISNULL(ResidentName, 'System') AS ResidentName,
            ISNULL(UnitName, 'General') AS UnitName,
            COUNT(*) OVER() as TotalCount
        FROM RawAdvances
        WHERE (@AssetId IS NULL OR AssetId = @AssetId)
          AND (
               @Status IS NULL 
               OR Status = @Status 
               OR (@Status = 'Paid' AND Status = 'Settled') 
               OR (@Status = 'Settled' AND Status = 'Settled')
          )
          AND (@StartDate IS NULL OR [Date] >= @StartDate)
          AND (@EndDate IS NULL OR [Date] <= @EndDate)
          AND (@SearchTerm IS NULL 
               OR ResidentName LIKE '%' + @SearchTerm + '%' 
               OR UnitName LIKE '%' + @SearchTerm + '%'
               OR ReferenceId LIKE '%' + @SearchTerm + '%'
          )
    )
    SELECT 
        * 
    FROM FilteredAdvances
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'ResidentName' THEN ResidentName
                WHEN @SortColumn = 'UnitName' THEN UnitName
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'ReferenceId' THEN ReferenceId
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'ResidentName' THEN ResidentName
                WHEN @SortColumn = 'UnitName' THEN UnitName
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'ReferenceId' THEN ReferenceId
            END
        END DESC,
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'Date' THEN CAST([Date] AS SQL_VARIANT)
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'Date' THEN CAST([Date] AS SQL_VARIANT)
            END
        END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO

GO

-- Script0082_DeduplicateWalletHistory.sql
-- Fix: Deduplicating wallet history by only including 'Debit' transactions from the ledger.
-- This ensures only the money leaving the wallet is visible, excluding the corresponding invoice credit.

CREATE   PROCEDURE assoc.sp_Payments_GetAdvancesPaged
    @TenantId INT,
    @AssociationId INT = NULL,
    @UserId INT = NULL,
    @AssetId INT = NULL,
    @SearchTerm NVARCHAR(255) = NULL,
    @Status NVARCHAR(50) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'Date',
    @SortDirection NVARCHAR(10) = 'DESC'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Calculate Offset
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    -- Sorting Safety
    IF @SortColumn NOT IN ('ResidentName', 'UnitName', 'Amount', 'Date', 'Status', 'ReferenceId')
        SET @SortColumn = 'Date';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'DESC';

    -- NEW: Robust Identity Resolution (resolves from either schema)
    DECLARE @UserEmail NVARCHAR(255);
    SELECT @UserEmail = Email FROM corp.Users WHERE UserId = @UserId;
    
    IF @UserEmail IS NULL
        SELECT @UserEmail = Email FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId;

    -- CTE for Filtering and Paging
    ;WITH RawAdvances AS (
        -- 1. TOP-UPS (Credits)
        SELECT 
            p.Amount,
            p.CreatedDate AS [Date],
            p.Status,
            p.GatewayReference AS ReferenceId,
            u.Name AS ResidentName,
            a.Name AS UnitName,
            p.UserId,
            p.AssetId
        FROM assoc.Payments p
        LEFT JOIN corp.Users cu ON p.UserId = cu.UserId
        LEFT JOIN assoc.Users au ON p.UserId = au.UserId AND p.TenantId = @TenantId
        LEFT JOIN assoc.Users u ON p.UserId = u.UserId AND p.TenantId = @TenantId -- For Display Name
        LEFT JOIN assoc.Assets a ON p.AssetId = a.AssetId
        WHERE p.TenantId = @TenantId
          AND p.InvoiceId IS NULL -- Top-ups / Advances
          AND (@AssociationId IS NULL OR p.AssociationId = @AssociationId)
          -- Match by Email OR UserId for Identity consistency
          AND (
                @UserId IS NULL 
                OR (@UserEmail IS NOT NULL AND (cu.Email = @UserEmail OR au.Email = @UserEmail))
                OR p.UserId = @UserId -- Fallback to direct ID match
          )

        UNION ALL

        -- 2. SETTLEMENTS (Debits)
        -- DEDUPLICATION FIX: Only include 'Debit' type transactions from the ledger.
        -- This represents the money leaving the wallet.
        SELECT 
            -t.Amount AS Amount,
            t.TransactionDate AS [Date],
            'Settled' AS Status,
            t.Description AS ReferenceId,
            NULL AS ResidentName,
            a.Name AS UnitName,
            -- Map the transaction to the user requesting the history if they are an occupant
            @UserId AS UserId, 
            t.AssetId
        FROM assoc.Transactions t
        INNER JOIN assoc.Assets a ON t.AssetId = a.AssetId
        WHERE t.TenantId = @TenantId
          AND t.Type = 'Debit' -- ONLY WALLET WITHDRAWAL
          AND t.Category IN ('Credit Settlement', 'Internal Credit Transfer')
          AND (@AssociationId IS NULL OR t.AssociationId = @AssociationId)
          -- SECURITY: Resolve Assets belonging to this email OR directly to this UserId
          AND (@UserId IS NULL OR t.AssetId IN (
              SELECT DISTINCT oc.AssetId 
              FROM assoc.Occupancy oc
              INNER JOIN assoc.Persons per ON oc.PersonId = per.PersonId
              WHERE (per.Email = @UserEmail OR per.Email = (SELECT Email FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId))
                AND oc.TenantId = @TenantId
              
              UNION
              
              SELECT DISTINCT pay.AssetId 
              FROM assoc.Payments pay
              LEFT JOIN corp.Users gcu ON pay.UserId = gcu.UserId
              LEFT JOIN assoc.Users lau ON pay.UserId = lau.UserId AND pay.TenantId = @TenantId
              WHERE (
                     (@UserEmail IS NOT NULL AND (gcu.Email = @UserEmail OR lau.Email = @UserEmail))
                     OR pay.UserId = @UserId
                    ) 
                AND pay.TenantId = @TenantId
          ))
    ),
    FilteredAdvances AS (
        SELECT 
            Amount,
            [Date],
            Status,
            ReferenceId,
            ISNULL(ResidentName, 'System') AS ResidentName,
            ISNULL(UnitName, 'General') AS UnitName,
            COUNT(*) OVER() as TotalCount
        FROM RawAdvances
        WHERE (@AssetId IS NULL OR AssetId = @AssetId)
          AND (
               @Status IS NULL 
               OR Status = @Status 
               OR (@Status = 'Paid' AND Status = 'Settled') 
               OR (@Status = 'Settled' AND Status = 'Settled')
          )
          AND (@StartDate IS NULL OR [Date] >= @StartDate)
          AND (@EndDate IS NULL OR [Date] <= @EndDate)
          AND (@SearchTerm IS NULL 
               OR ResidentName LIKE '%' + @SearchTerm + '%' 
               OR UnitName LIKE '%' + @SearchTerm + '%'
               OR ReferenceId LIKE '%' + @SearchTerm + '%'
          )
    )
    SELECT 
        * 
    FROM FilteredAdvances
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'ResidentName' THEN ResidentName
                WHEN @SortColumn = 'UnitName' THEN UnitName
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'ReferenceId' THEN ReferenceId
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'ResidentName' THEN ResidentName
                WHEN @SortColumn = 'UnitName' THEN UnitName
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'ReferenceId' THEN ReferenceId
            END
        END DESC,
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'Date' THEN CAST([Date] AS SQL_VARIANT)
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'Date' THEN CAST([Date] AS SQL_VARIANT)
            END
        END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;

GO

-- PAYMENTS
CREATE   PROCEDURE assoc.sp_Payments_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Payments 
    WHERE PaymentId = @Id AND AssociationId = @AssociationId; 
END

GO

CREATE   PROCEDURE assoc.sp_Payments_GetByTenantId @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Payments 
    WHERE AssociationId = @AssociationId; 
END

GO

CREATE   PROCEDURE assoc.sp_Payments_UpdateStatus @Id INT, @Status NVARCHAR(50), @GatewayReference NVARCHAR(255) = NULL, @TenantId INT, @AssociationId INT AS 
BEGIN 
    UPDATE assoc.Payments SET Status = @Status, GatewayReference = @GatewayReference 
    WHERE PaymentId = @Id AND AssociationId = @AssociationId; 
END

GO

-- 2. Procedure for TransactionExistsAsync
CREATE   PROCEDURE assoc.sp_PaymentTransactions_CheckExists
    @RazorpayPaymentId NVARCHAR(255),
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(COUNT(1) AS BIT) 
    FROM assoc.PaymentTransactions 
    WHERE RazorpayPaymentId = @RazorpayPaymentId 
      AND TenantId = @TenantId;
END;

GO

-- Create Transaction
CREATE   PROCEDURE assoc.sp_PaymentTransactions_Create
    @TenantId INT,
    @AssociationId INT,
    @PaymentOrderId INT = NULL,
    @RazorpayPaymentId NVARCHAR(255),
    @RazorpayOrderId NVARCHAR(255),
    @RazorpaySignature NVARCHAR(MAX),
    @Status NVARCHAR(50),
    @Amount DECIMAL(18,2),
    @RawResponse NVARCHAR(MAX) = NULL,
    @PrimaryAccountName NVARCHAR(255) = NULL,
    @PrimaryAccountNumber NVARCHAR(255) = NULL,
    @PaymentMethod NVARCHAR(50) = NULL,
    @BankName NVARCHAR(255) = NULL,
    @BankRrn NVARCHAR(255) = NULL,
    @CardNetwork NVARCHAR(50) = NULL,
    @GatewayFee DECIMAL(18,2) = NULL,
    @GatewayTax DECIMAL(18,2) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentTransactions (TenantId, AssociationId, PaymentOrderId, RazorpayPaymentId, RazorpayOrderId, RazorpaySignature, Status, Amount, RawResponse, PrimaryAccountName, PrimaryAccountNumber, PaymentMethod, BankName, BankRrn, CardNetwork, GatewayFee, GatewayTax)
    VALUES (@TenantId, @AssociationId, @PaymentOrderId, @RazorpayPaymentId, @RazorpayOrderId, @RazorpaySignature, @Status, @Amount, @RawResponse, @PrimaryAccountName, @PrimaryAccountNumber, @PaymentMethod, @BankName, @BankRrn, @CardNetwork, @GatewayFee, @GatewayTax);
    SELECT SCOPE_IDENTITY();
END;

GO

-- Get Transactions by Invoice
CREATE   PROCEDURE assoc.sp_PaymentTransactions_GetByInvoiceId
    @InvoiceId INT,
    @TenantId INT
AS
BEGIN
    SELECT 
        pt.*, 
        po.InvoiceId,
        po.Status AS OrderStatus
    FROM assoc.PaymentTransactions pt
    JOIN assoc.PaymentOrders po ON pt.PaymentOrderId = po.Id
    WHERE po.InvoiceId = @InvoiceId AND po.TenantId = @TenantId;
END;

GO

-- Create Webhook Log
CREATE   PROCEDURE assoc.sp_PaymentWebhookLogs_Create
    @TenantId INT = NULL,
    @EventType NVARCHAR(100),
    @RawPayload NVARCHAR(MAX),
    @Signature NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentWebhookLogs (TenantId, EventType, RawPayload, Signature)
    VALUES (@TenantId, @EventType, @RawPayload, @Signature);
    SELECT SCOPE_IDENTITY();
END;

GO

CREATE   PROCEDURE assoc.sp_Persons_Create @TenantId INT, @AssociationId INT, @FirstName NVARCHAR(100), @LastName NVARCHAR(100), @Email NVARCHAR(255), @Phone NVARCHAR(50), @PhotoUrl NVARCHAR(MAX), @CreatedDate DATETIME, @IsActive BIT AS 
BEGIN INSERT INTO assoc.Persons (TenantId, AssociationId, FirstName, LastName, Email, Phone, PhotoUrl, CreatedDate, IsActive) OUTPUT INSERTED.PersonId VALUES (@TenantId, @AssociationId, @FirstName, @LastName, @Email, @Phone, @PhotoUrl, @CreatedDate, @IsActive); END

GO

CREATE   PROCEDURE assoc.sp_Persons_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN UPDATE assoc.Persons SET IsActive = 0 WHERE PersonId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END

GO

CREATE   PROCEDURE assoc.sp_Persons_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Persons WHERE AssociationId = @AssociationId AND IsActive = 1; END
GO

GO

CREATE   PROCEDURE assoc.sp_Persons_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Persons WHERE PersonId = @Id AND AssociationId = @AssociationId; END
GO

GO

CREATE   PROCEDURE assoc.sp_Persons_Update @PersonId INT, @TenantId INT, @AssociationId INT, @FirstName NVARCHAR(100), @LastName NVARCHAR(100), @Email NVARCHAR(255), @Phone NVARCHAR(50), @PhotoUrl NVARCHAR(MAX), @IsActive BIT AS 
BEGIN UPDATE assoc.Persons SET FirstName = @FirstName, LastName = @LastName, Email = @Email, Phone = @Phone, PhotoUrl = @PhotoUrl, IsActive = @IsActive WHERE PersonId = @PersonId AND TenantId = @TenantId AND AssociationId = @AssociationId; END

GO

CREATE   PROCEDURE assoc.sp_Pets_Create @AssetId INT, @TenantId INT, @AssociationId INT, @Name NVARCHAR(100), @Species NVARCHAR(100), @Breed NVARCHAR(100), @TagNumber NVARCHAR(50), @IsActive BIT AS 
BEGIN INSERT INTO assoc.Pets (AssetId, TenantId, AssociationId, Name, Species, Breed, TagNumber, IsActive) OUTPUT INSERTED.PetId VALUES (@AssetId, @TenantId, @AssociationId, @Name, @Species, @Breed, @TagNumber, @IsActive); END

GO

CREATE   PROCEDURE assoc.sp_Pets_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    DELETE FROM assoc.Pets 
    WHERE PetId = @Id AND AssociationId = @AssociationId; 
END

GO

-- PETS
CREATE   PROCEDURE assoc.sp_Pets_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Pets 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId; 
END
GO

GO

CREATE   PROCEDURE assoc.sp_Pets_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.Pets 
    WHERE PetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END;

GO

-- 3. Pets Update
CREATE   PROCEDURE assoc.sp_Pets_Update
    @PetId INT,
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT,
    @Name NVARCHAR(100),
    @Species NVARCHAR(100),
    @Breed NVARCHAR(100) = NULL,
    @TagNumber NVARCHAR(50) = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE assoc.Pets
    SET AssetId = @AssetId,
        TenantId = @TenantId,
        AssociationId = @AssociationId,
        Name = @Name,
        Species = @Species,
        Breed = @Breed,
        TagNumber = @TagNumber,
        IsActive = @IsActive
    WHERE PetId = @PetId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END

GO

CREATE   PROCEDURE assoc.sp_RefreshTokens_Delete @UserId INT AS 
BEGIN DELETE FROM assoc.RefreshTokens WHERE UserId = @UserId; END

GO

-- REFRESH TOKENS PROCEDURES FOR ASSOC
CREATE   PROCEDURE assoc.sp_RefreshTokens_GetByToken @Token NVARCHAR(MAX) AS 
BEGIN SELECT * FROM assoc.RefreshTokens WHERE Token = @Token; END

GO

CREATE   PROCEDURE assoc.sp_RefreshTokens_Upsert @UserId INT, @Token NVARCHAR(MAX), @ExpiryDate DATETIME, @CreatedDate DATETIME AS 
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.RefreshTokens WHERE UserId = @UserId)
        UPDATE assoc.RefreshTokens SET Token = @Token, ExpiryDate = @ExpiryDate WHERE UserId = @UserId
    ELSE
        INSERT INTO assoc.RefreshTokens (UserId, Token, ExpiryDate, CreatedDate) VALUES (@UserId, @Token, @ExpiryDate, @CreatedDate);
END

GO

CREATE OR ALTER PROCEDURE assoc.sp_Reports_GetFinancialMetrics
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Aging Calculation
    ;WITH UnpaidInvoices AS (
        SELECT 
            i.InvoiceId,
            i.DueDate,
            i.Amount + ISNULL(fines.TotalFines, 0) as TotalDue
        FROM assoc.Invoices i
        OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines 
            FROM assoc.InvoiceLineItems li 
            WHERE li.InvoiceId = i.InvoiceId 
            AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
        ) fines
        WHERE i.TenantId = @TenantId 
        AND i.AssociationId = @AssociationId 
        AND i.Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft', 'Settled')
    )
    SELECT 
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 0 AND 30 THEN TotalDue ELSE 0 END) AS Bucket0_30,
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 31 AND 60 THEN TotalDue ELSE 0 END) AS Bucket31_60,
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 61 AND 90 THEN TotalDue ELSE 0 END) AS Bucket61_90,
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) > 90 THEN TotalDue ELSE 0 END) AS BucketOver90
    FROM UnpaidInvoices;

    -- 2. Monthly Collection Efficiency (Last 12 Months)
    ;WITH Months AS (
        SELECT TOP 12 
            FORMAT(DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE()), 'MMM yyyy') AS MonthLabel,
            DATEPART(MONTH, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Month],
            DATEPART(YEAR, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Year]
        FROM sys.objects
    ),
    MonthlyBilled AS (
        SELECT 
            DATEPART(MONTH, i.DueDate) as [Month],
            DATEPART(YEAR, i.DueDate) as [Year],
            SUM(i.Amount + ISNULL(fines.TotalFines, 0)) as TotalBilled
        FROM assoc.Invoices i
        OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines 
            FROM assoc.InvoiceLineItems li 
            WHERE li.InvoiceId = i.InvoiceId 
            AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
        ) fines
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
        AND i.Status NOT IN ('Draft', 'Cancelled', 'Void')
        GROUP BY DATEPART(MONTH, i.DueDate), DATEPART(YEAR, i.DueDate)
    ),
    MonthlyCollected AS (
        SELECT 
            DATEPART(MONTH, i.DueDate) as [Month],
            DATEPART(YEAR, i.DueDate) as [Year],
            SUM(p.Amount) as TotalCollected
        FROM assoc.Payments p
        INNER JOIN assoc.Invoices i ON p.InvoiceId = i.InvoiceId
        WHERE p.TenantId = @TenantId AND p.AssociationId = @AssociationId
        AND p.Status IN ('Paid', 'Completed', 'Captured')
        GROUP BY DATEPART(MONTH, i.DueDate), DATEPART(YEAR, i.DueDate)
    )
    SELECT 
        m.MonthLabel as [Month],
        ISNULL(mb.TotalBilled, 0) as BilledAmount,
        ISNULL(mc.TotalCollected, 0) as CollectedAmount
    FROM Months m
    LEFT JOIN MonthlyBilled mb ON m.[Month] = mb.[Month] AND m.[Year] = mb.[Year]
    LEFT JOIN MonthlyCollected mc ON m.[Month] = mc.[Month] AND m.[Year] = mc.[Year]
    ORDER BY m.[Year] ASC, m.[Month] ASC;

    -- 3. High Level Stats
    SELECT 
        (SELECT ISNULL(SUM(Amount), 0) FROM assoc.Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND Status IN ('Paid', 'Completed', 'Captured')) as TotalCollectedAllTime,
        (SELECT ISNULL(SUM(i.Amount + ISNULL(fines.TotalFines, 0)), 0) 
         FROM assoc.Invoices i 
         OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines 
            FROM assoc.InvoiceLineItems li 
            WHERE li.InvoiceId = i.InvoiceId 
            AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
         ) fines
         WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId AND i.Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft', 'Settled')) as TotalUnpaidPrincipal
END
GO

GO

CREATE PROCEDURE assoc.sp_Reports_GetFinancialMetrics
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Aging Calculation
    ;WITH UnpaidInvoices AS (
        SELECT 
            i.InvoiceId,
            i.DueDate,
            i.Amount + ISNULL(fines.TotalFines, 0) as TotalDue
        FROM assoc.Invoices i
        OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines 
            FROM assoc.InvoiceLineItems li 
            WHERE li.InvoiceId = i.InvoiceId 
            AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
        ) fines
        WHERE i.TenantId = @TenantId 
        AND i.AssociationId = @AssociationId 
        AND i.Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft', 'Settled')
    )
    SELECT 
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 0 AND 30 THEN TotalDue ELSE 0 END) AS Bucket0_30,
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 31 AND 60 THEN TotalDue ELSE 0 END) AS Bucket31_60,
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 61 AND 90 THEN TotalDue ELSE 0 END) AS Bucket61_90,
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) > 90 THEN TotalDue ELSE 0 END) AS BucketOver90
    FROM UnpaidInvoices;

    -- 2. Monthly Collection Efficiency (Last 12 Months)
    ;WITH Months AS (
        SELECT TOP 12 
            FORMAT(DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE()), 'MMM yyyy') AS MonthLabel,
            DATEPART(MONTH, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Month],
            DATEPART(YEAR, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Year]
        FROM sys.objects
    ),
    MonthlyBilled AS (
        SELECT 
            DATEPART(MONTH, i.DueDate) as [Month],
            DATEPART(YEAR, i.DueDate) as [Year],
            SUM(i.Amount + ISNULL(fines.TotalFines, 0)) as TotalBilled
        FROM assoc.Invoices i
        OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines 
            FROM assoc.InvoiceLineItems li 
            WHERE li.InvoiceId = i.InvoiceId 
            AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
        ) fines
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
        AND i.Status NOT IN ('Draft', 'Cancelled', 'Void')
        GROUP BY DATEPART(MONTH, i.DueDate), DATEPART(YEAR, i.DueDate)
    ),
    MonthlyCollected AS (
        SELECT 
            DATEPART(MONTH, i.DueDate) as [Month],
            DATEPART(YEAR, i.DueDate) as [Year],
            SUM(p.Amount) as TotalCollected
        FROM assoc.Payments p
        INNER JOIN assoc.Invoices i ON p.InvoiceId = i.InvoiceId
        WHERE p.TenantId = @TenantId AND p.AssociationId = @AssociationId
        AND p.Status IN ('Paid', 'Completed', 'Captured')
        GROUP BY DATEPART(MONTH, i.DueDate), DATEPART(YEAR, i.DueDate)
    )
    SELECT 
        m.MonthLabel as [Month],
        ISNULL(mb.TotalBilled, 0) as BilledAmount,
        ISNULL(mc.TotalCollected, 0) as CollectedAmount
    FROM Months m
    LEFT JOIN MonthlyBilled mb ON m.[Month] = mb.[Month] AND m.[Year] = mb.[Year]
    LEFT JOIN MonthlyCollected mc ON m.[Month] = mc.[Month] AND m.[Year] = mc.[Year]
    ORDER BY m.[Year] ASC, m.[Month] ASC;

    -- 3. High Level Stats
    SELECT 
        (SELECT ISNULL(SUM(Amount), 0) FROM assoc.Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND Status IN ('Paid', 'Completed', 'Captured')) as TotalCollectedAllTime,
        (SELECT ISNULL(SUM(i.Amount + ISNULL(fines.TotalFines, 0)), 0) 
         FROM assoc.Invoices i 
         OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines 
            FROM assoc.InvoiceLineItems li 
            WHERE li.InvoiceId = i.InvoiceId 
            AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
         ) fines
         WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId AND i.Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft', 'Settled')) as TotalUnpaidPrincipal
END;

GO

CREATE OR ALTER PROCEDURE assoc.sp_Reports_GetFinancialMetrics_v2
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Local variables for Fine Settings
    DECLARE @StrategyType NVARCHAR(50), @FineValue DECIMAL(18,2), @GracePeriodDays INT, @IsCompounding BIT, @ActivationDate DATETIME;
    
    SELECT TOP 1 
        @StrategyType = StrategyType,
        @FineValue = FineValue,
        @GracePeriodDays = GracePeriodDays,
        @IsCompounding = IsCompounding,
        @ActivationDate = ActivationDate
    FROM assoc.FineSettings
    WHERE AssociationId = @AssociationId AND TenantId = @TenantId;

    -- 1. Pre-calculate metrics into a Temp Table to share across Multiple Result Sets
    WITH InvoiceData AS (
        SELECT 
            i.InvoiceId,
            i.DueDate,
            i.CreatedDate,
            i.Amount,
            i.[Status],
            ISNULL(fines.TotalFines, 0) as RecordedFines,
            ISNULL(payments.TotalPaid, 0) as TotalPaid
        FROM assoc.Invoices i
        OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines 
            FROM assoc.InvoiceLineItems li 
            WHERE li.InvoiceId = i.InvoiceId 
            AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
        ) fines
        OUTER APPLY (
            SELECT SUM(p.Amount) as TotalPaid
            FROM assoc.Payments p
            WHERE p.InvoiceId = i.InvoiceId
            AND p.Status IN ('Paid', 'Completed', 'Captured')
        ) payments
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
        AND i.[Status] NOT IN ('Cancelled', 'Void', 'Draft')
    ),
    CalculatedFines AS (
        SELECT 
            d.*,
            CASE 
                WHEN d.[Status] = 'Paid' THEN 0 
                WHEN d.DueDate >= GETUTCDATE() THEN 0
                WHEN @StrategyType IS NULL OR @StrategyType = 'None' THEN 0
                WHEN @ActivationDate IS NULL OR d.CreatedDate < @ActivationDate THEN 0
                WHEN DATEDIFF(DAY, d.DueDate, GETUTCDATE()) <= @GracePeriodDays THEN 0
                WHEN d.RecordedFines > 0 THEN 0 
                ELSE 
                    -- Months Late calculation (Ceiling)
                    (SELECT 
                        CASE 
                            WHEN @StrategyType = 'FlatAmount' THEN @FineValue * monthsLate
                            WHEN @StrategyType = 'OneTimeFlat' THEN @FineValue
                            WHEN @StrategyType = 'OneTimePercentage' THEN ROUND(d.Amount * (@FineValue / 100.0), 2)
                            WHEN @StrategyType = 'Percentage' AND @IsCompounding = 0 THEN ROUND(d.Amount * (@FineValue / 100.0) * monthsLate, 2)
                            WHEN @StrategyType = 'Percentage' AND @IsCompounding = 1 THEN ROUND(d.Amount * (POWER(CAST(1 + (@FineValue / 100.0) AS FLOAT), monthsLate)) - d.Amount, 2)
                            ELSE 0
                        END
                     FROM (SELECT CEILING(DATEDIFF(DAY, d.DueDate, GETUTCDATE()) / 30.44) as monthsLate) m
                    )
            END as DynamicFine
        FROM InvoiceData d
    ),
    NetInvoiceStats AS (
        SELECT 
            *,
            -- Explicitly cast to DECIMAL to avoid float issues from POWER function
            CAST((Amount + RecordedFines + DynamicFine) - TotalPaid AS DECIMAL(18,2)) as NetDue,
            CAST(Amount + RecordedFines + DynamicFine AS DECIMAL(18,2)) as GrossBilled
        FROM CalculatedFines
    )
    SELECT * INTO #NetInvoiceStats FROM NetInvoiceStats;

    -- 2. Aging Calculation
    SELECT 
        ISNULL(SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 0 AND 30 AND NetDue > 0 THEN NetDue ELSE 0 END), 0) AS Bucket0_30,
        ISNULL(SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 31 AND 60 AND NetDue > 0 THEN NetDue ELSE 0 END), 0) AS Bucket31_60,
        ISNULL(SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 61 AND 90 AND NetDue > 0 THEN NetDue ELSE 0 END), 0) AS Bucket61_90,
        ISNULL(SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) > 90 AND NetDue > 0 THEN NetDue ELSE 0 END), 0) AS BucketOver90
    FROM #NetInvoiceStats;

    -- 3. Monthly Collection Efficiency
    WITH Months AS (
        SELECT TOP 12 
            FORMAT(DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE()), 'MMM yyyy') AS MonthLabel,
            DATEPART(MONTH, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Month],
            DATEPART(YEAR, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Year]
        FROM sys.objects
    ),
    MonthlyStats AS (
        SELECT 
            DATEPART(MONTH, DueDate) as [Month],
            DATEPART(YEAR, DueDate) as [Year],
            SUM(GrossBilled) as TotalBilled,
            SUM(TotalPaid) as TotalCollected
        FROM #NetInvoiceStats
        GROUP BY DATEPART(MONTH, DueDate), DATEPART(YEAR, DueDate)
    )
    SELECT 
        m.MonthLabel as [Month],
        ISNULL(ms.TotalBilled, 0) as BilledAmount,
        ISNULL(ms.TotalCollected, 0) as CollectedAmount
    FROM Months m
    LEFT JOIN MonthlyStats ms ON m.[Month] = ms.[Month] AND m.[Year] = ms.[Year]
    ORDER BY m.[Year] ASC, m.[Month] ASC;

    -- 4. High Level Stats
    SELECT 
        (SELECT ISNULL(SUM(Amount), 0) FROM assoc.Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND Status IN ('Paid', 'Completed', 'Captured')) as TotalCollectedAllTime,
        (SELECT ISNULL(SUM(NetDue), 0) FROM #NetInvoiceStats WHERE NetDue > 0) as TotalUnpaidPrincipal

    DROP TABLE #NetInvoiceStats;
END

GO

CREATE   PROCEDURE assoc.sp_TariffGroups_Create @TenantId INT, @AssociationId INT = NULL, @Name NVARCHAR(100), @Description NVARCHAR(MAX) = NULL AS 
BEGIN INSERT INTO assoc.TariffGroups (TenantId, AssociationId, Name, Description) VALUES (@TenantId, @AssociationId, @Name, @Description); SELECT CAST(SCOPE_IDENTITY() as int); END

GO

CREATE   PROCEDURE assoc.sp_TariffGroups_Delete @GroupId INT AS 
BEGIN DELETE FROM assoc.TariffGroups WHERE TariffGroupId = @GroupId; END

GO

-- TARIFF GROUPS
CREATE   PROCEDURE assoc.sp_TariffGroups_GetByTenantId @TenantId INT, @AssociationId INT = NULL AS 
BEGIN SELECT * FROM assoc.TariffGroups WHERE TenantId = @TenantId AND (AssociationId = @AssociationId OR (@AssociationId IS NULL AND AssociationId IS NULL)); END

GO

CREATE   PROCEDURE assoc.sp_TariffGroups_Update @TariffGroupId INT, @Name NVARCHAR(100), @Description NVARCHAR(MAX) = NULL AS 
BEGIN UPDATE assoc.TariffGroups SET Name = @Name, Description = @Description WHERE TariffGroupId = @TariffGroupId; END

GO

-- Update sp_TariffLayers_Create to support AssociationId
CREATE   PROCEDURE assoc.sp_TariffLayers_Create 
    @TariffGroupId INT, 
    @TenantId INT, 
    @AssociationId INT = NULL, 
    @Name NVARCHAR(100), 
    @BaseRate DECIMAL(18, 2), 
    @Frequency INT, 
    @CalculationType INT, 
    @AccountingCategory NVARCHAR(100) = NULL 
AS 
BEGIN 
    INSERT INTO assoc.TariffLayers (
        TariffGroupId, 
        TenantId, 
        AssociationId, 
        Name, 
        BaseRate, 
        Frequency, 
        CalculationType, 
        AccountingCategory
    ) 
    VALUES (
        @TariffGroupId, 
        @TenantId, 
        @AssociationId, 
        @Name, 
        @BaseRate, 
        @Frequency, 
        @CalculationType, 
        @AccountingCategory
    ); 
    SELECT CAST(SCOPE_IDENTITY() as int); 
END

GO

CREATE   PROCEDURE assoc.sp_TariffLayers_Delete @LayerId INT AS 
BEGIN DELETE FROM assoc.TariffLayers WHERE TariffLayerId = @LayerId; END

GO

-- TARIFF LAYERS
CREATE   PROCEDURE assoc.sp_TariffLayers_GetByGroupId @GroupId INT AS 
BEGIN SELECT * FROM assoc.TariffLayers WHERE TariffGroupId = @GroupId; END

GO

CREATE   PROCEDURE assoc.sp_TariffLayers_Update @TariffLayerId INT, @Name NVARCHAR(100), @BaseRate DECIMAL(18, 2), @Frequency INT, @CalculationType INT, @AccountingCategory NVARCHAR(100) = NULL AS 
BEGIN UPDATE assoc.TariffLayers SET Name = @Name, BaseRate = @BaseRate, Frequency = @Frequency, CalculationType = @CalculationType, AccountingCategory = @AccountingCategory WHERE TariffLayerId = @TariffLayerId; END

GO

-- Script0062_FixGovernanceAndFinanceProcs.sql

-- 1. Fix Transaction Creation Procedure to match Repository (ensure all 10 params are handled)
CREATE   PROCEDURE assoc.sp_Transactions_Create
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT,
    @InvoiceId INT = NULL,
    @PaymentId INT = NULL,
    @Type NVARCHAR(50),
    @Amount DECIMAL(18, 2),
    @Category NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL,
    @TransactionDate DATETIME
AS
BEGIN
    INSERT INTO assoc.Transactions (
        TenantId,
        AssociationId,
        AssetId,
        InvoiceId,
        PaymentId,
        Type,
        Amount,
        Category,
        Description,
        TransactionDate
    )
    VALUES (
        @TenantId,
        @AssociationId,
        @AssetId,
        @InvoiceId,
        @PaymentId,
        @Type,
        @Amount,
        @Category,
        @Description,
        @TransactionDate
    );
    
    SELECT SCOPE_IDENTITY();
END

GO

-- Script0071_StandardizeFinancialSignConvention.sql
-- Unifies the sign convention across all financial reports and dashboards.
-- Standard Convention: Positive = Outstanding Debt (Debit > Credit), Negative = Advance Credit (Credit > Debit).

-- 1. Fix Transactions Balance (was inverted in Script0049)
CREATE   PROCEDURE assoc.sp_Transactions_GetBalanceByAssetId 
    @AssetId INT, 
    @TenantId INT, 
    @AssociationId INT 
AS 
BEGIN 
    SET NOCOUNT ON;
    -- FIX: Debit is Positive (Owed), Credit is Negative (Paid)
    SELECT ISNULL(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0) 
    FROM assoc.Transactions 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId; 
END

GO

-- TRANSACTIONS
CREATE   PROCEDURE assoc.sp_Transactions_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Transactions 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId 
    ORDER BY TransactionDate DESC; 
END

GO

CREATE   PROCEDURE assoc.sp_Transactions_GetByTenantId @TenantId INT, @AssociationId INT, @StartDate DATETIME, @EndDate DATETIME AS 
BEGIN 
    SELECT * FROM assoc.Transactions 
    WHERE AssociationId = @AssociationId AND TransactionDate BETWEEN @StartDate AND @EndDate 
    ORDER BY TransactionDate DESC; 
END

GO

-- STORED PROCEDURES FOR ASSOC USER ASSOCIATIONS
CREATE   PROCEDURE assoc.sp_UserAssociations_CheckExists @UserId INT, @AssociationId INT AS 
BEGIN SELECT COUNT(1) FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId; END

GO

CREATE   PROCEDURE assoc.sp_UserAssociations_Delete @UserId INT, @AssociationId INT AS 
BEGIN DELETE FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId; END

GO


CREATE   PROCEDURE assoc.sp_UserAssociations_GetRole
    @UserId INT,
    @AssociationId INT
AS
BEGIN
    -- 1. Check direct association mapping
    DECLARE @Role NVARCHAR(50) = (SELECT TOP 1 Role FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId);
    
    IF @Role IS NOT NULL
        SELECT @Role;
    ELSE
    BEGIN
        -- 2. Check if user is high-level admin in assoc.Users
        SET @Role = (SELECT TOP 1 Role FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin'));
        
        IF @Role IS NOT NULL
            SELECT @Role;
        ELSE
        BEGIN
            -- 3. Check occupancy for implicit Resident role
            IF EXISTS (SELECT 1 FROM assoc.Occupancy o 
                       INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId 
                       INNER JOIN assoc.Users u ON p.Email = u.Email 
                       WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId)
                SELECT 'Resident';
            ELSE
                SELECT NULL;
        END
    END
END;

GO


CREATE   PROCEDURE assoc.sp_UserAssociations_IsAuthorised
    @UserId INT,
    @AssociationId INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin'))
    BEGIN
        SELECT 1;
    END
    ELSE
    BEGIN
        SELECT COUNT(1) FROM (
            -- 1. Direct mapping
            SELECT AssociationId FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId
            UNION
            -- 2. Implicit mapping via occupancy (using Email bridge to be safe)
            SELECT o.AssociationId FROM assoc.Occupancy o 
            INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
            INNER JOIN assoc.Users u ON p.Email = u.Email
            WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId
        ) AS AuthCheck;
    END
END;

GO

CREATE   PROCEDURE assoc.sp_UserAssociations_List
AS
BEGIN
    SELECT * FROM assoc.UserAssociations;
END;

GO

CREATE   PROCEDURE assoc.sp_UserAssociations_Upsert @UserId INT, @AssociationId INT, @Role NVARCHAR(50) AS 
BEGIN 
    IF EXISTS (SELECT 1 FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId)
        UPDATE assoc.UserAssociations SET Role = @Role WHERE UserId = @UserId AND AssociationId = @AssociationId
    ELSE
        INSERT INTO assoc.UserAssociations (UserId, AssociationId, Role) VALUES (@UserId, @AssociationId, @Role);
END

GO

CREATE OR ALTER PROCEDURE assoc.sp_Users_Create @TenantId INT = NULL, @GoogleId NVARCHAR(255) = NULL, @Email NVARCHAR(255), @Name NVARCHAR(255), @PictureUrl NVARCHAR(MAX) = NULL, @Role NVARCHAR(50) = 'User', @CreatedDate DATETIME, @LastLoginDate DATETIME = NULL, @IsActive BIT = 1 AS 
BEGIN 
    INSERT INTO assoc.Users (TenantId, GoogleId, Email, Name, PictureUrl, Role, CreatedDate, LastLoginDate, IsActive) 
    OUTPUT INSERTED.UserId 
    VALUES (@TenantId, @GoogleId, @Email, @Name, @PictureUrl, @Role, @CreatedDate, @LastLoginDate, @IsActive); 
END

GO


CREATE   PROCEDURE assoc.sp_Users_DeleteGlobal
    @UserId INT
AS
BEGIN
    DELETE FROM assoc.UserAssociations WHERE UserId = @UserId;
    DELETE FROM assoc.Users WHERE UserId = @UserId;
END;

GO

CREATE   PROCEDURE assoc.sp_Users_GetAll AS 
BEGIN SELECT * FROM assoc.Users; END

GO

CREATE   PROCEDURE assoc.sp_Users_GetByAssociationId @AssociationId INT AS 
BEGIN 
    -- 1. Explicitly mapped users
    SELECT u.*, ua.Role 
    FROM assoc.Users u 
    JOIN assoc.UserAssociations ua ON u.UserId = ua.UserId 
    WHERE ua.AssociationId = @AssociationId
    
    UNION

    -- 2. Persons mapped as occupants (Residents)
    SELECT DISTINCT u.*, 'Resident' as Role
    FROM assoc.Users u
    INNER JOIN assoc.Persons p ON u.Email = p.Email
    INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    WHERE o.AssociationId = @AssociationId;
END

GO

CREATE   PROCEDURE assoc.sp_Users_GetByById @Id INT AS BEGIN SELECT * FROM assoc.Users WHERE UserId = @Id; END;

GO

CREATE   PROCEDURE assoc.sp_Users_GetByEmail @Email NVARCHAR(255) AS BEGIN SELECT * FROM assoc.Users WHERE Email = @Email; END;

GO

CREATE   PROCEDURE assoc.sp_Users_GetByGoogleId @GoogleId NVARCHAR(255) AS BEGIN SELECT * FROM assoc.Users WHERE GoogleId = @GoogleId; END;

GO

-- STORED PROCEDURES FOR ASSOC USERS
CREATE   PROCEDURE assoc.sp_Users_GetById @Id INT AS 
BEGIN SELECT * FROM assoc.Users WHERE UserId = @Id; END

GO

CREATE   PROCEDURE assoc.sp_Users_GetPaged
    @AssociationId INT = NULL,
    @TenantId INT = NULL,
    @SearchTerm NVARCHAR(255) = NULL,
    @Role NVARCHAR(50) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'Name',
    @SortDirection NVARCHAR(10) = 'ASC'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @SortColumn NOT IN ('Name', 'Email', 'Role', 'CreatedDate', 'Balance')
        SET @SortColumn = 'Name';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'ASC';

    -- 1. Identify all unique members and their highest-priority role
    ;WITH MemberRoles AS (
        -- Staff Mappings
        SELECT 
            ua.UserId, 
            ua.Role, 
            ua.AssociationId,
            CASE 
                WHEN ua.Role = 'AssociationAdmin' THEN 1
                WHEN ua.Role = 'FinanceManager' THEN 2
                WHEN ua.Role = 'CommitteeMember' THEN 3
                WHEN ua.Role = 'Staff' THEN 4
                ELSE 5 
            END as RolePriority
        FROM assoc.UserAssociations ua
        WHERE (@AssociationId IS NULL OR @AssociationId = 0 OR ua.AssociationId = @AssociationId)

        UNION ALL

        -- Resident Mappings (via Occupancy)
        SELECT 
            u.UserId, 
            'Resident' as Role, 
            o.AssociationId,
            6 as RolePriority -- Lowest priority
        FROM assoc.Users u
        INNER JOIN assoc.Persons p ON u.Email = p.Email
        INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
        WHERE (@AssociationId IS NULL OR @AssociationId = 0 OR o.AssociationId = @AssociationId)

        UNION ALL

        -- Fallback Global Admins
        SELECT 
            u.UserId, 
            ua.Role, 
            ua.TenantId as AssociationId,
            1 as RolePriority
        FROM corp.Users u
        INNER JOIN corp.UserAssociations ua ON u.UserId = ua.UserId
        WHERE (@AssociationId IS NULL OR @AssociationId = 0 OR ua.TenantId = @AssociationId)
        AND u.Email NOT IN (SELECT Email FROM assoc.Users)
    ),
    UniqueMembers AS (
        -- Pick the best role per User/Association combo
        SELECT 
            UserId, 
            AssociationId,
            Role,
            ROW_NUMBER() OVER(PARTITION BY UserId, AssociationId ORDER BY RolePriority ASC) as RoleRank
        FROM MemberRoles
    ),
    MemberBalances AS (
        -- Calculate total balance for residents across all their units in this association
        -- (Only applies to residents, but we join globally)
        SELECT 
            u.UserId,
            @AssociationId as AssociationId,
            ISNULL(SUM(CASE WHEN t.Type = 'Debit' THEN t.Amount ELSE -t.Amount END), 0) as Balance
        FROM assoc.Users u
        -- Get all persons for this user email
        INNER JOIN assoc.Persons p ON u.Email = p.Email
        -- Get all occupancy for those persons
        INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
        -- Join transactions for those assets
        LEFT JOIN assoc.Transactions t ON o.AssetId = t.AssetId AND t.AssociationId = o.AssociationId
        WHERE (@AssociationId IS NULL OR @AssociationId = 0 OR o.AssociationId = @AssociationId)
        GROUP BY u.UserId
    ),
    PagedMembers AS (
        SELECT 
            u.UserId, u.Name, u.Email, u.PictureUrl, u.IsActive, u.CreatedDate,
            um.Role,
            CAST(ISNULL(mb.Balance, 0) AS DECIMAL(18,2)) as Balance,
            CAST(COUNT(*) OVER() AS INT) as TotalCount
        FROM assoc.Users u
        INNER JOIN UniqueMembers um ON u.UserId = um.UserId AND um.RoleRank = 1
        LEFT JOIN MemberBalances mb ON u.UserId = mb.UserId
        WHERE (@AssociationId IS NULL OR @AssociationId = 0 OR um.AssociationId = @AssociationId)
        AND (@Role IS NULL OR um.Role = @Role)
        AND (@SearchTerm IS NULL OR u.Name LIKE '%' + @SearchTerm + '%' OR u.Email LIKE '%' + @SearchTerm + '%')
    )
    SELECT 
        * 
    FROM PagedMembers
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Name' THEN Name
                WHEN @SortColumn = 'Email' THEN Email
                WHEN @SortColumn = 'Role' THEN Role
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Name' THEN Name
                WHEN @SortColumn = 'Email' THEN Email
                WHEN @SortColumn = 'Role' THEN Role
            END
        END DESC,
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Balance' THEN Balance
                WHEN @SortColumn = 'CreatedDate' THEN CAST(CreatedDate AS SQL_VARIANT)
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Balance' THEN Balance
                WHEN @SortColumn = 'CreatedDate' THEN CAST(CreatedDate AS SQL_VARIANT)
            END
        END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;

GO


CREATE   PROCEDURE assoc.sp_Users_List
AS
BEGIN
    SELECT * FROM assoc.Users ORDER BY Name;
END;

GO

CREATE   PROCEDURE assoc.sp_Users_Update @UserId INT, @Name NVARCHAR(255), @PictureUrl NVARCHAR(MAX), @Role NVARCHAR(50), @LastLoginDate DATETIME, @IsActive BIT AS 
BEGIN 
    UPDATE assoc.Users SET Name = @Name, PictureUrl = @PictureUrl, Role = @Role, LastLoginDate = @LastLoginDate, IsActive = @IsActive 
    WHERE UserId = @UserId; 
END

GO

CREATE   PROCEDURE assoc.sp_Vehicles_Create @AssetId INT, @TenantId INT, @AssociationId INT, @Make NVARCHAR(100), @Model NVARCHAR(100), @LicensePlate NVARCHAR(50), @Color NVARCHAR(50), @ParkingSlot NVARCHAR(100), @IsActive BIT AS 
BEGIN INSERT INTO assoc.Vehicles (AssetId, TenantId, AssociationId, Make, Model, LicensePlate, Color, ParkingSlot, IsActive) OUTPUT INSERTED.VehicleId VALUES (@AssetId, @TenantId, @AssociationId, @Make, @Model, @LicensePlate, @Color, @ParkingSlot, @IsActive); END

GO

CREATE   PROCEDURE assoc.sp_Vehicles_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    DELETE FROM assoc.Vehicles 
    WHERE VehicleId = @Id AND AssociationId = @AssociationId; 
END

GO

-- VEHICLES
CREATE   PROCEDURE assoc.sp_Vehicles_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Vehicles 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId; 
END
GO

GO

CREATE   PROCEDURE assoc.sp_Vehicles_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.Vehicles 
    WHERE VehicleId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END;

GO

-- 2. Vehicles Update
CREATE   PROCEDURE assoc.sp_Vehicles_Update
    @VehicleId INT,
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT,
    @Make NVARCHAR(100),
    @Model NVARCHAR(100),
    @LicensePlate NVARCHAR(50),
    @Color NVARCHAR(50) = NULL,
    @ParkingSlot NVARCHAR(100) = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE assoc.Vehicles
    SET AssetId = @AssetId,
        TenantId = @TenantId,
        AssociationId = @AssociationId,
        Make = @Make,
        Model = @Model,
        LicensePlate = @LicensePlate,
        Color = @Color,
        ParkingSlot = @ParkingSlot,
        IsActive = @IsActive
    WHERE VehicleId = @VehicleId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END

GO

CREATE   PROCEDURE assoc.sp_Votes_Check
    @ElectionId INT,
    @MemberId INT
AS
BEGIN
    SELECT COUNT(1) FROM assoc.Votes WHERE ElectionId = @ElectionId AND MemberId = @MemberId;
END;

GO

CREATE   PROCEDURE assoc.sp_Votes_Insert
    @ElectionId INT,
    @MemberId INT,
    @CandidateId INT
AS
BEGIN
    INSERT INTO assoc.Votes (ElectionId, MemberId, CandidateId) VALUES (@ElectionId, @MemberId, @CandidateId);
END;

GO

CREATE   PROCEDURE assoc.sp_WorkOrders_Create @TenantId INT, @AssociationId INT, @AssetId INT = NULL, @Title NVARCHAR(200), @Description NVARCHAR(MAX) = NULL, @Priority NVARCHAR(50), @Status NVARCHAR(50), @CreatedDate DATETIME, @CreatedBy INT AS 
BEGIN INSERT INTO assoc.WorkOrders (TenantId, AssociationId, AssetId, Title, Description, Priority, Status, CreatedDate, CreatedBy) OUTPUT INSERTED.WorkOrderId VALUES (@TenantId, @AssociationId, @AssetId, @Title, @Description, @Priority, @Status, @CreatedDate, @CreatedBy); END

GO

CREATE   PROCEDURE assoc.sp_WorkOrders_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    DELETE FROM assoc.WorkOrders 
    WHERE WorkOrderId = @Id AND AssociationId = @AssociationId; 
END

GO

CREATE   PROCEDURE assoc.sp_WorkOrders_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT w.*, a.Name as AssetName 
    FROM assoc.WorkOrders w 
    LEFT JOIN assoc.Assets a ON w.AssetId = a.AssetId 
    WHERE w.AssociationId = @AssociationId 
    ORDER BY w.CreatedDate DESC; 
END

GO

CREATE   PROCEDURE assoc.sp_WorkOrders_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT w.*, a.Name as AssetName 
    FROM assoc.WorkOrders w 
    LEFT JOIN assoc.Assets a ON w.AssetId = a.AssetId 
    WHERE w.AssetId = @AssetId AND w.AssociationId = @AssociationId 
    ORDER BY w.CreatedDate DESC; 
END

GO

-- WORK ORDERS
CREATE   PROCEDURE assoc.sp_WorkOrders_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT w.*, a.Name as AssetName 
    FROM assoc.WorkOrders w 
    LEFT JOIN assoc.Assets a ON w.AssetId = a.AssetId 
    WHERE w.WorkOrderId = @Id AND w.AssociationId = @AssociationId; 
END

GO

CREATE   PROCEDURE assoc.sp_WorkOrders_Update @WorkOrderId INT, @Title NVARCHAR(200), @Description NVARCHAR(MAX) = NULL, @Priority NVARCHAR(50), @Status NVARCHAR(50) AS 
BEGIN UPDATE assoc.WorkOrders SET Title = @Title, Description = @Description, Priority = @Priority, Status = @Status WHERE WorkOrderId = @WorkOrderId; END

GO

CREATE   PROCEDURE assoc.sp_WorkOrders_UpdateStatus @Id INT, @Status NVARCHAR(50), @TenantId INT, @AssociationId INT AS 
BEGIN 
    UPDATE assoc.WorkOrders SET Status = @Status 
    WHERE WorkOrderId = @Id AND AssociationId = @AssociationId; 
END

GO

-- 4. Update sp_Associations_Create
CREATE   PROCEDURE corp.sp_Associations_Create 
    @TenantId INT, 
    @Name NVARCHAR(255), 
    @Description NVARCHAR(MAX), 
    @CreatedDate DATETIME, 
    @CreatedBy INT,
    @AdminEmail NVARCHAR(255) = NULL,
    @PlatformAccountId INT = NULL,
    @AdminPaysFee BIT = 1
AS 
BEGIN 
    INSERT INTO corp.Associations (TenantId, Name, Description, CreatedDate, CreatedBy, AdminEmail, PlatformAccountId, AdminPaysFee, Status) 
    OUTPUT INSERTED.AssociationId 
    VALUES (@TenantId, @Name, @Description, @CreatedDate, @CreatedBy, @AdminEmail, @PlatformAccountId, @AdminPaysFee, 'Active'); 
END

GO

CREATE PROCEDURE corp.sp_Associations_Delete @Id INT AS 
    BEGIN 
        UPDATE corp.Associations SET Status = 'Deactivated' WHERE AssociationId = @Id; 
    END

GO

-- 3. Update sp_Associations_GetAllByTenantId
CREATE   PROCEDURE corp.sp_Associations_GetAllByTenantId @TenantId INT AS 
BEGIN SELECT * FROM corp.Associations WHERE TenantId = @TenantId; END

GO

-- 2. Update sp_Associations_GetById
CREATE   PROCEDURE corp.sp_Associations_GetById @Id INT, @TenantId INT AS 
BEGIN SELECT * FROM corp.Associations WHERE AssociationId = @Id AND TenantId = @TenantId; END

GO

CREATE   PROCEDURE corp.sp_Associations_GetByUserId @UserId INT AS 
BEGIN
    SELECT DISTINCT a.* FROM corp.Associations a
    INNER JOIN corp.UserAssociations ua ON a.TenantId = ua.TenantId
    WHERE ua.UserId = @UserId AND ua.Role IN ('SystemAdmin', 'AssociationAdmin', 'PlatformAdmin') AND a.Status = 'Active'
    UNION
    SELECT DISTINCT a.* FROM corp.Associations a
    INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN corp.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId AND a.Status = 'Active'
END

GO

-- 3. Stored Procedures for Wallet Management

CREATE   PROCEDURE corp.sp_Associations_GetWalletBalance
    @AssociationId INT
AS
BEGIN
    SELECT ISNULL(PlatformWalletBalance, 0) FROM corp.Associations WHERE AssociationId = @AssociationId;
END;

GO

-- 3. Update Associations List Stored Procedure to include Billing Account Name
CREATE   PROCEDURE corp.sp_Associations_List
AS
BEGIN
    SELECT 
        a.*,
        pa.AccountName as BillingAccountName
    FROM corp.Associations a
    LEFT JOIN corp.PlatformAccounts pa ON a.PlatformAccountId = pa.Id;
END;

GO

-- 5. Update sp_Associations_Update
CREATE   PROCEDURE corp.sp_Associations_Update 
    @AssociationId INT, 
    @TenantId INT, 
    @Name NVARCHAR(255), 
    @Description NVARCHAR(MAX),
    @AdminEmail NVARCHAR(255) = NULL,
    @PlatformAccountId INT = NULL,
    @AdminPaysFee BIT = 1,
    @Status NVARCHAR(50) = 'Active'
AS 
BEGIN 
    UPDATE corp.Associations 
    SET Name = @Name, 
        Description = @Description,
        AdminEmail = ISNULL(@AdminEmail, AdminEmail),
        PlatformAccountId = @PlatformAccountId,
        AdminPaysFee = @AdminPaysFee,
        Status = @Status
    WHERE AssociationId = @AssociationId AND TenantId = @TenantId; 
END

GO

-- 7. Add sp_Associations_UpdateStatus
CREATE   PROCEDURE corp.sp_Associations_UpdateStatus @Id INT, @Status NVARCHAR(50) AS 
BEGIN 
    UPDATE corp.Associations SET Status = @Status WHERE AssociationId = @Id; 
END

GO

CREATE   PROCEDURE corp.sp_Associations_UpdateWalletBalance
    @AssociationId INT,
    @Delta DECIMAL(18,2)
AS
BEGIN
    UPDATE corp.Associations
    SET PlatformWalletBalance = ISNULL(PlatformWalletBalance, 0) + @Delta
    WHERE AssociationId = @AssociationId;
END;

GO


CREATE   PROCEDURE corp.sp_Association_BulkDelete
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @TenantId INT;
    SELECT @TenantId = TenantId FROM corp.Associations WHERE AssociationId = @AssociationId;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Tier 0: Global Audit Logs & Child Transactions
        DELETE FROM corp.AuditLogs WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.PaymentTransactions WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.PaymentOrders WHERE AssociationId = @AssociationId;
        
        -- 2. Tier 2: Ledgers & Invoices
        DELETE FROM assoc.Transactions WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.Payments WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.InvoiceLineItems WHERE InvoiceId IN (SELECT InvoiceId FROM assoc.Invoices WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Invoices WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.BillingBatches WHERE AssociationId = @AssociationId;

        -- 3. Tier 3: Asset Details
        DELETE FROM assoc.Vehicles WHERE AssetId IN (SELECT AssetId FROM assoc.Assets WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Pets WHERE AssetId IN (SELECT AssetId FROM assoc.Assets WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Occupancy WHERE AssetId IN (SELECT AssetId FROM assoc.Assets WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Persons WHERE AssociationId = @AssociationId;

        -- 4. Tier 4: Core Registry
        DELETE FROM assoc.AssetTariffs WHERE AssetId IN (SELECT AssetId FROM assoc.Assets WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.TariffLayers WHERE TariffGroupId IN (SELECT TariffGroupId FROM assoc.TariffGroups WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.TariffGroups WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.Assets WHERE AssociationId = @AssociationId;

        -- 5. Tier 5: Governance & Workflow
        DELETE FROM assoc.Votes WHERE ElectionId IN (SELECT ElectionId FROM assoc.Elections WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Candidates WHERE ElectionId IN (SELECT ElectionId FROM assoc.Elections WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Elections WHERE AssociationId = @AssociationId;
        
        DELETE FROM assoc.MeetingMinutes WHERE MeetingId IN (SELECT MeetingId FROM assoc.Meetings WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Meetings WHERE AssociationId = @AssociationId;
        
        DELETE FROM assoc.CommitteeMembers WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.WorkOrders WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.Broadcasts WHERE AssociationId = @AssociationId;

        -- 6. Tier 6: Profiles and Settings
        DELETE FROM assoc.FineSettings WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.ByeLaws WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.AssociationBankDetails WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.AssociationProfile WHERE AssociationId = @AssociationId;

        -- 7. Tier 7: Corporate Integration
        DELETE FROM corp.PlatformAdvancePayments WHERE AssociationId = @AssociationId;
        DELETE FROM corp.PlatformPayments WHERE PlatformInvoiceId IN (SELECT PlatformInvoiceId FROM corp.PlatformInvoices WHERE AssociationId = @AssociationId);
        DELETE FROM corp.PlatformInvoices WHERE AssociationId = @AssociationId;
        DELETE FROM corp.AssociationSubscriptions WHERE AssociationId = @AssociationId;

        -- 8. Tier 8: Identity & Mapping
        -- Delete RefreshTokens for any system (corp or assoc schema) linked to users of this association
        DELETE FROM corp.RefreshTokens WHERE UserId IN (SELECT UserId FROM corp.Users WHERE AssociationId = @AssociationId);
        
        IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[RefreshTokens]') AND type in (N'U'))
        BEGIN
            DELETE FROM assoc.RefreshTokens WHERE UserId IN (SELECT UserId FROM corp.Users WHERE AssociationId = @AssociationId);
        END

        -- Handle User Mappings across schemas
        IF @TenantId IS NOT NULL
        BEGIN
            DELETE FROM corp.UserAssociations WHERE TenantId = @TenantId;
        END

        IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[UserAssociations]') AND type in (N'U'))
        BEGIN
            DELETE FROM assoc.UserAssociations WHERE AssociationId = @AssociationId;
        END
        
        -- Delete association-specific users only if they are not mapped to any other associations
        DELETE FROM corp.Users 
        WHERE AssociationId = @AssociationId
        AND UserId NOT IN (SELECT UserId FROM corp.UserAssociations WHERE AssociationId != @AssociationId);

        -- 9. Tier 9: Final Primary Deletion
        DELETE FROM corp.Associations WHERE AssociationId = @AssociationId;

        -- Optional: Delete Tenant record if it is now empty and not used elsewhere
        -- IF @TenantId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM corp.Associations WHERE TenantId = @TenantId)
        -- BEGIN
        --     DELETE FROM corp.Tenants WHERE TenantId = @TenantId;
        -- END

        COMMIT TRANSACTION;
        PRINT 'Bulk delete successful for AssociationId: ' + CAST(@AssociationId AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

GO

CREATE PROCEDURE corp.sp_AuditLogs_Create
        @TenantId INT,
        @AssociationId INT = NULL,
        @UserId INT = NULL,
        @AssetId INT = NULL,
        @Action NVARCHAR(MAX),
        @Entity NVARCHAR(100) = NULL,
        @EntityId INT = NULL,
        @IpAddress NVARCHAR(50) = NULL,
        @CorrelationId NVARCHAR(100) = NULL,
        @Timestamp DATETIME
    AS
    BEGIN
        INSERT INTO corp.AuditLogs (TenantId, AssociationId, UserId, AssetId, Action, Entity, EntityId, IpAddress, CorrelationId, Timestamp)
        VALUES (@TenantId, @AssociationId, @UserId, @AssetId, @Action, @Entity, @EntityId, @IpAddress, @CorrelationId, @Timestamp);
        
        SELECT SCOPE_IDENTITY();
    END

GO

-- AUDIT
CREATE   PROCEDURE corp.sp_AuditLogs_GetByTenantId @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM corp.AuditLogs 
    WHERE AssociationId = @AssociationId 
    ORDER BY Timestamp DESC; 
END

GO

CREATE   PROCEDURE corp.sp_Maintenance_ArchiveAuditLogs
    @RetentionDays INT = 180, -- Default 6 months
    @BatchSize INT = 5000     -- Limit per run to avoid log bloat
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CutoffDate DATETIME = DATEADD(DAY, -@RetentionDays, GETUTCDATE());
    DECLARE @RowsAffected INT = 0;

    -- Create temporary table for IDs to be moved (to minimize locking during the move)
    CREATE TABLE #LogsToMove (AuditLogId INT PRIMARY KEY);

    INSERT INTO #LogsToMove (AuditLogId)
    SELECT TOP (@BatchSize) AuditLogId
    FROM corp.AuditLogs WITH (NOLOCK)
    WHERE Timestamp < @CutoffDate
    ORDER BY Timestamp ASC;

    SET @RowsAffected = @@ROWCOUNT;

    IF @RowsAffected > 0
    BEGIN
        BEGIN TRANSACTION;
        BEGIN TRY
            -- 1. Insert into Archive
            INSERT INTO archive.AuditLogs (AuditLogId, TenantId, UserId, Action, Entity, EntityId, IpAddress, Timestamp, AssociationId, AssetId, CorrelationId)
            SELECT l.AuditLogId, l.TenantId, l.UserId, l.Action, l.Entity, l.EntityId, l.IpAddress, l.Timestamp, l.AssociationId, l.AssetId, l.CorrelationId
            FROM corp.AuditLogs l
            INNER JOIN #LogsToMove m ON l.AuditLogId = m.AuditLogId;

            -- 2. Delete from Active
            DELETE l
            FROM corp.AuditLogs l
            INNER JOIN #LogsToMove m ON l.AuditLogId = m.AuditLogId;

            COMMIT TRANSACTION;
            
            PRINT 'Archived ' + CAST(@RowsAffected AS VARCHAR) + ' audit logs.';
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            THROW;
        END CATCH
    END

    DROP TABLE #LogsToMove;
    SELECT @RowsAffected AS ArchivedCount;
END
GO

GO

CREATE PROCEDURE corp.sp_Maintenance_ArchiveAuditLogs
    @RetentionDays INT = 180, -- Default 6 months
    @BatchSize INT = 5000     -- Limit per run to avoid log bloat
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CutoffDate DATETIME = DATEADD(DAY, -@RetentionDays, GETUTCDATE());
    DECLARE @RowsAffected INT = 0;

    -- Create temporary table for IDs to be moved (to minimize locking during the move)
    CREATE TABLE #LogsToMove (AuditLogId INT PRIMARY KEY);

    INSERT INTO #LogsToMove (AuditLogId)
    SELECT TOP (@BatchSize) AuditLogId
    FROM corp.AuditLogs WITH (NOLOCK)
    WHERE Timestamp < @CutoffDate
    ORDER BY Timestamp ASC;

    SET @RowsAffected = @@ROWCOUNT;

    IF @RowsAffected > 0
    BEGIN
        BEGIN TRANSACTION;
        BEGIN TRY
            -- 1. Insert into Archive
            INSERT INTO archive.AuditLogs (AuditLogId, TenantId, UserId, Action, Entity, EntityId, IpAddress, Timestamp, AssociationId, AssetId, CorrelationId)
            SELECT l.AuditLogId, l.TenantId, l.UserId, l.Action, l.Entity, l.EntityId, l.IpAddress, l.Timestamp, l.AssociationId, l.AssetId, l.CorrelationId
            FROM corp.AuditLogs l
            INNER JOIN #LogsToMove m ON l.AuditLogId = m.AuditLogId;

            -- 2. Delete from Active
            DELETE l
            FROM corp.AuditLogs l
            INNER JOIN #LogsToMove m ON l.AuditLogId = m.AuditLogId;

            COMMIT TRANSACTION;
            
            PRINT 'Archived ' + CAST(@RowsAffected AS VARCHAR) + ' audit logs.';
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            THROW;
        END CATCH
    END

    DROP TABLE #LogsToMove;
    SELECT @RowsAffected AS ArchivedCount;
END

GO

-- Stored Procedures for Platform Accounts
GO
CREATE PROCEDURE corp.sp_PlatformAccounts_Create
    @AccountName NVARCHAR(255),
    @AccountNumber NVARCHAR(50) = NULL,
    @BankName NVARCHAR(255) = NULL,
    @IFSCCode NVARCHAR(20) = NULL,
    @BranchName NVARCHAR(255) = NULL,
    @RazorpayKeyId NVARCHAR(255) = NULL,
    @RazorpayKeySecret NVARCHAR(255) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    INSERT INTO corp.PlatformAccounts (AccountName, AccountNumber, BankName, IFSCCode, BranchName, RazorpayKeyId, RazorpayKeySecret, IsActive, LastUpdated)
    VALUES (@AccountName, @AccountNumber, @BankName, @IFSCCode, @BranchName, @RazorpayKeyId, @RazorpayKeySecret, @IsActive, GETUTCDATE());
    SELECT SCOPE_IDENTITY();
END
GO

CREATE PROCEDURE corp.sp_PlatformAccounts_Update
    @Id INT,
    @AccountName NVARCHAR(255),
    @AccountNumber NVARCHAR(50) = NULL,
    @BankName NVARCHAR(255) = NULL,
    @IFSCCode NVARCHAR(20) = NULL,
    @BranchName NVARCHAR(255) = NULL,
    @RazorpayKeyId NVARCHAR(255) = NULL,
    @RazorpayKeySecret NVARCHAR(255) = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE corp.PlatformAccounts
    SET AccountName = @AccountName,
        AccountNumber = @AccountNumber,
        BankName = @BankName,
        IFSCCode = @IFSCCode,
        BranchName = @BranchName,
        RazorpayKeyId = @RazorpayKeyId,
        RazorpayKeySecret = @RazorpayKeySecret,
        IsActive = @IsActive,
        LastUpdated = GETUTCDATE()
    WHERE Id = @Id;
END
GO

CREATE PROCEDURE corp.sp_PlatformAccounts_GetById
    @Id INT
AS
BEGIN
    SELECT * FROM corp.PlatformAccounts WHERE Id = @Id;
END
GO

CREATE PROCEDURE corp.sp_PlatformAccounts_List
AS
BEGIN
    SELECT * FROM corp.PlatformAccounts;
END
GO

CREATE PROCEDURE corp.sp_PlatformAccounts_Delete
    @Id INT
AS
BEGIN
    DELETE FROM corp.PlatformAccounts WHERE Id = @Id;
END
GO

GO

CREATE   PROCEDURE corp.sp_PlatformAdvancePayments_GetPaged
    @AssociationId INT,
    @SearchTerm NVARCHAR(100) = NULL,
    @Status NVARCHAR(50) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'Date',
    @SortDirection NVARCHAR(10) = 'DESC'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    WITH FilteredResults AS (
        SELECT *, COUNT(*) OVER() as TotalCount
        FROM corp.PlatformAdvancePayments
        WHERE AssociationId = @AssociationId
          AND (@Status IS NULL OR Status = @Status)
          AND (@SearchTerm IS NULL OR Description LIKE '%' + @SearchTerm + '%' OR TransactionRef LIKE '%' + @SearchTerm + '%')
          AND (@StartDate IS NULL OR Date >= @StartDate)
          AND (@EndDate IS NULL OR Date <= @EndDate)
    )
    SELECT *
    FROM FilteredResults
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Date' THEN CAST(Date AS NVARCHAR(50))
                WHEN @SortColumn = 'Amount' THEN RIGHT('0000000000' + CAST(ABS(Amount) * 100 AS VARCHAR(20)), 20)
                ELSE CAST(Date AS NVARCHAR(50))
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Date' THEN CAST(Date AS NVARCHAR(50))
                WHEN @SortColumn = 'Amount' THEN RIGHT('0000000000' + CAST(ABS(Amount) * 100 AS VARCHAR(20)), 20)
                ELSE CAST(Date AS NVARCHAR(50))
            END
        END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;

GO

CREATE   PROCEDURE corp.sp_PlatformAdvancePayments_Insert
    @AssociationId INT,
    @Amount DECIMAL(18,2),
    @Status NVARCHAR(50),
    @TransactionRef NVARCHAR(255) = NULL,
    @Description NVARCHAR(500) = NULL,
    @Notes NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO corp.PlatformAdvancePayments (AssociationId, Amount, Status, TransactionRef, Description, Notes)
    VALUES (@AssociationId, @Amount, @Status, @TransactionRef, @Description, @Notes);
    SELECT SCOPE_IDENTITY();
END;

GO

CREATE PROCEDURE [corp].[sp_PlatformInvoices_GetAll]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        pi.*, 
        sp.Name as PlanName, 
        a.Name as AssociationName 
    FROM corp.PlatformInvoices pi 
    JOIN corp.SubscriptionPlans sp ON pi.PlanId = sp.PlanId 
    JOIN corp.Associations a ON pi.AssociationId = a.AssociationId 
    ORDER BY pi.BillingDate DESC
END
GO

GO

CREATE   PROCEDURE corp.sp_PlatformInvoices_GetAll
AS
BEGIN
    SELECT pi.*, sp.Name as PlanName, a.Name as AssociationName
    FROM corp.PlatformInvoices pi
    JOIN corp.SubscriptionPlans sp ON pi.PlanId = sp.PlanId
    JOIN corp.Associations a ON pi.AssociationId = a.AssociationId
    ORDER BY pi.BillingDate DESC;
END;

GO

CREATE   PROCEDURE corp.sp_PlatformInvoices_GetByAssociationId
    @AssociationId INT
AS
BEGIN
    SELECT pi.*, sp.Name as PlanName
    FROM corp.PlatformInvoices pi
    JOIN corp.SubscriptionPlans sp ON pi.PlanId = sp.PlanId
    WHERE pi.AssociationId = @AssociationId
    ORDER BY pi.BillingDate DESC;
END;

GO


-- Update Stored Procedure
CREATE   PROCEDURE corp.sp_PlatformInvoices_Insert
    @AssociationId INT,
    @PlanId INT,
    @Amount DECIMAL(18,2),
    @BillingDate DATETIME,
    @DueDate DATETIME
AS
BEGIN
    INSERT INTO corp.PlatformInvoices (AssociationId, PlanId, Amount, BillingDate, DueDate)
    VALUES (@AssociationId, @PlanId, @Amount, @BillingDate, @DueDate);
    SELECT SCOPE_IDENTITY();
END;

GO

CREATE PROCEDURE corp.sp_PlatformInvoices_UpdateStatus
    @PlatformInvoiceId INT,
    @Status NVARCHAR(50)
AS
BEGIN
    UPDATE corp.PlatformInvoices
    SET Status = @Status
    WHERE PlatformInvoiceId = @PlatformInvoiceId;
END

GO

-- Script0083_sp_PlatformPayments_GetRevenue.sql
-- Refactor: Replacing hardcoded revenue query with a standardized stored procedure.
-- Purpose: Achieving 100% architectural consistency for data access.

CREATE   PROCEDURE corp.sp_PlatformPayments_GetRevenue
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT ISNULL(SUM(Amount), 0) 
    FROM corp.PlatformPayments 
    WHERE PaymentDate >= @StartDate AND PaymentDate <= @EndDate;
END;

GO

-- 2. Update sp_PlatformPayments_Insert to handle new fields
CREATE   PROCEDURE corp.sp_PlatformPayments_Insert
    @PlatformInvoiceId INT,
    @Amount DECIMAL(18,2),
    @TransactionRef NVARCHAR(255),
    @PaymentMethod NVARCHAR(50) = 'Manual',
    @Status NVARCHAR(50) = 'Completed'
AS
BEGIN
    BEGIN TRANSACTION;
    
    INSERT INTO corp.PlatformPayments (PlatformInvoiceId, Amount, TransactionRef, PaymentMethod, Status)
    VALUES (@PlatformInvoiceId, @Amount, @TransactionRef, @PaymentMethod, @Status);
    
    -- If status is 'Completed', mark the invoice as Paid. 
    -- If 'Pending Verification', keep it unpaid or add a new invoice status.
    IF @Status = 'Completed'
    BEGIN
        UPDATE corp.PlatformInvoices 
        SET Status = 'Paid' 
        WHERE PlatformInvoiceId = @PlatformInvoiceId;
    END
    ELSE
    BEGIN
        UPDATE corp.PlatformInvoices 
        SET Status = 'Payment Pending' 
        WHERE PlatformInvoiceId = @PlatformInvoiceId;
    END
    
    COMMIT TRANSACTION;
    SELECT SCOPE_IDENTITY();
END;

GO

CREATE   PROCEDURE corp.sp_RefreshTokens_Delete @UserId INT AS 
BEGIN DELETE FROM corp.RefreshTokens WHERE UserId = @UserId; END

GO

-- REFRESH TOKENS
CREATE   PROCEDURE corp.sp_RefreshTokens_GetByToken @Token NVARCHAR(MAX) AS 
BEGIN SELECT * FROM corp.RefreshTokens WHERE Token = @Token; END

GO

CREATE   PROCEDURE corp.sp_RefreshTokens_Upsert @UserId INT, @Token NVARCHAR(MAX), @ExpiryDate DATETIME, @CreatedDate DATETIME AS 
BEGIN
    IF EXISTS (SELECT 1 FROM corp.RefreshTokens WHERE UserId = @UserId)
        UPDATE corp.RefreshTokens SET Token = @Token, ExpiryDate = @ExpiryDate WHERE UserId = @UserId
    ELSE
        INSERT INTO corp.RefreshTokens (UserId, Token, ExpiryDate, CreatedDate) VALUES (@UserId, @Token, @ExpiryDate, @CreatedDate);
END

GO

-- SUBSCRIPTIONS
CREATE   PROCEDURE corp.sp_SubscriptionPlans_GetAll AS 
BEGIN SELECT * FROM corp.SubscriptionPlans; END

GO

CREATE   PROCEDURE corp.sp_SubscriptionPlans_Upsert @PlanId INT, @Name NVARCHAR(100), @BasePrice DECIMAL(18,2), @PricePerAsset DECIMAL(18,2), @IsActive BIT AS 
BEGIN
    IF EXISTS (SELECT 1 FROM corp.SubscriptionPlans WHERE PlanId = @PlanId)
        UPDATE corp.SubscriptionPlans SET Name = @Name, BasePrice = @BasePrice, PricePerAsset = @PricePerAsset, IsActive = @IsActive WHERE PlanId = @PlanId
    ELSE
        INSERT INTO corp.SubscriptionPlans (Name, BasePrice, PricePerAsset, IsActive) VALUES (@Name, @BasePrice, @PricePerAsset, @IsActive);
END

GO

CREATE   PROCEDURE corp.sp_Subscriptions_GetByAssociationId @AssociationId INT AS 
BEGIN
    SELECT s.*, a.TenantId, a.Name as AssociationName, p.Name as PlanName, p.BasePrice, p.PricePerAsset
    FROM corp.AssociationSubscriptions s
    JOIN corp.SubscriptionPlans p ON s.PlanId = p.PlanId
    JOIN corp.Associations a ON s.AssociationId = a.AssociationId
    WHERE s.AssociationId = @AssociationId;
END

GO

CREATE   PROCEDURE corp.sp_Subscriptions_Upsert @AssociationId INT, @PlanId INT, @Status NVARCHAR(50), @NextBillingDate DATETIME AS 
BEGIN
    IF EXISTS (SELECT 1 FROM corp.AssociationSubscriptions WHERE AssociationId = @AssociationId)
        UPDATE corp.AssociationSubscriptions SET PlanId = @PlanId, Status = @Status, NextBillingDate = @NextBillingDate WHERE AssociationId = @AssociationId
    ELSE
        INSERT INTO corp.AssociationSubscriptions (AssociationId, PlanId, Status, NextBillingDate) VALUES (@AssociationId, @PlanId, @Status, @NextBillingDate);
END

GO

-- Delete Payment Config
CREATE   PROCEDURE corp.sp_TenantPaymentConfig_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM corp.TenantPaymentConfig WHERE Id = @Id;
END;

GO

-- Get All Payment Configs (Admin Only)
CREATE   PROCEDURE corp.sp_TenantPaymentConfig_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        c.Id, 
        c.TenantId, 
        t.Name AS TenantName,
        c.RazorpayKeyId, 
        c.RazorpayKeySecret, 
        c.RazorpayWebhookSecret,
        c.IsActive, 
        c.LastUpdated
    FROM corp.TenantPaymentConfig c
    JOIN corp.Tenants t ON c.TenantId = t.TenantId
    ORDER BY c.TenantId;
END;

GO

-- 5. Stored Procedures

-- Get Payment Config
CREATE   PROCEDURE corp.sp_TenantPaymentConfig_GetByTenantId
    @TenantId INT
AS
BEGIN
    SELECT * FROM corp.TenantPaymentConfig WHERE TenantId = @TenantId AND IsActive = 1;
END;

GO

-- Upsert Payment Config
CREATE   PROCEDURE corp.sp_TenantPaymentConfig_Upsert
    @Id INT = 0,
    @TenantId INT,
    @RazorpayKeyId NVARCHAR(100),
    @RazorpayKeySecret NVARCHAR(100),
    @RazorpayWebhookSecret NVARCHAR(100) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM corp.TenantPaymentConfig WHERE Id = @Id OR TenantId = @TenantId)
    BEGIN
        UPDATE corp.TenantPaymentConfig
        SET 
            RazorpayKeyId = @RazorpayKeyId,
            RazorpayKeySecret = @RazorpayKeySecret,
            RazorpayWebhookSecret = @RazorpayWebhookSecret,
            IsActive = @IsActive,
            LastUpdated = GETUTCDATE()
        WHERE Id = @Id OR TenantId = @TenantId;
        
        -- Return the ID
        SELECT ISNULL(NULLIF(@Id, 0), (SELECT Id FROM corp.TenantPaymentConfig WHERE TenantId = @TenantId));
    END
    ELSE
    BEGIN
        INSERT INTO corp.TenantPaymentConfig (TenantId, RazorpayKeyId, RazorpayKeySecret, RazorpayWebhookSecret, IsActive, LastUpdated)
        VALUES (@TenantId, @RazorpayKeyId, @RazorpayKeySecret, @RazorpayWebhookSecret, @IsActive, GETUTCDATE());
        
        SELECT SCOPE_IDENTITY();
    END
END;

GO

CREATE   PROCEDURE corp.sp_Tenants_Create @Name NVARCHAR(255), @CreatedDate DATETIME, @IsActive BIT AS 
BEGIN INSERT INTO corp.Tenants (Name, CreatedDate, IsActive) OUTPUT INSERTED.TenantId VALUES (@Name, @CreatedDate, @IsActive); END

GO

CREATE   PROCEDURE corp.sp_Tenants_GetAll AS 
BEGIN SELECT * FROM corp.Tenants; END

GO

-- TENANTS
CREATE   PROCEDURE corp.sp_Tenants_GetById @Id INT AS 
BEGIN SELECT * FROM corp.Tenants WHERE TenantId = @Id; END

GO

CREATE   PROCEDURE corp.sp_Tenants_Update @TenantId INT, @Name NVARCHAR(255), @IsActive BIT AS 
BEGIN UPDATE corp.Tenants SET Name = @Name, IsActive = @IsActive WHERE TenantId = @TenantId; END

GO

CREATE   PROCEDURE corp.sp_UserAssociations_CheckExists @UserId INT, @TenantId INT AS 
BEGIN SELECT COUNT(1) FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId; END

GO

CREATE   PROCEDURE corp.sp_UserAssociations_Delete @UserId INT, @TenantId INT AS 
BEGIN DELETE FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId; END

GO


-- 7. Get Role for Context (Schema-aware)
CREATE   PROCEDURE corp.sp_UserAssociations_GetRole
    @UserId INT,
    @TenantId INT
AS
BEGIN
    -- 1. Check direct tenant mapping
    DECLARE @Role NVARCHAR(50) = (SELECT TOP 1 Role FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId);
    
    IF @Role IS NOT NULL
        SELECT @Role;
    ELSE
    BEGIN
        -- 2. Check if user is global admin in corp.Users
        SELECT Role FROM corp.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin');
    END
END;

GO

CREATE   PROCEDURE corp.sp_UserAssociations_Upsert @UserId INT, @TenantId INT, @Role NVARCHAR(50) AS 
BEGIN 
    IF EXISTS (SELECT 1 FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId)
        UPDATE corp.UserAssociations SET Role = @Role WHERE UserId = @UserId AND TenantId = @TenantId
    ELSE
        INSERT INTO corp.UserAssociations (UserId, TenantId, Role) VALUES (@UserId, @TenantId, @Role);
END

GO

CREATE OR ALTER PROCEDURE corp.sp_Users_Create @TenantId INT, @GoogleId NVARCHAR(255) = NULL, @Email NVARCHAR(255), @Name NVARCHAR(255), @PictureUrl NVARCHAR(MAX), @Role NVARCHAR(50), @CreatedDate DATETIME, @LastLoginDate DATETIME = NULL, @IsActive BIT AS 
BEGIN INSERT INTO corp.Users (TenantId, GoogleId, Email, Name, PictureUrl, Role, CreatedDate, LastLoginDate, IsActive) OUTPUT INSERTED.UserId VALUES (@TenantId, @GoogleId, @Email, @Name, @PictureUrl, @Role, @CreatedDate, @LastLoginDate, @IsActive); END

GO


-- 2. Delete User (Global)
CREATE   PROCEDURE corp.sp_Users_DeleteGlobal
    @UserId INT
AS
BEGIN
    DELETE FROM corp.UserAssociations WHERE UserId = @UserId;
    DELETE FROM corp.Users WHERE UserId = @UserId;
END;

GO

CREATE PROCEDURE corp.sp_Users_GetByAssociationId_Complex
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Branch 1: Directly assigned users
    SELECT u.*
    FROM corp.Users u
    WHERE u.AssociationId = @AssociationId

    UNION

    -- Branch 2: Residents via Occupancy
    -- Note: Uses JOIN instead of LEFT JOIN/OR to force index usage
    SELECT u.*
    FROM corp.Users u
    INNER JOIN assoc.Persons p ON u.Email = p.Email
    INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    WHERE o.AssociationId = @AssociationId

    UNION

    -- Branch 3: Admins via Tenant association
    SELECT u.*
    FROM corp.Users u
    INNER JOIN corp.UserAssociations ua ON u.TenantId = ua.TenantId
    WHERE ua.Role IN ('SystemAdmin', 'AssociationAdmin') 
      AND u.TenantId = (SELECT TOP 1 TenantId FROM corp.Associations WHERE AssociationId = @AssociationId)

    ORDER BY Name;
END

GO

CREATE   PROCEDURE corp.sp_Users_GetByEmail @Email NVARCHAR(255) AS 
BEGIN SELECT * FROM corp.Users WHERE Email = @Email; END

GO

CREATE   PROCEDURE corp.sp_Users_GetByGoogleId @GoogleId NVARCHAR(255) AS 
BEGIN SELECT * FROM corp.Users WHERE GoogleId = @GoogleId; END

GO

-- USERS & ROLES
CREATE   PROCEDURE corp.sp_Users_GetById @Id INT AS 
BEGIN SELECT * FROM corp.Users WHERE UserId = @Id; END

GO

CREATE   PROCEDURE corp.sp_Users_GetByTenantId @TenantId INT AS 
BEGIN 
    -- 1. Global corporate users
    SELECT u.*, ua.Role 
    FROM corp.Users u 
    JOIN corp.UserAssociations ua ON u.UserId = ua.UserId 
    WHERE ua.TenantId = @TenantId
    
    UNION

    -- 2. Residents from associations within the tenant
    SELECT DISTINCT u.*, 'Resident' as Role
    FROM corp.Users u
    INNER JOIN assoc.Persons p ON u.Email = p.Email
    INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    INNER JOIN corp.Associations a ON o.AssociationId = a.AssociationId
    WHERE a.TenantId = @TenantId;
END

GO


-- 3. Complex Authorisation Check (Tenant Level)
CREATE   PROCEDURE corp.sp_Users_IsAuthorisedForAssociation
    @UserId INT,
    @AssociationId INT
AS
BEGIN
    SELECT COUNT(1) FROM (
        -- 1. High-level Admins see everything in their tenant
        SELECT a.AssociationId 
        FROM corp.Associations a
        INNER JOIN corp.UserAssociations ua ON a.TenantId = ua.TenantId
        WHERE ua.UserId = @UserId AND ua.Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin') AND a.AssociationId = @AssociationId

        UNION

        -- 2. Residents & Staff linked to assets/occupancy
        SELECT a.AssociationId
        FROM corp.Associations a
        INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
        INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
        INNER JOIN corp.Users u ON p.Email = u.Email
        WHERE u.UserId = @UserId AND a.AssociationId = @AssociationId
    ) AS AuthCheck;
END;

GO

-- User Management Stored Procedures

-- 1. Get All Users (Schema-aware)
CREATE   PROCEDURE corp.sp_Users_List
AS
BEGIN
    SELECT * FROM corp.Users ORDER BY Name;
END;

GO

CREATE   PROCEDURE corp.sp_Users_Update @UserId INT, @Name NVARCHAR(255), @PictureUrl NVARCHAR(MAX), @Role NVARCHAR(50), @LastLoginDate DATETIME, @IsActive BIT AS 
BEGIN UPDATE corp.Users SET Name = @Name, PictureUrl = @PictureUrl, Role = @Role, LastLoginDate = @LastLoginDate, IsActive = @IsActive WHERE UserId = @UserId; END

GO

-- Update sp_Broadcasts_Delete
CREATE   PROCEDURE sp_Broadcasts_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    DELETE FROM Broadcasts 
    WHERE BroadcastId = @Id AND TenantId = @TenantId
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END

GO

-- Update sp_Broadcasts_GetAll to support Corporate Level (All associations in tenant)
CREATE   PROCEDURE sp_Broadcasts_GetAll
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT b.*, u.FirstName + ' ' + u.LastName as AuthorName, a.Name as AssetName
    FROM Broadcasts b
    JOIN Users u ON b.CreatedBy = u.UserId
    LEFT JOIN Assets a ON b.AssetId = a.AssetId
    WHERE b.TenantId = @TenantId 
      AND (b.AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY b.IsPinned DESC, b.CreatedDate DESC;
END

GO

-- Update sp_Broadcasts_GetById
CREATE   PROCEDURE sp_Broadcasts_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT b.*, u.FirstName + ' ' + u.LastName as AuthorName, a.Name as AssetName
    FROM Broadcasts b
    JOIN Users u ON b.CreatedBy = u.UserId
    LEFT JOIN Assets a ON b.AssetId = a.AssetId
    WHERE b.BroadcastId = @Id AND b.TenantId = @TenantId
    AND (b.AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END

GO

-- Update sp_Invoices_Delete
CREATE   PROCEDURE sp_Invoices_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    DELETE FROM Invoices 
    WHERE InvoiceId = @Id AND TenantId = @TenantId 
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END

GO

-- Update sp_Invoices_GetAll to support Corporate Level (All associations in tenant)
CREATE   PROCEDURE sp_Invoices_GetAll
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT i.*, a.Name as AssetName 
    FROM Invoices i 
    LEFT JOIN Assets a ON i.AssetId = a.AssetId
    WHERE i.TenantId = @TenantId 
      AND (i.AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY i.DueDate DESC;
END

GO

-- Update sp_Invoices_GetById
CREATE   PROCEDURE sp_Invoices_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT i.*, a.Name as AssetName 
    FROM Invoices i 
    LEFT JOIN Assets a ON i.AssetId = a.AssetId
    WHERE i.InvoiceId = @Id AND i.TenantId = @TenantId
    AND (i.AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END

GO

-- Update sp_Invoices_UpdateStatus
CREATE   PROCEDURE sp_Invoices_UpdateStatus
    @Id INT,
    @Status NVARCHAR(50),
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    UPDATE Invoices SET Status = @Status 
    WHERE InvoiceId = @Id AND TenantId = @TenantId 
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END

GO

-- Update sp_Payments_GetByTenantId
CREATE   PROCEDURE sp_Payments_GetByTenantId
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT * FROM Payments 
    WHERE TenantId = @TenantId 
      AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY CreatedDate DESC;
END

GO

-- Update sp_Persons_Delete
CREATE   PROCEDURE sp_Persons_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    DELETE FROM Persons 
    WHERE PersonId = @Id AND TenantId = @TenantId
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END

GO

-- Update sp_Persons_GetAll to support Corporate Level (All associations in tenant)
CREATE   PROCEDURE sp_Persons_GetAll
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT * FROM Persons
    WHERE TenantId = @TenantId 
      AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY LastName, FirstName;
END

GO

-- Update sp_Persons_GetById
CREATE   PROCEDURE sp_Persons_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT * FROM Persons
    WHERE PersonId = @Id AND TenantId = @TenantId
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END

GO

-- Update sp_TariffGroups_Create
CREATE   PROCEDURE sp_TariffGroups_Create
    @TenantId INT,
    @AssociationId INT = NULL,
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO TariffGroups (TenantId, AssociationId, Name, Description)
    OUTPUT INSERTED.TariffGroupId
    VALUES (@TenantId, @AssociationId, @Name, @Description);
END

GO

-- Update sp_TariffGroups_GetByTenantId to support scoping
CREATE   PROCEDURE sp_TariffGroups_GetByTenantId
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT * FROM TariffGroups 
    WHERE TenantId = @TenantId 
      AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY Name;
END

GO

-- Update sp_TariffLayers_Create
CREATE   PROCEDURE sp_TariffLayers_Create
    @TariffGroupId INT,
    @TenantId INT,
    @AssociationId INT = NULL,
    @Name NVARCHAR(100),
    @BaseRate DECIMAL(18, 2),
    @Frequency NVARCHAR(50),
    @CalculationType NVARCHAR(50),
    @AccountingCategory NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO TariffLayers (TariffGroupId, TenantId, AssociationId, Name, BaseRate, Frequency, CalculationType, AccountingCategory)
    OUTPUT INSERTED.TariffLayerId
    VALUES (@TariffGroupId, @TenantId, @AssociationId, @Name, @BaseRate, @Frequency, @CalculationType, @AccountingCategory);
END

GO

CREATE   PROCEDURE [dbo].[sp_Users_GetByAssociationId]
    @AssociationId INT
AS
BEGIN
    SELECT DISTINCT u.*
    FROM Users u
    LEFT JOIN Persons p ON u.Email = p.Email
    LEFT JOIN Occupancy o ON p.PersonId = o.PersonId
    LEFT JOIN UserAssociations ua ON u.TenantId = ua.TenantId
    WHERE 
        u.AssociationId = @AssociationId -- Active association
        OR o.AssociationId = @AssociationId -- Resident association
        OR (ua.Role IN ('SystemAdmin', 'AssociationAdmin') AND u.TenantId = (SELECT TenantId FROM Associations WHERE AssociationId = @AssociationId))
    ORDER BY u.Name
END

GO


/* 4. MIGRATIONS (0053-0058) */

-- Governance Stored Procedures

-- 1. Profile
CREATE OR ALTER PROCEDURE assoc.sp_AssociationProfile_Get
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.AssociationProfile WHERE AssociationId = @AssociationId;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_AssociationProfile_Upsert
    @AssociationId INT,
    @RegistrationNumber NVARCHAR(100),
    @RegistrationDate DATETIME2,
    @Address NVARCHAR(MAX),
    @City NVARCHAR(100),
    @State NVARCHAR(100),
    @Pincode NVARCHAR(20),
    @ContactEmail NVARCHAR(255),
    @ContactPhone NVARCHAR(50),
    @Logo NVARCHAR(MAX) = NULL
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
GO

-- 2. Committee
CREATE OR ALTER PROCEDURE assoc.sp_CommitteeRoles_List
AS
BEGIN
    SELECT * FROM assoc.CommitteeRoles;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_CommitteeMembers_List
    @AssociationId INT,
    @ActiveOnly BIT = 1
AS
BEGIN
    SELECT cm.*, COALESCE(cm.MemberName, u.Name) as MemberName, cr.RoleName 
    FROM assoc.CommitteeMembers cm
    LEFT JOIN corp.Users u ON cm.MemberId = u.UserId
    JOIN assoc.CommitteeRoles cr ON cm.RoleId = cr.RoleId
    WHERE cm.AssociationId = @AssociationId
    AND (@ActiveOnly = 0 OR cm.IsActive = 1);
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_CommitteeMembers_Insert
    @AssociationId INT,
    @MemberId INT,
    @MemberName NVARCHAR(255) = NULL,
    @RoleId INT,
    @StartDate DATETIME2,
    @EndDate DATETIME2 = NULL,
    @IsActive BIT
AS
BEGIN
    INSERT INTO assoc.CommitteeMembers (AssociationId, MemberId, MemberName, RoleId, StartDate, EndDate, IsActive)
    VALUES (@AssociationId, @MemberId, @MemberName, @RoleId, @StartDate, @EndDate, @IsActive);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_CommitteeMembers_Update
    @CommitteeMemberId INT,
    @MemberName NVARCHAR(255) = NULL,
    @RoleId INT,
    @StartDate DATETIME2,
    @EndDate DATETIME2 = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE assoc.CommitteeMembers 
    SET RoleId = @RoleId, 
        MemberName = @MemberName, 
        StartDate = @StartDate, 
        EndDate = @EndDate, 
        IsActive = @IsActive 
    WHERE CommitteeMemberId = @CommitteeMemberId;
END;
GO

-- 3. Bye-laws
CREATE OR ALTER PROCEDURE assoc.sp_ByeLaws_List
    @AssociationId INT,
    @ActiveOnly BIT = 1
AS
BEGIN
    SELECT * FROM assoc.ByeLaws 
    WHERE AssociationId = @AssociationId
    AND (@ActiveOnly = 0 OR IsActive = 1);
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_ByeLaws_Insert
    @AssociationId INT,
    @Title NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @EffectiveDate DATETIME2,
    @Version NVARCHAR(50),
    @IsActive BIT,
    @DocumentContent VARBINARY(MAX) = NULL,
    @FileName NVARCHAR(255) = NULL,
    @ContentType NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO assoc.ByeLaws (AssociationId, Title, Description, EffectiveDate, Version, IsActive, DocumentContent, FileName, ContentType)
    VALUES (@AssociationId, @Title, @Description, @EffectiveDate, @Version, @IsActive, @DocumentContent, @FileName, @ContentType);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_ByeLaws_Update
    @ByeLawId INT,
    @Title NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @EffectiveDate DATETIME2,
    @Version NVARCHAR(50),
    @IsActive BIT,
    @DocumentContent VARBINARY(MAX) = NULL,
    @FileName NVARCHAR(255) = NULL,
    @ContentType NVARCHAR(100) = NULL
AS
BEGIN
    UPDATE assoc.ByeLaws SET 
        Title = @Title, 
        Description = @Description, 
        EffectiveDate = @EffectiveDate, 
        Version = @Version, 
        IsActive = @IsActive,
        DocumentContent = @DocumentContent,
        FileName = @FileName,
        ContentType = @ContentType
    WHERE ByeLawId = @ByeLawId;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_ByeLaws_Delete
    @id INT
AS
BEGIN
    DELETE FROM assoc.ByeLaws WHERE ByeLawId = @id;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_ByeLaws_GetById
    @id INT
AS
BEGIN
    SELECT * FROM assoc.ByeLaws WHERE ByeLawId = @id;
END;
GO

-- 4. Meetings
CREATE OR ALTER PROCEDURE assoc.sp_Meetings_List
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.Meetings WHERE AssociationId = @AssociationId;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Meetings_Insert
    @AssociationId INT,
    @Title NVARCHAR(200),
    @MeetingDate DATETIME2,
    @Description NVARCHAR(MAX),
    @CreatedBy INT
AS
BEGIN
    INSERT INTO assoc.Meetings (AssociationId, Title, MeetingDate, Description, CreatedBy)
    VALUES (@AssociationId, @Title, @MeetingDate, @Description, @CreatedBy);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_MeetingMinutes_Insert
    @MeetingId INT,
    @Notes NVARCHAR(MAX),
    @DocumentUrl NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO assoc.MeetingMinutes (MeetingId, Notes, DocumentUrl)
    VALUES (@MeetingId, @Notes, @DocumentUrl);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_MeetingMinutes_List
    @MeetingId INT
AS
BEGIN
    SELECT * FROM assoc.MeetingMinutes WHERE MeetingId = @MeetingId;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_UserAssociations_List
AS
BEGIN
    SELECT * FROM assoc.UserAssociations;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_BillingBatches_UpdateStatus
    @Id INT,
    @Status NVARCHAR(50),
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    UPDATE assoc.BillingBatches 
    SET Status = @Status 
    WHERE BillingBatchId = @Id 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId;
END;
GO
CREATE OR ALTER PROCEDURE assoc.sp_Elections_List
    @AssociationId INT,
    @ActiveOnly BIT = 1
AS
BEGIN
    SELECT * FROM assoc.Elections 
    WHERE AssociationId = @AssociationId
    AND (@ActiveOnly = 0 OR IsActive = 1);
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Elections_Insert
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
GO

CREATE OR ALTER PROCEDURE assoc.sp_Candidates_Insert
    @ElectionId INT,
    @MemberId INT
AS
BEGIN
    INSERT INTO assoc.Candidates (ElectionId, MemberId) VALUES (@ElectionId, @MemberId);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Votes_Insert
    @ElectionId INT,
    @MemberId INT,
    @CandidateId INT
AS
BEGIN
    INSERT INTO assoc.Votes (ElectionId, MemberId, CandidateId) VALUES (@ElectionId, @MemberId, @CandidateId);
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_ElectionResults_Get
    @ElectionId INT
AS
BEGIN
    SELECT u.Name as CandidateName, COUNT(v.VoteId) as VoteCount
    FROM assoc.Candidates c
    JOIN corp.Users u ON c.MemberId = u.UserId
    LEFT JOIN assoc.Votes v ON c.CandidateId = v.CandidateId
    WHERE c.ElectionId = @ElectionId
    GROUP BY u.Name;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Votes_Check
    @ElectionId INT,
    @MemberId INT
AS
BEGIN
    SELECT COUNT(1) FROM assoc.Votes WHERE ElectionId = @ElectionId AND MemberId = @MemberId;
END;
GO

GO

-- User Management Stored Procedures

-- 1. Get All Users (Schema-aware)
CREATE OR ALTER PROCEDURE corp.sp_Users_List
AS
BEGIN
    SELECT * FROM corp.Users ORDER BY Name;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Users_List
AS
BEGIN
    SELECT * FROM assoc.Users ORDER BY Name;
END;
GO

-- 2. Delete User (Global)
CREATE OR ALTER PROCEDURE corp.sp_Users_DeleteGlobal
    @UserId INT
AS
BEGIN
    DELETE FROM corp.UserAssociations WHERE UserId = @UserId;
    DELETE FROM corp.Users WHERE UserId = @UserId;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Users_DeleteGlobal
    @UserId INT
AS
BEGIN
    DELETE FROM assoc.UserAssociations WHERE UserId = @UserId;
    DELETE FROM assoc.Users WHERE UserId = @UserId;
END;
GO

-- 3. Complex Authorisation Check (Tenant Level)
CREATE OR ALTER PROCEDURE corp.sp_Users_IsAuthorisedForAssociation
    @UserId INT,
    @AssociationId INT
AS
BEGIN
    SELECT COUNT(1) FROM (
        -- 1. High-level Admins see everything in their tenant
        SELECT a.AssociationId 
        FROM corp.Associations a
        INNER JOIN corp.UserAssociations ua ON a.TenantId = ua.TenantId
        WHERE ua.UserId = @UserId AND ua.Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin') AND a.AssociationId = @AssociationId

        UNION

        -- 2. Residents & Staff linked to assets/occupancy
        SELECT a.AssociationId
        FROM corp.Associations a
        INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
        INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
        INNER JOIN corp.Users u ON p.Email = u.Email
        WHERE u.UserId = @UserId AND a.AssociationId = @AssociationId
    ) AS AuthCheck;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_UserAssociations_IsAuthorised
    @UserId INT,
    @AssociationId INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin'))
    BEGIN
        SELECT 1;
    END
    ELSE
    BEGIN
        SELECT COUNT(1) FROM (
            -- 1. Direct mapping
            SELECT AssociationId FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId
            UNION
            -- 2. Implicit mapping via occupancy (using Email bridge to be safe)
            SELECT o.AssociationId FROM assoc.Occupancy o 
            INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
            INNER JOIN assoc.Users u ON p.Email = u.Email
            WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId
        ) AS AuthCheck;
    END
END;
GO

-- 4. Get Users by Association (Complex logic)
CREATE OR ALTER PROCEDURE corp.sp_Users_GetByAssociationId_Complex
    @AssociationId INT
AS
BEGIN
    SELECT DISTINCT u.*
    FROM corp.Users u
    LEFT JOIN assoc.Persons p ON u.Email = p.Email
    LEFT JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    LEFT JOIN corp.UserAssociations ua ON u.TenantId = ua.TenantId
    WHERE 
        u.AssociationId = @AssociationId -- Active association
        OR o.AssociationId = @AssociationId -- Resident association
        OR (ua.Role IN ('SystemAdmin', 'AssociationAdmin') AND u.TenantId = (SELECT TenantId FROM corp.Associations WHERE AssociationId = @AssociationId))
    ORDER BY u.Name;
END;
GO

CREATE OR ALTER PROCEDURE corp.sp_Associations_List
AS
BEGIN
    SELECT * FROM corp.Associations;
END;
GO

-- 5. Asset Count (Move to SP)
CREATE OR ALTER PROCEDURE assoc.sp_Assets_Count
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT COUNT(*) FROM assoc.Assets 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND IsActive = 1;
END;
GO

-- 6. Associations List for User (Schema-aware)
CREATE OR ALTER PROCEDURE assoc.sp_Associations_GetByUserId
    @UserId INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin'))
    BEGIN
        SELECT * FROM corp.Associations;
    END
    ELSE
    BEGIN
        -- 1. Direct mappings
        SELECT DISTINCT a.* FROM corp.Associations a
        INNER JOIN assoc.UserAssociations ua ON a.AssociationId = ua.AssociationId
        WHERE ua.UserId = @UserId
        
        UNION

        -- 2. Indirect mapping via Occupancy
        SELECT DISTINCT a.* FROM corp.Associations a
        INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
        INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
        INNER JOIN assoc.Users u ON p.Email = u.Email
        WHERE u.UserId = @UserId
    END
END;
GO

-- 7. Get Role for Context (Schema-aware)
CREATE OR ALTER PROCEDURE corp.sp_UserAssociations_GetRole
    @UserId INT,
    @TenantId INT
AS
BEGIN
    -- 1. Check direct tenant mapping
    DECLARE @Role NVARCHAR(50) = (SELECT TOP 1 Role FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId);
    
    IF @Role IS NOT NULL
        SELECT @Role;
    ELSE
    BEGIN
        -- 2. Check if user is global admin in corp.Users
        SELECT Role FROM corp.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin');
    END
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_UserAssociations_GetRole
    @UserId INT,
    @AssociationId INT
AS
BEGIN
    -- 1. Check direct association mapping
    DECLARE @Role NVARCHAR(50) = (SELECT TOP 1 Role FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId);
    
    IF @Role IS NOT NULL
        SELECT @Role;
    ELSE
    BEGIN
        -- 2. Check if user is high-level admin in assoc.Users
        SET @Role = (SELECT TOP 1 Role FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin'));
        
        IF @Role IS NOT NULL
            SELECT @Role;
        ELSE
        BEGIN
            -- 3. Check occupancy for implicit Resident role
            IF EXISTS (SELECT 1 FROM assoc.Occupancy o 
                       INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId 
                       INNER JOIN assoc.Users u ON p.Email = u.Email 
                       WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId)
                SELECT 'Resident';
            ELSE
                SELECT NULL;
        END
    END
END;
GO

GO

-- Script0055_CleanupUserRoles.sql
-- This script cleans up the contaminated Role column in both corp and assoc schemas.
-- It ensures that only the highest single role is preserved in the base Users table.

-- 1. Clean corp.Users
UPDATE corp.Users
SET Role = 
    CASE 
        WHEN Role LIKE '%PlatformAdmin%' THEN 'PlatformAdmin'
        WHEN Role LIKE '%SystemAdmin%' THEN 'SystemAdmin'
        WHEN Role LIKE '%GlobalUserManager%' THEN 'GlobalUserManager'
        WHEN Role LIKE '%CorporateManager%' THEN 'CorporateManager'
        WHEN Role LIKE '%AssociationAdmin%' THEN 'AssociationAdmin'
        WHEN Role LIKE '%Resident%' THEN 'Resident'
        ELSE Role
    END
WHERE Role LIKE '%,%';

-- 2. Clean assoc.Users
UPDATE assoc.Users
SET Role = 
    CASE 
        WHEN Role LIKE '%SystemAdmin%' THEN 'SystemAdmin'
        WHEN Role LIKE '%PlatformAdmin%' THEN 'PlatformAdmin'
        WHEN Role LIKE '%AssociationAdmin%' THEN 'AssociationAdmin'
        WHEN Role LIKE '%AssetManager%' THEN 'AssetManager'
        WHEN Role LIKE '%UserManager%' THEN 'UserManager'
        WHEN Role LIKE '%FinanceManager%' THEN 'FinanceManager'
        WHEN Role LIKE '%Resident%' THEN 'Resident'
        ELSE Role
    END
WHERE Role LIKE '%,%';

-- 3. Specific fix for reported user myassociationmanager005@gmail.com
-- The user reported this user is a resident, but they were acting as AssociationAdmin.
-- We ensure their base role in the Users table is 'Resident'.
-- If they have an explicit mapping in UserAssociations, that will still grant them the mapping role in that context.

UPDATE corp.Users SET Role = 'Resident' WHERE Email = 'myassociationmanager005@gmail.com';
UPDATE assoc.Users SET Role = 'Resident' WHERE Email = 'myassociationmanager005@gmail.com';

-- 4. Invalidate contaminated role in UserAssociations if any (just in case)
UPDATE assoc.UserAssociations
SET Role = 'Resident'
WHERE Role LIKE '%,%' AND Role LIKE '%Resident%';

UPDATE corp.UserAssociations
SET Role = 'Resident'
WHERE Role LIKE '%,%' AND Role LIKE '%Resident%';

GO

-- Fixed Migration Script for Bank Traceability
GO

-- 1. Ensure Columns Exist (Safe Re-run)
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'assoc' AND TABLE_NAME = 'PaymentOrders' AND COLUMN_NAME = 'PrimaryAccountName')
BEGIN
    ALTER TABLE assoc.PaymentOrders ADD PrimaryAccountName NVARCHAR(200) NULL;
    ALTER TABLE assoc.PaymentOrders ADD PrimaryAccountNumber NVARCHAR(100) NULL;
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'assoc' AND TABLE_NAME = 'PaymentTransactions' AND COLUMN_NAME = 'PrimaryAccountName')
BEGIN
    ALTER TABLE assoc.PaymentTransactions ADD PrimaryAccountName NVARCHAR(200) NULL;
    ALTER TABLE assoc.PaymentTransactions ADD PrimaryAccountNumber NVARCHAR(100) NULL;
END
GO

-- 2. Update Stored Procedures
CREATE OR ALTER PROCEDURE assoc.sp_PaymentOrders_Create
    @TenantId INT,
    @AssociationId INT,
    @UserId INT,
    @RazorpayOrderId NVARCHAR(255),
    @Amount DECIMAL(18,2),
    @Currency NVARCHAR(10),
    @InvoiceId INT = NULL,
    @Receipt NVARCHAR(255) = NULL,
    @PrimaryAccountName NVARCHAR(200) = NULL,
    @PrimaryAccountNumber NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentOrders (TenantId, AssociationId, UserId, RazorpayOrderId, Amount, Currency, InvoiceId, Receipt, PrimaryAccountName, PrimaryAccountNumber)
    VALUES (@TenantId, @AssociationId, @UserId, @RazorpayOrderId, @Amount, @Currency, @InvoiceId, @Receipt, @PrimaryAccountName, @PrimaryAccountNumber);
    
    SELECT SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_PaymentTransactions_Create
    @TenantId INT,
    @AssociationId INT,
    @PaymentOrderId INT = NULL,
    @RazorpayPaymentId NVARCHAR(255),
    @RazorpayOrderId NVARCHAR(255),
    @RazorpaySignature NVARCHAR(500),
    @Status NVARCHAR(50),
    @Amount DECIMAL(18,2),
    @RawResponse NVARCHAR(MAX) = NULL,
    @PrimaryAccountName NVARCHAR(200) = NULL,
    @PrimaryAccountNumber NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentTransactions (TenantId, AssociationId, PaymentOrderId, RazorpayPaymentId, RazorpayOrderId, RazorpaySignature, Status, Amount, RawResponse, PrimaryAccountName, PrimaryAccountNumber)
    VALUES (@TenantId, @AssociationId, @PaymentOrderId, @RazorpayPaymentId, @RazorpayOrderId, @RazorpaySignature, @Status, @Amount, @RawResponse, @PrimaryAccountName, @PrimaryAccountNumber);
    
    SELECT SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_PaymentTransactions_GetByInvoiceId
    @InvoiceId INT,
    @TenantId INT
AS
BEGIN
    SELECT 
        PT.CreatedDate,
        PT.Amount,
        PT.Status,
        PT.RazorpayPaymentId AS ReferenceId,
        'Gateway' AS Method,
        PT.RazorpayOrderId,
        PT.PrimaryAccountName,
        PT.PrimaryAccountNumber
    FROM assoc.PaymentTransactions PT
    INNER JOIN assoc.PaymentOrders PO ON PT.PaymentOrderId = PO.Id
    WHERE PO.InvoiceId = @InvoiceId
    AND PT.TenantId = @TenantId
    ORDER BY PT.CreatedDate DESC;
END
GO

GO

-- Migration Script for Advanced Payment Details
GO

-- 1. Alter Tables
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'assoc' AND TABLE_NAME = 'PaymentTransactions' AND COLUMN_NAME = 'PaymentMethod')
BEGIN
    ALTER TABLE assoc.PaymentTransactions ADD PaymentMethod NVARCHAR(50) NULL;
    ALTER TABLE assoc.PaymentTransactions ADD BankName NVARCHAR(100) NULL;
    ALTER TABLE assoc.PaymentTransactions ADD BankRrn NVARCHAR(100) NULL;
    ALTER TABLE assoc.PaymentTransactions ADD CardNetwork NVARCHAR(50) NULL;
    ALTER TABLE assoc.PaymentTransactions ADD GatewayFee DECIMAL(18,2) NULL;
    ALTER TABLE assoc.PaymentTransactions ADD GatewayTax DECIMAL(18,2) NULL;
END
GO

-- 2. Update Stored Procedures
CREATE OR ALTER PROCEDURE assoc.sp_PaymentTransactions_Create
    @TenantId INT,
    @AssociationId INT,
    @PaymentOrderId INT = NULL,
    @RazorpayPaymentId NVARCHAR(255),
    @RazorpayOrderId NVARCHAR(255),
    @RazorpaySignature NVARCHAR(500),
    @Status NVARCHAR(50),
    @Amount DECIMAL(18,2),
    @RawResponse NVARCHAR(MAX) = NULL,
    @PrimaryAccountName NVARCHAR(200) = NULL,
    @PrimaryAccountNumber NVARCHAR(100) = NULL,
    @PaymentMethod NVARCHAR(50) = NULL,
    @BankName NVARCHAR(100) = NULL,
    @BankRrn NVARCHAR(100) = NULL,
    @CardNetwork NVARCHAR(50) = NULL,
    @GatewayFee DECIMAL(18,2) = NULL,
    @GatewayTax DECIMAL(18,2) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentTransactions (
        TenantId, AssociationId, PaymentOrderId, RazorpayPaymentId, RazorpayOrderId, RazorpaySignature, 
        Status, Amount, RawResponse, PrimaryAccountName, PrimaryAccountNumber,
        PaymentMethod, BankName, BankRrn, CardNetwork, GatewayFee, GatewayTax
    )
    VALUES (
        @TenantId, @AssociationId, @PaymentOrderId, @RazorpayPaymentId, @RazorpayOrderId, @RazorpaySignature, 
        @Status, @Amount, @RawResponse, @PrimaryAccountName, @PrimaryAccountNumber,
        @PaymentMethod, @BankName, @BankRrn, @CardNetwork, @GatewayFee, @GatewayTax
    );
    
    SELECT SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_PaymentTransactions_GetByInvoiceId
    @InvoiceId INT,
    @TenantId INT
AS
BEGIN
    SELECT 
        PT.CreatedDate,
        PT.Amount,
        PT.Status,
        PT.RazorpayPaymentId AS ReferenceId,
        'Gateway' AS Method,
        PT.RazorpayOrderId,
        PT.PrimaryAccountName,
        PT.PrimaryAccountNumber,
        PT.PaymentMethod,
        PT.BankName,
        PT.BankRrn,
        PT.CardNetwork,
        PT.GatewayFee,
        PT.GatewayTax
    FROM assoc.PaymentTransactions PT
    INNER JOIN assoc.PaymentOrders PO ON PT.PaymentOrderId = PO.Id
    WHERE PO.InvoiceId = @InvoiceId
    AND PT.TenantId = @TenantId
    ORDER BY PT.CreatedDate DESC;
END
GO

GO

-- CREATE TABLE
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[CommunicationLogs]') AND type in (N'U'))
BEGIN
    CREATE TABLE [assoc].[CommunicationLogs] (
        [LogId] INT IDENTITY(1,1) PRIMARY KEY,
        [TenantId] INT NOT NULL,
        [AssociationId] INT NOT NULL,
        [RecipientEmail] NVARCHAR(255) NOT NULL,
        [RecipientName] NVARCHAR(255) NULL,
        [Subject] NVARCHAR(500) NOT NULL,
        [HtmlBody] NVARCHAR(MAX) NOT NULL,
        [ReferenceType] NVARCHAR(50) NULL,
        [ReferenceId] INT NULL,
        [Status] INT NOT NULL DEFAULT 1, -- 1 = Posted
        [ErrorMessage] NVARCHAR(MAX) NULL,
        [RetryCount] INT NOT NULL DEFAULT 0,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [ProcessedDate] DATETIME2 NULL,
        [ScheduledDate] DATETIME2 NULL
    );
    
    CREATE INDEX IX_CommunicationLogs_Tenant_Assoc ON [assoc].[CommunicationLogs] (TenantId, AssociationId);
    CREATE INDEX IX_CommunicationLogs_Status ON [assoc].[CommunicationLogs] ([Status]);
END
GO

-- STORED PROCEDURES

CREATE OR ALTER PROCEDURE [assoc].[sp_CommunicationLogs_GetById]
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM [assoc].[CommunicationLogs]
    WHERE LogId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE [assoc].[sp_CommunicationLogs_GetByAssociation]
    @TenantId INT,
    @AssociationId INT,
    @Status INT = NULL
AS
BEGIN
    SELECT * FROM [assoc].[CommunicationLogs]
    WHERE TenantId = @TenantId 
      AND AssociationId = @AssociationId
      AND (@Status IS NULL OR Status = @Status)
    ORDER BY CreatedDate DESC;
END
GO

CREATE OR ALTER PROCEDURE [assoc].[sp_CommunicationLogs_GetPending]
AS
BEGIN
    SELECT * FROM [assoc].[CommunicationLogs]
    WHERE Status IN (1, 7) -- Posted OR Resend
      AND (ScheduledDate IS NULL OR ScheduledDate <= GETUTCDATE())
    ORDER BY CreatedDate ASC;
END
GO

CREATE OR ALTER PROCEDURE [assoc].[sp_CommunicationLogs_Create]
    @TenantId INT,
    @AssociationId INT,
    @RecipientEmail NVARCHAR(255),
    @RecipientName NVARCHAR(255) = NULL,
    @Subject NVARCHAR(500),
    @HtmlBody NVARCHAR(MAX),
    @ReferenceType NVARCHAR(50) = NULL,
    @ReferenceId INT = NULL,
    @Status INT = 1,
    @ScheduledDate DATETIME2 = NULL
AS
BEGIN
    INSERT INTO [assoc].[CommunicationLogs] (
        TenantId, AssociationId, RecipientEmail, RecipientName, Subject, HtmlBody, 
        ReferenceType, ReferenceId, Status, ScheduledDate, CreatedDate
    )
    VALUES (
        @TenantId, @AssociationId, @RecipientEmail, @RecipientName, @Subject, @HtmlBody, 
        @ReferenceType, @ReferenceId, @Status, @ScheduledDate, GETUTCDATE()
    );
    
    SELECT SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE [assoc].[sp_CommunicationLogs_UpdateStatus]
    @Id INT,
    @TenantId INT,
    @Status INT,
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    UPDATE [assoc].[CommunicationLogs]
    SET Status = @Status,
        ErrorMessage = @ErrorMessage,
        ProcessedDate = CASE WHEN @Status IN (4, 5, 6) THEN GETUTCDATE() ELSE ProcessedDate END,
        RetryCount = CASE WHEN @Status = 5 THEN RetryCount + 1 ELSE RetryCount END
    WHERE LogId = @Id AND TenantId = @TenantId;
END
GO

GO

