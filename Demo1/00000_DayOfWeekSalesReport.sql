CREATE PROCEDURE dbo.usp_GetOrderTotalsByDayOfWeek AS
BEGIN

	SELECT 
		[WeekDay] = DATEPART(WEEKDAY, OrderDate),
		SumTotal = SUM(Total),
		AvgTotal = AVG(Total),
		MinTotal = MIN(Total),
		MaxTotal = MAX(Total)
	FROM Orders
	GROUP BY DATEPART(WEEKDAY, OrderDate);

END