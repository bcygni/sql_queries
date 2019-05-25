SELECT 
	OrderNumber,
	Equipment,
	StartTime,
	EndTime,
	Employee,
	JoinTime,
	LeaveTime,
	NextCrew,

	CASE
	
		--When Crew was joined before Order was started and (Crew was left after Order Ended or (Crew has not been left yet or Order is still running))
		--Then use time between StartTime and EndTime or LeaveTime if Order has not ended or CurrentTime if Order has not ended and employee is still on crew
		WHEN JoinTime < StartTime AND (LeaveTime >= EndTime or (EndTime is NULL OR LeaveTime is NULL))
			THEN DATEDIFF('second', StartTime, COALESCE(EndTime, LeaveTime, NOW()::timestamp))/60
				
														
		-- When Crew was joined in the middle of Order and (Crew was left after Order Ended or (Crew has not been left yet or Order is still running))
		-- Then use time between JoinTime and EndTime or LeaveTime if Order has not ended or CurrentTime if Order has not ended and employee is still on crew
		WHEN JoinTime >= StartTime AND (LeaveTime >= EndTime or (EndTime is NULL OR LeaveTime is NULL))
			THEN DATEDIFF('second', JoinTime, COALESCE(EndTime, LeaveTime, NOW()::timestamp))/60										
							
													   
		-- When Crew was joined before order was started and Crew was left before Order Ended
		-- Then use time between JoinTime and LeaveTime
		WHEN JoinTime < StartTime AND LeaveTime <= EndTime						
			THEN DATEDIFF('second', StartTime, Leavetime)/60
																				   
		WHEN JoinTime >= StartTime AND LeaveTime <= EndTime
			THEN DATEDIFF('second', JoinTime, LeaveTime)/60
		ELSE
			NULL
													   
	END AS TimeOnJob,
					  
													   
	CASE
	
		--When Crew was joined before Order was started and (Crew was left after Order Ended or (Crew has not been left yet or Order is still running))
		--Then use time between StartTime and EndTime or LeaveTime if Order has not ended or CurrentTime if Order has not ended and employee is still on crew
		WHEN JoinTime < StartTime AND (LeaveTime >= EndTime or (EndTime is NULL OR LeaveTime is NULL))
			THEN 'A'
				
														
		-- When Crew was joined in the middle of Order and (Crew was left after Order Ended or (Crew has not been left yet or Order is still running))
		-- Then use time between JoinTime and EndTime or LeaveTime if Order has not ended or CurrentTime if Order has not ended and employee is still on crew
		WHEN JoinTime >= StartTime AND (LeaveTime >= EndTime or (EndTime is NULL OR LeaveTime is NULL))
			THEN 'B'										
							
													   
		-- When Crew was joined before order was started and Crew was left before Order Ended
		-- Then use time between JoinTime and LeaveTime
		WHEN JoinTime < StartTime AND LeaveTime <= EndTime						
			THEN 'C'
														   
		-- When Crew was joined after order was started and Crew was left before Order Ended
		-- Then use time between JoinTime and LeaveTime													 
		WHEN JoinTime >= StartTime AND LeaveTime <= EndTime
			THEN 'D'
		ELSE
			NULL
													   
	END AS TimeOnJobCode								   
													   	   
FROM AllEvents
ORDER BY StartTime, JoinTime
