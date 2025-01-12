USE TIA;
GO

DROP PROCEDURE IF EXISTS populate_fait_Vente;
GO

CREATE PROCEDURE populate_fait_Vente
AS
BEGIN TRANSACTION
BEGIN TRY

    -- Insert data into fait_vente by joining dimension tables
INSERT INTO [fait_vente] ([Quantite_vendue], [Valeur_Rabais], [Benefice_Percu], [date_id],[produit_No], [SalesTerritory_ID] )
SELECT 
    SUM(sod.[OrderQty]) AS [Quantite_vendue],
    SUM(sod.[UnitPriceDiscount] * sod.[UnitPrice] * sod.[OrderQty]) AS [Valeur_Rabais],
    SUM((sod.[UnitPrice] * (1 - sod.[UnitPriceDiscount]) - pp.[StandardCost]) * sod.[OrderQty]) AS [Benefice_Percu],
    dd.[date_id],
    dp.[produit_No],
    dst.[SalesTerritory_ID]
FROM [AdventureWorks2022].[Sales].[SalesOrderHeader] soh
INNER JOIN [AdventureWorks2022].[Sales].[SalesOrderDetail] sod ON soh.[SalesOrderID] = sod.[SalesOrderID]
INNER JOIN [AdventureWorks2022].[Production].[Product] pp ON sod.[ProductID] = pp.[ProductID]
INNER JOIN [AdventureWorks2022].[Sales].[SalesTerritory] sst ON sst.[TerritoryID] = soh.[TerritoryID]
INNER JOIN [dbo].[dim_date] dd ON dd.[date] = soh.[OrderDate]
INNER JOIN [dbo].[dim_produit] dp ON pp.[ProductNumber] = dp.[ProductNumber]
INNER JOIN [dbo].[dim_SalesTerritory] dst ON sst.[Name] = dst.[Nom_Territoire]
    AND dst.[Zone_Geographique] = sst.[Group]
    AND dst.[Code_Pays_Region_ISO] = sst.[CountryRegionCode]
GROUP BY dd.[date_id], dp.[produit_No], dst.[SalesTerritory_ID] 
ORDER BY dp.[produit_No],dd.[date_id],dst.[SalesTerritory_ID],[Benefice_Percu]; --- just to clarify more 



END TRY

BEGIN CATCH
    PRINT('');
    PRINT('ErrorNumber = ' + CAST(ERROR_NUMBER() AS CHAR(10)));
    PRINT('ErrorSeverity = ' + CAST(ERROR_SEVERITY() AS CHAR(10)));
    PRINT('ErrorLine = ' + CAST(ERROR_LINE() AS CHAR(10)));
    PRINT('ErrorMessage = ' + CAST(ERROR_MESSAGE() AS CHAR(400)));

    IF @@TRANCOUNT > 0 
        ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
GO

---test
EXEC dbo.populate_fait_Vente;
GO

select * from [dbo].[fait_vente]


