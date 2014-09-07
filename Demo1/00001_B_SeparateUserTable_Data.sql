
-- Create User records base on latest order placed
WITH LatestOrderPerUser AS (
	SELECT	O_O.Username, 
			LatestOrderId = A.OrderId
	FROM dbo.Orders O_O
		OUTER APPLY ( SELECT TOP 1 OrderId
					  FROM dbo.Orders O_I
					  WHERE O_I.Username = O_O.Username
					  ORDER BY OrderDate DESC ) A
	GROUP BY O_O.Username
)
INSERT INTO dbo.Users(Username, Firstname, LastName, [Address], City, [State], PostalCode, Country, Phone, Email)
SELECT O.Username, Firstname, LastName, [Address], City, [State], PostalCode, Country, Phone, Email
FROM dbo.Orders O
	INNER JOIN LatestOrderPerUser L ON L.LatestOrderId = O.OrderId;


UPDATE O
SET UserId = U.UserId
FROM dbo.Orders O 
	INNER JOIN dbo.Users U ON U.UserName = O.Username;
