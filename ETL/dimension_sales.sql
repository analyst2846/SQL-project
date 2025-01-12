USE TIA
GO

IF OBJECT_ID('populate_dim_SalesTerritory', 'P') IS NOT NULL
    DROP PROCEDURE populate_dim_SalesTerritory;
GO

CREATE PROCEDURE populate_dim_SalesTerritory
AS
BEGIN TRANSACTION
BEGIN TRY
 
    -- Insert new data into the dimension table
    INSERT INTO dim_SalesTerritory (Nom_Territoire, Code_Pays_Region_ISO, Zone_Geographique, Annee_Vente, Total_Ventes_Annee_Courante, Total_Ventes_Annee_Precedente, Difference_Ventes, Difference_Pourcentage,EffectiveDate)
    SELECT 
        st.[Name] AS Nom_Territoire,
        st.CountryRegionCode AS Code_Pays_Region_ISO,
        st.[Group] AS Zone_Geographique,
        YEAR(soh.OrderDate) AS Annee_Vente,
        SUM(soh.SubTotal)  AS Total_Ventes_Annee_Courante,
        LAG(SUM(soh.SubTotal), 1, 0) OVER (PARTITION BY st.[Name], st.CountryRegionCode, st.[Group] ORDER BY YEAR(soh.OrderDate)) AS Total_Ventes_Annee_Precedente,
        SUM(soh.SubTotal) - LAG(SUM(soh.SubTotal), 1, 0) OVER (PARTITION BY st.[Name], st.[CountryRegionCode], st.[Group] ORDER BY YEAR(soh.OrderDate)) AS Difference_Ventes,
        (SUM(soh.SubTotal) - LAG(SUM(soh.SubTotal), 1, 0) OVER (PARTITION BY st.[Name], st.[CountryRegionCode], st.[Group] ORDER BY YEAR(soh.OrderDate))) / NULLIF(LAG(SUM(soh.SubTotal), 1, 0) OVER (PARTITION BY st.[Name], st.[CountryRegionCode], st.[Group] ORDER BY YEAR(soh.OrderDate)), 0)*100 AS Difference_Pourcentage,
		st.ModifiedDate AS EffectiveDate
    FROM AdventureWorks2022.sales.SalesTerritory st
    INNER JOIN AdventureWorks2022.sales.SalesOrderHeader soh ON st.TerritoryID = soh.TerritoryID
    GROUP BY st.[Name],st.CountryRegionCode, st.[Group], YEAR(soh.OrderDate), st.ModifiedDate
	order by 1,4  --- ajout pour meilleure lecture seulement
END TRY

BEGIN CATCH
    PRINT('')
    PRINT('Numéro d''erreur = ' + CAST(ERROR_NUMBER() AS CHAR(10)))
    PRINT('Gravité de l''erreur = ' + CAST(ERROR_SEVERITY() AS CHAR(10)))
    PRINT('Ligne de l''erreur = ' + CAST(ERROR_LINE() AS CHAR(10)))
    PRINT('Message de l''erreur = ' + CAST(ERROR_MESSAGE() AS CHAR(400)))

    IF @@TRANCOUNT > 0 
        ROLLBACK TRANSACTION; -- annuler la transaction en cas d'erreur
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION; ---- Valider la transaction s'il n'y a pas d'erreurs
GO


exec dbo.populate_dim_SalesTerritory

select * from [dbo].[dim_SalesTerritory] 


