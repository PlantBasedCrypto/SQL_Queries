WITH entrieswithmissingdata
	  --- isolate unique entryids that have at least one of the fields you specify missing.
	  -- all that matters is that the id is present in a list where value = 'None'. This replaces the need to check each field you create horizontally.
	  -- you dont care what field is missing, but that there is at least one
	AS (
		SELECT DISTINCT ae.entryid
		FROM   kare.allentries_current ae
				INNER JOIN kare.dcdatafact_current f
						ON f.entryid = ae.entryid
				INNER JOIN kare.allfields_current af
						ON af.fieldid = f.fieldid
		WHERE  af.fieldname IN ( 'Has Debt?','Debt ID', 'Is Active', 'Maximum Debt',
								'Lender',
								'Credit Spread', 'Index', 'Rate Type',
								'Initial Maturity Date','I/O Month End' )
				AND ae.listid = 61531
				--AND value = 'None'
	),
	---2
	-- create a CTE and inner join to your first CTE so that only entries contained in the list of entries with at least one thing missing are present            
	sourcetable
	AS (
		SELECT ae.NAME AS [Debt Name],
			af.fieldname,
			[Kayne Funds] = CASE WHEN L.[Kayne Funds] = 'None' THEN NULL ELSE L.[Kayne Funds] END,
			L.[Property Name],
			PIT.[Investment Type],
			case when  f.value = 'None' then null else value end as [Value]
		FROM   kare.allentries_current ae
				INNER JOIN kare.dcdatafact_current f
					ON f.entryid = ae.entryid
				INNER JOIN kare.allfields_current af
					ON af.fieldid = f.fieldid
				INNER JOIN entrieswithmissingdata e
					ON e.entryid = ae.entryid
				LEFT JOIN KARE.vw_DC_Loan_First_Property_Has_KayneFund L
					ON L.LoanEntryID = f.entryid
				LEFT JOIN KARE.vw_DC_Property_InvestmentType PIT
					ON L.[Property Name] = PIT.[Property Name]
		WHERE  af.fieldname IN ( 'Debt ID', 'Has Debt?', 'Is Active',
								'Maximum Debt',
								'Lender', 'Credit Spread', 'Index',
								'Rate Type',
								'Initial Maturity Date', 'I/O Month End' )
				AND ae.listid = 61531
	)
	--pivot the resulting table where the columns are rows

	 SELECT [debt name],
			 [has debt?],
			 CASE WHEN [Kayne Funds] ='KAREP IV;KAREP V' THEN 'SENTIO' ELSE [Kayne Funds] END AS 'Kayne Funds',
			 [Investment Type],
			 [Debt ID],
			 [is active],
			cast ([maximum debt] as float) as [maximum debt],
			 [lender],
			 cast([credit spread] as float) as [credit spread],
			 [index],
			 [rate type],
			 cast([initial maturity date] as date) as [Initial Maturity Date],
			 cast([i/o month end] as date) as [I/O Month End],
			 DATEDIFF(day, CAST( GETDATE() AS Date ), cast([initial maturity date] as date)) AS 'Days'
	FROM   sourcetable
	PIVOT( Max(value)
		FOR [fieldname] IN ([Has Debt?],
							[Debt ID],
							[Is Active],
							[Maximum Debt],
							[Lender],
							[Credit Spread],
							[Index],
							[Rate Type],
							[Initial Maturity Date],
							[I/O Month End]) 
		)pt
	where [Has Debt?]<>'No' 
		AND [Is Active] = 'Yes' 
		AND LEFT ([Debt ID],2) <>'00'
		AND cast([initial maturity date] as date) <= DATEADD(DAY, 120, GETUTCDATE())