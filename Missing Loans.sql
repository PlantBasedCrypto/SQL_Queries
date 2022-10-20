WITH cte_proplvltable
     AS (SELECT 
				ab.entryid,
                [name],
                [field name],
                f.value AS [Value]
         FROM   kare.vw_propertylevelmortagedebt ab
                CROSS apply String_split(ab.[value], ';') f)

--cte_proplvltableLender
--     AS (SELECT 
--				ac.entryid,
--                [name],
--                [field name],
--                e.value AS [Value]
--         FROM   kare.vw_propertylevelmortagedebt ac
--                CROSS apply String_split(ac.[value], ';') e
		 --WHERE Value = 'Lender')
-----------------------------------------------------------------------------------------------------------------------
-----------------Step 2 get properties from kare.vw_Master_Property_View_Closed DealCloud list-------------------------
--SELECT * --cte_proplvltable.[name]
--FROM cte_proplvltable


SELECT DISTINCT cte_proplvltable.[name],count(case when cte_proplvltable.[field name] is null then 1 end) field_null
FROM cte_proplvltable
order by cte_proplvltable.[name] DESC
