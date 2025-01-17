
use AdventureWorks2022;
go




/***************** QUESTION 1 (2,5 points) *****************/
/* 
	AdventureWorks vous demande de rédiger une requête permettant de voir le total des ventes par catégorie 
	(s’il y en a…) entre décembre 2012 et décembre 2013, inclusivement. On a besoin d'afficher les informations
	suivantes:
		- Identifiant de la catégorie (N/A, si non disponible),
		- Nom de la catégorie (N/A, si non disponible),
		- Année des ventes,
		- Trimestre des ventes,
		- Numéro du mois des ventes,
		- Nom du mois des ventes (NOTE: peu importe que la valeur s'affiche en anglais ou en français...),
		- Somme des ventes (sous forme monétaire) de la catégorie pour le mois de l'année correspondants.
	
	Le tout devra être trié de façon ascendante par identificateur de catégorie, année et mois des ventes.
*/

use AdventureWorks2022;
go


SELECT 
    COALESCE(pc.[ProductCategoryID], 'N/A') AS "ID catégorie",
    COALESCE(pc.[Name], 'N/A') AS "Nom de la catégorie",
    DATEPART(YEAR, sod.[ModifiedDate]) AS Année,
    DATEPART(QUARTER, sod.[ModifiedDate]) AS Trimestre,
    MONTH(sod.[ModifiedDate]) AS "Numéro du mois",
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
	AdventureWorks vous demande maintenant de rédiger une requête permettant de voir également les ventes du mois 
	précédent pour chaque ligne des résultats de la requête rédigée pour répondre à la demande précédente.

	On a besoin d'ajouter les informations suivantes :
	- le total des ventes pour le mois précédant
	- la différence entre le total des ventes du mois courant et celui du mois précédant
	- le pourcentage de fluctuation des ventes par rapport au mois précédent

	Ne voulant pas perdre de temps à ajuster la requête précédente, vous décidez de l'exploiter dans le contexte
	d’une CTE vous permettant de répondre à la nouvelle demande.

	Extrait des résultats (remarquer le format d'affichage pour le pourcentage de fluctuation des ventes):

	CategoryID	CategoryName	SalesYear	SalesQuarter	SalesMonthNumber	SalesMonthName	TotalSales		TotalSalesLastMonth	NetChange		PercentageChange
	----------- --------------- ----------- --------------- -------------------	---------------	---------------	-------------------	---------------	-------------------
	1			Bikes			2012        4				12					décembre		$2,598,926.59	NULL				NULL			NULL
	1			Bikes			2013        1				1					janvier			$1,883,815.42	$2,598,926.59       ($715,111.17)	-27,52 %
	1			Bikes			2013        1				2					février			$1,961,526.99	$1,883,815.42       $77,711.57		4,13 %
	1			Bikes			2013        1				3					mars			$2,878,097.80	$1,961,526.99       $916,570.82		46,73 %
	...
	1			Bikes			2013        4				12					décembre		$3,642,514.68	$3,010,755.29       $631,759.39		20,98 %
	2			Components		2012        4				12					décembre		$183,231.42		NULL				NULL			NULL
	2			Components		2013        1				1					janvier			$164,709.85		$183,231.42			($18,521.57)	-10,11 %
	...
*/

	WITH cte 
AS (
    SELECT 
        COALESCE(pc.[ProductCategoryID], 'N/A') AS [ID catégorie],
        COALESCE(pc.[Name], 'N/A') AS [Nom de la catégorie],
        DATEPART(YEAR, sod.[ModifiedDate]) AS Année,
        DATEPART(QUARTER, sod.[ModifiedDate]) AS Trimestre,
        MONTH(sod.[ModifiedDate]) AS [Numéro du mois],
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
    [ID catégorie],
    [Nom de la catégorie],
    Année,
    Trimestre,
    [Numéro du mois],
    [Nom du mois des ventes],
    FORMAT([Somme des ventes], 'C', 'en-US') AS [Somme des ventes],
    FORMAT(LAG([Somme des ventes], 1) OVER (partition by [ID catégorie] order by Année, [Numéro du mois]), 'C', 'en-US') AS [Ventes Mois Dernier],
    FORMAT([Somme des ventes] - LAG([Somme des ventes], 1) OVER (partition by [ID catégorie] order by Année, [Numéro du mois]), 'C', 'en-US') AS [Net Change],
	format(round(([Somme des ventes] - LAG([Somme des ventes], 1) OVER (partition by [ID catégorie] order by Année, [Numéro du mois])) / LAG([Somme des ventes], 1) OVER (partition by [ID catégorie] order by Année, [Numéro du mois]),4),'p') as ' %change'
	

FROM 
    cte
ORDER BY 
    1,3,5


/***************** QUESTION 3 (3,25 points) *****************/
/*
	Votre employeur voudrait savoir qui parmi ses fournisseurs actifs et non privilégiés auprès desquels AdventureWorks a acheté 
	au moins 30 fois a tendance à réduire ses prix. L'entreprise souhaite utiliser ces informations afin de leur accorder le statut
	de "fournisseur privilégié". On émet ici l'hypothèse que les commandes auprès d'un fournisseur restent stables à travers le temps
	et sont donc toujours pour des produits/quantités similaires.

	En utilisant une CTE construisez une requête qui affichera la liste des fournisseurs pour lesquels le montant moyen (en utilisant 
	le sous-total) de leurs trois commandes les plus récentes est inférieur au montant moyen qu’ils ont demandé à AdventureWorks 
	jusqu’à présent.

	On voudra afficher :
		- L'identifiant du fournisseur
		- Le nom du fournisseur
		- Le montant moyen des toutes les commandes faites auprès du fournisseur
		- Le montant moyen des trois commandes les plus récentes faites auprès du fournisseur
		- La différence entre le montant moyen des trois commandes les plus récentes faites auprès du fournisseur et le montant moyen des
			toutes les commandes faites auprès du fournisseur.

	Votre rapport doit contenir seulement ces cinq colonnes et être filtré par la diminution relative aux coûts d'acquisition, de façon 
	que la réduction la plus importante soit en tête de la liste. Tous les montants doivent être affichés sous forme monétaire.
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
	   ra.Moyenne_3_comandes_recentes - avg(r.[SubTotal]) Différence

from RankCTE r

inner join [Purchasing].[Vendor] v on
v.[BusinessEntityID] = r.[VendorID]
inner join RecentAvgCTE ra on 
r.[VendorID] = ra.[VendorID]

where [PreferredVendorStatus] = 0 and [ActiveFlag] = 1 and r.OrderCount>=30  ----- statut preferré et actif et 30 commandes minimum

group by  r.[VendorID], v.[Name],ra.Moyenne_3_comandes_recentes

having ra.Moyenne_3_comandes_recentes - avg(r.[SubTotal]) < 0   ---- 

order by Différence


