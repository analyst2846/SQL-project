USE TIA;
GO

IF OBJECT_ID('populate_dim_date', 'P') IS NOT NULL
    DROP PROCEDURE populate_dim_date;
GO

CREATE OR ALTER PROCEDURE populate_dim_date
    @DateDebut DATE,
    @DateFin DATE
AS
BEGIN TRANSACTION
BEGIN TRY

    ----- initialiser la date courante
    DECLARE @DateCourante DATE = CONVERT(DATETIME, @DateDebut, 105);

--- looper à travers chaque date du début à la fin
    WHILE @DateCourante <= @DateFin
    BEGIN
        INSERT INTO dim_date ([date], jour, mois, trimestre, annee_civile, annee_fiscale, trimestre_fiscal, plan_strategique)
        VALUES (
            @DateCourante, -- [date]
                DAY(@DateCourante), -- jour
        MONTH(@DateCourante), --- mois
            DATEPART(QUARTER, @DateCourante), -- trimestre
    YEAR(@DateCourante), --- annee_civile
            CASE 
                WHEN MONTH(@DateCourante) >= 6 THEN YEAR(@DateCourante)
                ELSE YEAR(@DateCourante) - 1
        END, -- annee_fiscale
            CASE 
                WHEN MONTH(@DateCourante) BETWEEN 6 AND 8 THEN 1
               WHEN MONTH(@DateCourante) BETWEEN 9 AND 11 THEN 2
                WHEN MONTH(@DateCourante) IN (12, 1, 2) THEN 3
    WHEN MONTH(@DateCourante) IN (3, 4, 5) THEN 4
            END, -- trimestre_fiscal
        FLOOR((DATEDIFF(YEAR, @DateDebut, @DateCourante) / 3.0) + 1) -- plan_strategique
        );

        set @DateCourante = DATEADD(DAY, 1, @DateCourante); ---- augmenter la date courante de 1 jour
    END

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

EXEC dbo.populate_dim_date '2012-01-01', '2013-12-31'; ---- exécuter la procédure stockée pour peupler la table dim_date ( intervalle de dates non spécifié dans l'énoncé, on peut prenre 2011 a 2014 aussi )
select * from [dbo].[dim_date]