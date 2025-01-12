
USE TIA;
GO

IF OBJECT_ID('stage_produit', 'U') IS NOT NULL
    DROP TABLE stage_produit;

IF OBJECT_ID('product_upload', 'P') IS NOT NULL
    DROP PROCEDURE product_upload;

CREATE TABLE stage_produit (
    ProductID INT not null,
    Evaluation DECIMAL(3,2) not null
    );
GO

CREATE OR ALTER PROCEDURE product_upload
    @LoadType BIT
AS
BEGIN TRANSACTION
BEGIN TRY 

    -- Charger les données CSV dans la table de staging
    BULK INSERT stage_produit   
    FROM 'C:\Users\Gilles\Desktop\TP 4\produits_evaluations.csv'
    WITH
    (
        FIRSTROW = 3,            
        FIELDTERMINATOR = ';',    
        ROWTERMINATOR = '\n',    
        MAXERRORS = 0,
        TABLOCK                    
    );

    -- Charger les données JSON dans la table de staging 
    DECLARE @json NVARCHAR(MAX);

    SELECT @json = BulkColumn FROM OPENROWSET (BULK 'C:\Users\Gilles\Desktop\TP 4\produits_evaluations.json', SINGLE_CLOB) AS j;

    INSERT INTO stage_produit (ProductID, Evaluation)
    SELECT 
        ProductID,
        Evaluation
    FROM OPENJSON(@json)
    WITH (
        ProductID INT '$.ProductID',
        Evaluation DECIMAL(3,2) '$.Evaluation'
    );

    IF (@LoadType = 0) 
    BEGIN 
        INSERT INTO dim_produit (product_name, ProductNumber, Jours_Sur_Le_Marche, Evaluation_Moyenne, Style_Produit, Margeproduit, EffectiveDate)
        SELECT 
        pp.[Name] AS product_name,
        pp.ProductNumber as ProductNumber,
        CASE
            WHEN pp.SellEndDate IS NULL THEN DATEDIFF(DAY, pp.SellStartDate, GETDATE())
            ELSE DATEDIFF(DAY, pp.SellStartDate, pp.SellEndDate)
        END AS Jours_Sur_Le_Marche,
        ROUND(AVG(COALESCE(sp.Evaluation, pr.Rating)), 2) AS Evaluation_Moyenne,
        CASE
            WHEN pp.Style = 'W' THEN 'Women'
            WHEN pp.Style = 'M' THEN 'Men'
            WHEN pp.Style = 'U' THEN 'Universal'
            ELSE 'Unavailable'
        END AS Style_Produit,
        CASE
            WHEN sod.UnitPriceDiscount > 0 THEN pp.StandardCost * (1 - sod.UnitPriceDiscount)
            ELSE pp.StandardCost
        END AS Margeproduit,
        pp.ModifiedDate
        FROM AdventureWorks2022.Production.Product pp
        LEFT JOIN AdventureWorks2022.Sales.SalesOrderDetail sod ON pp.ProductID = sod.ProductID
        LEFT JOIN AdventureWorks2022.Production.ProductReview pr ON pp.ProductID = pr.ProductID
        LEFT JOIN stage_produit sp ON pp.ProductID = sp.ProductID
        GROUP BY 
        pp.[Name], 
        pp.ProductNumber, 
        pp.SellEndDate, 
        pp.SellStartDate, 
        pp.Style, 
        pp.StandardCost,
        sod.UnitPriceDiscount,
        pp.ModifiedDate
		
   
  end
	END TRY

BEGIN CATCH
    print('') 
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

--- CREATION INDEX ---
--- drop si existe
IF EXISTS (SELECT name FROM sys.indexes WHERE name = 'idx_Margeproduit' AND object_id = OBJECT_ID('dim_produit'))
    DROP INDEX idx_Margeproduit ON dim_produit;
GO

--- creer index---
CREATE INDEX idx_Margeproduit ON dim_produit (Margeproduit);

/*Pourquoi avoir utiliser un index sur l'attribut Margeproduit ?

1. Performance des requêtes: Accélère les requêtes filtrant ou triant par Margeproduit.
2. Analyses rapides: Facilite les calculs et rapports sur les marges de profit.
3. Filtres et tris: Rend les opérations de tri et de filtrage plus rapides.
4. Optimisation: Réduit la charge sur le serveur, surtout pour de grandes tables.*/

----creation metadonnes -------
EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Product style (Women, Men, Universal, Unavailable – if NULL)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'dim_produit', 
    @level2type = N'COLUMN', @level2name = N'Style_Produit';
GO


----execute la procedure----------
EXEC dbo.product_upload @LoadType = 0;

select * from dbo.dim_produit p
















