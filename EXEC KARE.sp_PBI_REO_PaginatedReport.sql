BEGIN

	IF Object_id(N'tempdb..#MortageCloseProperties') IS NOT NULL
	BEGIN
		DROP TABLE #MortageCloseProperties
	END

	IF Object_id(N'tempdb..#OccupancyREO') IS NOT NULL
	BEGIN
		DROP TABLE #OccupancyREO
	END
	
	IF Object_id(N'tempdb..#TempT12NOI') IS NOT NULL
	BEGIN
		DROP TABLE #TempT12NOI
	END

	IF Object_id(N'tempdb..#TempDebtService') IS NOT NULL
	BEGIN
		DROP TABLE #TempDebtService
	END

	IF Object_id(N'tempdb..#TempDebtBalanceAndInvested') IS NOT NULL
	BEGIN
		DROP TABLE #TempDebtBalanceAndInvested
	END

	-- Mortage Debt Close Props
	SELECT
		PLM.[Debt ID]
		, PLM.[Debt Name]
		, PLM.[Lender]
		, PLM.[Maximum Debt]
		, PLM.[Rate Type]
		, PLM.[Credit Spread]
		, PLM.[Origination Date]
		, PLM.[I/O Month End]
		, PLM.[Initial Maturity Date]
		, PLM.[PropertyName]
		, PLM.[Index]

		, MPVC.[Kayne Funds]
		, [Capital Investment] = MPVC.[Acquisition Capital Investment]
		, MPVC.[MRI Code]
		, [State] = MPVC.[US State]
		, MPVC.[City]
		, [Property Type] = MPVC.[Sector]
		, [Property Closed Date] = MPVC.[Acquisition Close Date]
		, [Type] = MPVC.[Investment Type]
		, [Units/Beds/Sqft] = MPVC.[Rentable SF]
		, [Owned %] = NULL
		, [REIT/OC] = MPVC.[REIT / OC]
		, MPVC.PropertyID
	INTO #MortageCloseProperties
	FROM [KARE].[vw_PropertyLevelMortageDebtREO] PLM WITH(NOLOCK)
	INNER JOIN KARE.vw_Master_Property_View_Closed MPVC WITH(NOLOCK)
		ON PLM.[PropertyName] = MPVC.PropertyName

	-- Occupancy
	SELECT 
		Date
		, [DC Property ID]
		, Supply
		, Demand
		, Occupancy
	INTO #OccupancyREO
	FROM [KARE].[vw_OccupancyREO_V2] WITH(NOLOCK)


	-- T12 NOI
	;WITH T12NOI_CTE AS
	(
		SELECT EntityID
		   , Period
		   , PeriodDate = KARE.Fn_convertperiod_to_date(Period)
		   , T12NOI = SUM(Activity)
		FROM KARE.mri_glsum_current s
		WHERE balfor = 'N'
			AND ( ACCTNUM LIKE 'KA4%'
					OR ACCTNUM LIKE 'KA5%' )
			AND Basis = 'A'
			AND Period > 202012
			AND (EntityID NOT BETWEEN 320000 AND 329999
					AND EntityID NOT BETWEEN 832000 AND 832999
					OR EntityID IN (320080, 320081))
		GROUP BY EntityID
		   , Period
	)
	SELECT
		T1.EntityID
		, T1.Period
		, T1.PeriodDate
		, T12NOI = -SUM(T2.T12NOI)
	INTO #TempT12NOI
	FROM T12NOI_CTE T1
	INNER JOIN T12NOI_CTE T2
		ON T1.ENTITYID = T2.ENTITYID
			AND T2.PeriodDate >= DATEADD(MONTH, -11, T1.PeriodDate) AND T2.PeriodDate <= T1.PeriodDate	
	GROUP BY  T1.EntityID
		, T1.Period
		, T1.PeriodDate

	-- debt balance and invested equity
	;WITH CTE_DB AS
	(
		SELECT EntityID
			, Period
			, PeriodDate = KARE.Fn_convertperiod_to_date(Period)
			, [Debt Balance] = SUM(CASE WHEN ACCTNUM LIKE 'KA2500%' THEN ISNULL(Activity, 0) ELSE 0 END)
			, [Invested Equity] = SUM(CASE WHEN ACCTNUM LIKE 'KA3130%' THEN ISNULL(Activity, 0) ELSE 0 END)
	
		FROM   KARE.MRI_GLSUM_current s
		WHERE  balfor = 'N'
			AND (ACCTNUM LIKE 'KA2500%' OR ACCTNUM LIKE 'KA3130%')
			AND basis = 'A'
		GROUP BY S.EntityID
		, S.Period
	)
	SELECT T.EntityID
		, PeriodDate = Q.Quarter
		, [Debt Balance] = -SUM(T.[Debt Balance])
		, [Invested Equity] = -SUM(T.[Invested Equity])
	INTO #TempDebtBalanceAndInvested
	FROM kare.TblQuarter Q
	INNER JOIN CTE_DB T
		ON T.PeriodDate <= Q.Quarter
	--WHERE T.EntityID = 400524
	--	AND Q.Quarter = '2022-06-30' 
	GROUP BY T.EntityID
		, Q.Quarter

	-- debt service
	SELECT EntityID
		, Period
		, PeriodDate = KARE.Fn_convertperiod_to_date(Period)
		, [Debt Service] = SUM(Activity) * 12
	INTO #TempDebtService
	FROM   KARE.MRI_GLSUM_current s
	WHERE  BALFOR = 'N'
		AND AcctNum LIKE 'KA600000%'
		AND Basis = 'A'
		--AND EntityID = 400524
		--AND Period = 202206
	GROUP BY EntityID
		, Period


	SELECT 
		MP.[Debt ID]
		, MP.[Debt Name]
		, MP.[Lender]
		, MP.[Maximum Debt]
		, MP.[Rate Type]
		, MP.[Credit Spread]
		, MP.[Origination Date]
		, MP.[I/O Month End]
		, MP.[Initial Maturity Date]
		, MP.[PropertyName]
		, MP.PropertyID
		, MP.[Index]

		, MP.[Kayne Funds]
		, MP.[Capital Investment]
		, MP.[MRI Code]
		, MP.[State]
		, MP.[City]
		, MP.[Property Type]
		, MP.[Property Closed Date]
		, MP.[Type]
		, MP.[Units/Beds/Sqft]
		, [Owned %] = NULL
		, MP.[REIT/OC]

		-- Occupancy
		, [Quarter End Date] = O.Date
		, O.Occupancy

		-- valiation
		, FMV = CAST(CASE WHEN V.[Valuation] = 'None' THEN '0' ELSE V.[Valuation] END AS FLOAT)
		, V.[Valuation Method]

		-- Financial
		, [T-12 NOI] = F1.T12NOI
		, F2.[Debt Balance]
		, F2.[Invested Equity]
		, F3.[Debt Service]

		-- Calculation
		, LTV = CASE WHEN ISNULL(CAST(CASE WHEN V.[Valuation] = 'None' THEN '0' ELSE V.[Valuation] END AS FLOAT), 0) = 0 THEN 0 ELSE F2.[Debt Balance]/CAST(CASE WHEN V.[Valuation] = 'None' THEN '0' ELSE V.[Valuation] END AS FLOAT) END
		, [Years Owned] = ROUND(DATEDIFF(DAY, [Property Closed Date], O.Date)/365.0, 2)
		, [DSCR] = CASE WHEN ISNULL(F3.[Debt Service], 0) = 0 THEN 0 ELSE F1.T12NOI / F3.[Debt Service] END

	

	FROM #MortageCloseProperties MP
	INNER JOIN #OccupancyREO O
		ON MP.PropertyID = O.[DC Property ID]
	INNER JOIN [KARE].[vwj_ValuationsREO] V WITH(NOLOCK)
		ON MP.PropertyID = V.DCPropertyID AND O.Date = CAST(V.[Quarter End Date] AS Date)
	LEFT JOIN KARE.DC_MRI_Map_current MAP WITH(NOLOCK)
		ON MP.PropertyID = MAP.EntryID
	LEFT JOIN #TempT12NOI F1 
		ON MAP.MRICODE = F1.EntityID 
			AND O.Date = F1.PeriodDate
	LEFT JOIN #TempDebtBalanceAndInvested F2
		ON MAP.MRICODE = F2.EntityID 
			AND O.Date = F2.PeriodDate
	LEFT JOIN #TempDebtService F3 
		ON MAP.MRICODE = F3.EntityID 
			AND O.Date = F3.PeriodDate
	--WHERE [Debt Name] = 'Capital One (Facility Opp Fund LOC I) K5 Med4'
		--AND O.Date = '2022-06-30'


END