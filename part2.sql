/*
 *		TECH 60701 -- Technologies de l'intelligence d'affaires
 *					HEC Montr�al
 *		Travail Pratique 2
 *					Enseignant :
 *						J01 : Bogdan Negoita
 *		
 *		Instructions de remise :
 *			- R�pondre aux questions SQL directement dans ce fichier .sql
 *			- La remise du devoir doit �tre effectu�e via ZoneCours dans l'outil de remise de travaux
 *			- Date de remise : voir les dates sur ZoneCours, aucun retard permis
 *
 *		Correction :
 *			- 9% de la note finale, /9
 *			- Une question qui g�n�re une erreur (ne s'ex�cute pas) se verra attribuer automatiquement la note de 0.
 */

use AdventureWorks2022;
go




/***************** QUESTION 1 (2,5 points) *****************/
/* 
	AdventureWorks vous demande de r�diger une requ�te permettant de voir le total des ventes par cat�gorie 
	(s�il y en a�) entre d�cembre 2012 et d�cembre 2013, inclusivement. On a besoin d'afficher les informations
	suivantes:
		- Identifiant de la cat�gorie (N/A, si non disponible),
		- Nom de la cat�gorie (N/A, si non disponible),
		- Ann�e des ventes,
		- Trimestre des ventes,
		- Num�ro du mois des ventes,
		- Nom du mois des ventes (NOTE: peu importe que la valeur s'affiche en anglais ou en fran�ais...),
		- Somme des ventes (sous forme mon�taire) de la cat�gorie pour le mois de l'ann�e correspondants.
	
	Le tout devra �tre tri� de fa�on ascendante par identificateur de cat�gorie, ann�e et mois des ventes.
*/

use AdventureWorks2022;
go


SELECT 
    COALESCE(pc.[ProductCategoryID], 'N/A') AS "ID cat�gorie",
    COALESCE(pc.[Name], 'N/A') AS "Nom de la cat�gorie",
    DATEPART(YEAR, sod.[ModifiedDate]) AS Ann�e,
    DATEPART(QUARTER, sod.[ModifiedDate]) AS Trimestre,
    MONTH(sod.[ModifiedDate]) AS "Num�ro du mois",
    DATENAME(MONTH, sod.[ModifiedDate]) AS "Nom du mois des ventes",
    FORMAT(SUM(sod.[LineTotal]), 'C', 'en-US') AS "Somme des ventes"

FROM 
    [Production].[Product] p 
    INNER JOIN 
    [Sales].[SalesOrderDetail] sod ON p.[ProductID] = sod.[ProductID]
    LEFT JOIN 
    [Production].[ProductSubcategory] psc ON p.[ProductSubcategoryID] = psc.[ProductSubcategoryID]
    LEFT JOIN 
    [Production].[ProductCategory] pc ON psc.[ProductCategoryID] = pc.[ProductCategoryID]

 
    WHERE sod.[ModifiedDate] BETWEEN '2012-12-01' AND '2013-12-31'
GROUP BY 
    COALESCE(pc.[ProductCategoryID], 'N/A'), 
    COALESCE(pc.[Name], 'N/A'),
    DATEPART(YEAR, sod.[ModifiedDate]),
    DATEPART(QUARTER, sod.[ModifiedDate]),
    MONTH(sod.[ModifiedDate]),
    DATENAME(MONTH, sod.[ModifiedDate])
ORDER BY 
    1,3,5



/***************** QUESTION 2 (3,25 points) *****************/
/* 
	AdventureWorks vous demande maintenant de r�diger une requ�te permettant de voir �galement les ventes du mois 
	pr�c�dent pour chaque ligne des r�sultats de la requ�te r�dig�e pour r�pondre � la demande pr�c�dente.

	On a besoin d'ajouter les informations suivantes :
	- le total des ventes pour le mois pr�c�dant
	- la diff�rence entre le total des ventes du mois courant et celui du mois pr�c�dant
	- le pourcentage de fluctuation des ventes par rapport au mois pr�c�dent

	Ne voulant pas perdre de temps � ajuster la requ�te pr�c�dente, vous d�cidez de l'exploiter dans le contexte
	d�une CTE vous permettant de r�pondre � la nouvelle demande.

	Extrait des r�sultats (remarquer le format d'affichage pour le pourcentage de fluctuation des ventes):

	CategoryID	CategoryName	SalesYear	SalesQuarter	SalesMonthNumber	SalesMonthName	TotalSales		TotalSalesLastMonth	NetChange		PercentageChange
	----------- --------------- ----------- --------------- -------------------	---------------	---------------	-------------------	---------------	-------------------
	1			Bikes			2012        4				12					d�cembre		$2,598,926.59	NULL				NULL			NULL
	1			Bikes			2013        1				1					janvier			$1,883,815.42	$2,598,926.59       ($715,111.17)	-27,52 %
	1			Bikes			2013        1				2					f�vrier			$1,961,526.99	$1,883,815.42       $77,711.57		4,13 %
	1			Bikes			2013        1				3					mars			$2,878,097.80	$1,961,526.99       $916,570.82		46,73 %
	...
	1			Bikes			2013        4				12					d�cembre		$3,642,514.68	$3,010,755.29       $631,759.39		20,98 %
	2			Components		2012        4				12					d�cembre		$183,231.42		NULL				NULL			NULL
	2			Components		2013        1				1					janvier			$164,709.85		$183,231.42			($18,521.57)	-10,11 %
	...
*/

	WITH cte 
AS (
    SELECT 
        COALESCE(pc.[ProductCategoryID], 'N/A') AS [ID cat�gorie],
        COALESCE(pc.[Name], 'N/A') AS [Nom de la cat�gorie],
        DATEPART(YEAR, sod.[ModifiedDate]) AS Ann�e,
        DATEPART(QUARTER, sod.[ModifiedDate]) AS Trimestre,
        MONTH(sod.[ModifiedDate]) AS [Num�ro du mois],
        DATENAME(MONTH, sod.[ModifiedDate]) AS [Nom du mois des ventes],
        SUM(sod.[LineTotal]) AS [Somme des ventes]
    FROM 
        [Production].[Product] p 
    INNER JOIN 
        [Sales].[SalesOrderDetail] sod ON p.[ProductID] = sod.[ProductID]
    LEFT JOIN 
        [Production].[ProductSubcategory] psc ON p.[ProductSubcategoryID] = psc.[ProductSubcategoryID]
    LEFT JOIN 
        [Production].[ProductCategory] pc ON psc.[ProductCategoryID] = pc.[ProductCategoryID]
    WHERE 
        sod.[ModifiedDate] BETWEEN '2012-12-01' AND '2013-12-31'
    GROUP BY 
        COALESCE(pc.[ProductCategoryID], 'N/A'), 
        COALESCE(pc.[Name], 'N/A'),
        DATEPART(YEAR, sod.[ModifiedDate]),
        DATEPART(QUARTER, sod.[ModifiedDate]),
        MONTH(sod.[ModifiedDate]),
        DATENAME(MONTH, sod.[ModifiedDate])
)
SELECT 
    [ID cat�gorie],
    [Nom de la cat�gorie],
    Ann�e,
    Trimestre,
    [Num�ro du mois],
    [Nom du mois des ventes],
    FORMAT([Somme des ventes], 'C', 'en-US') AS [Somme des ventes],
    FORMAT(LAG([Somme des ventes], 1) OVER (partition by [ID cat�gorie] order by Ann�e, [Num�ro du mois]), 'C', 'en-US') AS [Ventes Mois Dernier],
    FORMAT([Somme des ventes] - LAG([Somme des ventes], 1) OVER (partition by [ID cat�gorie] order by Ann�e, [Num�ro du mois]), 'C', 'en-US') AS [Net Change],
	format(round(([Somme des ventes] - LAG([Somme des ventes], 1) OVER (partition by [ID cat�gorie] order by Ann�e, [Num�ro du mois])) / LAG([Somme des ventes], 1) OVER (partition by [ID cat�gorie] order by Ann�e, [Num�ro du mois]),4),'p') as ' %change'
	

FROM 
    cte
ORDER BY 
    1,3,5


/***************** QUESTION 3 (3,25 points) *****************/
/*
	Votre employeur voudrait savoir qui parmi ses fournisseurs actifs et non privil�gi�s aupr�s desquels AdventureWorks a achet� 
	au moins 30 fois a tendance � r�duire ses prix. L'entreprise souhaite utiliser ces informations afin de leur accorder le statut
	de "fournisseur privil�gi�". On �met ici l'hypoth�se que les commandes aupr�s d'un fournisseur restent stables � travers le temps
	et sont donc toujours pour des produits/quantit�s similaires.

	En utilisant une CTE construisez une requ�te qui affichera la liste des fournisseurs pour lesquels le montant moyen (en utilisant 
	le sous-total) de leurs trois commandes les plus r�centes est inf�rieur au montant moyen qu�ils ont demand� � AdventureWorks 
	jusqu�� pr�sent.

	On voudra afficher :
		- L'identifiant du fournisseur
		- Le nom du fournisseur
		- Le montant moyen des toutes les commandes faites aupr�s du fournisseur
		- Le montant moyen des trois commandes les plus r�centes faites aupr�s du fournisseur
		- La diff�rence entre le montant moyen des trois commandes les plus r�centes faites aupr�s du fournisseur et le montant moyen des
			toutes les commandes faites aupr�s du fournisseur.

	Votre rapport doit contenir seulement ces cinq colonnes et �tre filtr� par la diminution relative aux co�ts d'acquisition, de fa�on 
	que la r�duction la plus importante soit en t�te de la liste. Tous les montants doivent �tre affich�s sous forme mon�taire.
*/


-- CTE pour mettre les dates des commancdes en ordre
with RankCTE AS (

select rank() over(partition by poh.[VendorID] order by poh.[ModifiedDate] desc) as 'classement',
poh.[VendorID],
poh.[SubTotal],
COUNT(*) OVER(PARTITION BY poh.[VendorID]) AS OrderCount

from [Purchasing].[PurchaseOrderHeader] poh)
 
,

-- CTE pour obtenir la moyenne des commandes les plus recentes
RecentAvgCTE AS (
    SELECT 
        r.[VendorID],
        AVG(r.[SubTotal]) AS Moyenne_3_comandes_recentes
    FROM 
        RankCTE r
    WHERE 
        r.classement <= 3
    GROUP BY 
        r.[VendorID]
)

select r.[VendorID] as 'ID du fournisseur',
	   v.[Name] as 'NomFournisseur',
	   avg(r.[SubTotal]) as 'Moyenne des Commandes',
	   ra.Moyenne_3_comandes_recentes as Moyenne_des_3_comandes_recentes,
	   ra.Moyenne_3_comandes_recentes - avg(r.[SubTotal]) Diff�rence

from RankCTE r

inner join [Purchasing].[Vendor] v on
v.[BusinessEntityID] = r.[VendorID]
inner join RecentAvgCTE ra on 
r.[VendorID] = ra.[VendorID]

where [PreferredVendorStatus] = 0 and [ActiveFlag] = 1 and r.OrderCount>=30  ----- statut preferr� et actif et 30 commandes minimum

group by  r.[VendorID], v.[Name],ra.Moyenne_3_comandes_recentes

having ra.Moyenne_3_comandes_recentes - avg(r.[SubTotal]) < 0   ---- 

order by Diff�rence


