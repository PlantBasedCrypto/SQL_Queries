--SELECT TOP 5 * 
--FROM [KARE].[AllFields_current]

--SELECT TOP 5 * 
--FROM [KARE].[AllEntries_current]

--SELECT TOP 5 * 
--FROM [KARE].[DC_All_Lists_current]

--SELECT TOP 5 * 
--FROM [KARE].[DcDataFact_current]

--WITH cte_proplvltable
--     AS (SELECT ab.entryid,
--                [name],
--                [field name],
--                f.value AS [Value]
--         FROM   kare.vw_propertylevelmortagedebt ab
--                CROSS apply String_split(ab.[value], ';') f)




-------------------------------------------------------Original Unpivoted Table-------------------------------------------------------------------------
--SELECT DISTINCT a.[name],
--                c.[fieldname],
--				b.Value
--FROM   [KARE].[allentries_current] a
--       INNER JOIN [KARE].[dcdatafact_current]   b ON b.entryid = a.entryid --Connect [AllEntries_current] to [DcDataFact_current] with EntryID
--       INNER JOIN [KARE].[allfields_current]    c ON c.fieldid = b.fieldid --Connect [AllFields_current] to [DcDataFact_current] with FieldID
--       INNER JOIN [KARE].[dc_all_lists_current] d ON d.listid = a.listid   --Connect [AllFields_current] to [DcDataFact_current] with FieldID
--	   --inner join CTE on cte.EntryID = ae.EntryID
--WHERE  d.listid = 61531
--       AND c.[fieldname] IN ( 'Debt ID', 'Has Debt?', 'Is Active',
--                              'Maximum Debt', 'Lender', 'Credit Spread', 'Index',
--                              'Rate Type', 'Initial Maturity Date', 'I/O Month End') 
--ORDER BY a.[name]
-------------------------------------------------Pivoted Missing Loans Table----------------------------------------------------------------------------


--SELECT [name], [Debt ID],[Has Debt?], [Is Active],[Maximum Debt],[Lender],[Credit Spread],[Index],[Rate Type],[Initial Maturity Date], [I/O Month End]
--FROM
--(SELECT DISTINCT a.[name],
--                 c.[fieldname],
--				 b.Value
--FROM   [KARE].[allentries_current] a
--       INNER JOIN [KARE].[dcdatafact_current]   b ON b.entryid = a.entryid 
--       INNER JOIN [KARE].[allfields_current]    c ON c.fieldid = b.fieldid 
--       INNER JOIN [KARE].[dc_all_lists_current] d ON d.listid = a.listid   
--	   --inner join CTE on cte.EntryID = ae.EntryID
--WHERE  d.listid = 61531
--       AND c.[fieldname] IN ( 'Debt ID', 'Has Debt?', 'Is Active','Maximum Debt','Lender','Credit Spread','Index','Rate Type','Initial Maturity Date' , 'I/O Month End')) AS Source_Table
--PIVOT
--(Max(Value)
--For
--[fieldname] in ([Debt ID],[Has Debt?], [Is Active],[Maximum Debt],[Lender],[Credit Spread],[Index],[Rate Type],[Initial Maturity Date], [I/O Month End])) as PIVOT_TABLE

---------------------------------------------Final Script With filter on Has Debt-----------------------------------------------
       
--SELECT [name],
--       [debt id],
--       [has debt?]='Yes',
--       [is active]='Yes',
--       [maximum debt],
--       [lender],
--       [credit spread],
--       [index],
--       [rate type],
--       [initial maturity date],
--       [i/o month end],
--	   CASE 
--			WHEN [has debt?] IS NULL THEN 'Missing'
--			WHEN [has debt?] = 'None' THEN 'Missing'
--			WHEN [Is Active] IS NULL THEN 'Missing'
--			WHEN [Is Active] = 'None' THEN 'Missing'
--			WHEN [maximum debt] IS NULL THEN 'Missing'
--			WHEN [maximum debt] = 'None' THEN 'Missing'
--			WHEN [lender] IS NULL THEN 'Missing'
--			WHEN [lender] = 'None' THEN 'Missing'
--			WHEN [credit spread] IS NULL THEN 'Missing'
--			WHEN [credit spread] = 'None' THEN 'Missing'
--			WHEN [index] IS NULL THEN 'Missing'
--			WHEN [index] = 'None' THEN 'Missing'
--			WHEN [Rate Type] IS NULL THEN 'Missing'
--			WHEN [Rate Type] = 'None' THEN 'Missing'
--			WHEN [Initial Maturity Date] IS NULL THEN 'Missing'
--			WHEN [Initial Maturity Date] = 'None' THEN 'Missing'
--			WHEN [I/O Month End] IS NULL THEN 'Missing'
--			WHEN [I/O Month End] = 'None' THEN 'Missing' END AS 'Status'
			

--FROM   (SELECT DISTINCT a.[name],
--                        c.[fieldname],
--                        b.value
--        FROM   [KARE].[allentries_current] a
--               INNER JOIN [KARE].[dcdatafact_current] b
--                       ON b.entryid = a.entryid
--               INNER JOIN [KARE].[allfields_current] c
--                       ON c.fieldid = b.fieldid
--               INNER JOIN [KARE].[dc_all_lists_current] d
--                       ON d.listid = a.listid
--        --inner join CTE on cte.EntryID = ae.EntryID
--        WHERE  d.listid = 61531 
--               AND c.[fieldname] IN ( 'Debt ID', 'Has Debt?', 'Is Active',
--                                      'Maximum Debt',
--                                      'Lender', 'Credit Spread', 'Index',
--                                      'Rate Type',
--                                      'Initial Maturity Date', 'I/O Month End' )
--       ) AS
--       Source_Table
--       PIVOT (Max(value)
--             FOR [fieldname] IN ([Debt ID],
--                                 [Has Debt?],
--                                 [Is Active],
--                                 [Maximum Debt],
--                                 [Lender],
--                                 [Credit Spread],
--                                 [Index],
--                                 [Rate Type],
--                                 [Initial Maturity Date],
--                                 [I/O Month End])) AS pivot_table 
                 
--------------------------------CTE Filtered Table----------------------------------------------------------------------------


WITH CTE_LoanSummary AS (

SELECT [name],
       [debt id],
       [has debt?]='Yes',
       [is active]='Yes',
       [maximum debt],
       [lender],
       [credit spread],
       [index],
       [rate type],
       [initial maturity date],
       [i/o month end],
	   CASE 
			WHEN [has debt?] IS NULL THEN 'Missing'
			WHEN [has debt?] = 'None' THEN 'Missing'
			WHEN [Is Active] IS NULL THEN 'Missing'
			WHEN [Is Active] = 'None' THEN 'Missing'
			WHEN [maximum debt] IS NULL THEN 'Missing'
			WHEN [maximum debt] = 'None' THEN 'Missing'
			WHEN [lender] IS NULL THEN 'Missing'
			WHEN [lender] = 'None' THEN 'Missing'
			WHEN [credit spread] IS NULL THEN 'Missing'
			WHEN [credit spread] = 'None' THEN 'Missing'
			WHEN [index] IS NULL THEN 'Missing'
			WHEN [index] = 'None' THEN 'Missing'
			WHEN [Rate Type] IS NULL THEN 'Missing'
			WHEN [Rate Type] = 'None' THEN 'Missing'
			WHEN [Initial Maturity Date] IS NULL THEN 'Missing'
			WHEN [Initial Maturity Date] = 'None' THEN 'Missing'
			WHEN [I/O Month End] IS NULL THEN 'Missing'
			WHEN [I/O Month End] = 'None' THEN 'Missing' END AS 'Status'
			

FROM   (SELECT DISTINCT a.[name],
                        c.[fieldname],
                        b.value
        FROM   [KARE].[allentries_current] a
               INNER JOIN [KARE].[dcdatafact_current] b
                       ON b.entryid = a.entryid
               INNER JOIN [KARE].[allfields_current] c
                       ON c.fieldid = b.fieldid
               INNER JOIN [KARE].[dc_all_lists_current] d
                       ON d.listid = a.listid
        --inner join CTE on cte.EntryID = ae.EntryID
        WHERE  d.listid = 61531 
               AND c.[fieldname] IN ( 'Debt ID', 'Has Debt?', 'Is Active',
                                      'Maximum Debt',
                                      'Lender', 'Credit Spread', 'Index',
                                      'Rate Type',
                                      'Initial Maturity Date', 'I/O Month End' )
       ) AS
       Source_Table
       PIVOT (Max(value)
             FOR [fieldname] IN ([Debt ID],
                                 [Has Debt?],
                                 [Is Active],
                                 [Maximum Debt],
                                 [Lender],
                                 [Credit Spread],
                                 [Index],
                                 [Rate Type],
                                 [Initial Maturity Date],
                                 [I/O Month End])) AS pivot_table )


 Select *
 FROM CTE_LoanSummary
 WHERE Status ='Missing'