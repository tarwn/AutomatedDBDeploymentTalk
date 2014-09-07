-- Create Users Table

CREATE TABLE dbo.Users(
	UserId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	Username nvarchar(max) not null,
	FirstName nvarchar(160) not null,
	LastName nvarchar(160) not null,
	[Address] nvarchar(70) not null,
	City nvarchar(40) not null,
	[State] nvarchar(40) not null,
	PostalCode nvarchar(10) not null,
	Country nvarchar(40) not null,
	Phone nvarchar(24) not null,
	Email nvarchar(max) not null
);

-- Add user id's to the orders tables
ALTER TABLE dbo.Orders ADD UserId int NULL;
