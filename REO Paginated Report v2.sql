AS
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
	

		,  O.Occupancy
		, [Quarter End Date] = O.Date

		---- vwj_FinancialActivityREO
		, [T-12 NOI] = NULL
		, [Debt Balance] = NULL
		, [Invested Equity] = NULL
		, [Debt Service] = NULL

		-- vwj_ValuationsREO
		, [FMV] = V.Valuation
		, V.[Valuation Method]

		-- Calculation
		, [LTV] = NULL
		, [Years Owned] = NULL
		, [DSCR] = NULL
	FROM [KARE].[vw_PropertyLevelMortageDebtREO] PLM WITH(NOLOCK)
	INNER JOIN KARE.vw_Master_Property_View_Closed MPVC WITH(NOLOCK)
		ON PLM.[PropertyName] = MPVC.PropertyName
	INNER JOIN [KARE].[vw_OccupancyREO] O WITH(NOLOCK)
		ON PLM.PropertyName = O.[Property Name]
	INNER JOIN [KARE].[vwj_ValuationsREO] V WITH(NOLOCK)
		ON MPVC.PropertyID = V.DCPropertyID AND O.Date = CAST(V.[Quarter End Date] AS Date)
	LEFT JOIN [KARE].[vwj_FinancialActivityREO] F WITH(NOLOCK)
		ON MPVC.PropertyID = F.DCPropertyID AND O.Date = F.TransactionDate
	