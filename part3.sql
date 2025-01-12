/*
 *		TECH 60701 -- Technologies de l'intelligence d'affaires
 *					HEC Montréal
 *		Travail Pratique 3
 *					Enseignant :
 *						J01 : Bogdan Negoita
 *		
 *		Instructions de remise :
 *			- Répondre aux questions SQL directement dans ce fichier .sql
 *			- La remise du devoir doit être effectuée via ZoneCours dans l'outil de remise de travaux
 *			- Date de remise : voir les dates sur ZoneCours, aucun retard permis
 *
 *		Correction :
 *			- 9% de la note finale, /9
 *			- Une question qui génère une erreur (ne s'exécute pas) se verra attribuer automatiquement la note de 0.
 */
 




/*
	Question #1 (2,5 points) :
		Le directeur du service des ressources humaines chez AdventureWorks vous demande d’analyser les différentes
		informations concernant ses employés afin de déterminer s’il existe des iniquités potentielles entre des personnes
		de genres différents travaillant sous différents titres de poste chez AdventureWorks.
		
		Étant donné qu'il a besoin d'avoir le rapport tantôt pour les salariés hommes, tantôt pour les salariées femmes,
		vous décidez de construire une fonction (fn_GetEmpsByGender) à laquelle il pourra faire appel avec un paramètre 
		d'entrée différent en fonction de son besoin.

		Qu'il appelle la fonction pour les hommes ou pour les femmes, le résultat doit contenir les points de données suivants :

			- le titre de poste,
			- le sexe pour lequel le rapport est exécuté,
			- le nombre d'employé.es de ce sexe ayant le titre de poste
			- le pourcentage d'employés appartenant à ce sexe considérant le total des employés ayant le titre de poste,
			- le taux horaire moyen du salaire des employé.es appartenant à ce sexe dans le poste, en particulier.

		Il prend le temps de vous dire qu'il aimerait le rapport seulement pour les titres de poste comptant 3 employé.es et plus.
		De plus, les pourcentages et les valeurs monétaires doivent être correctement formatés.

		Le script que vous soumettrez pour cette question doit comprendre toutes les opérations nécessaires pour créer et recréer 
		la fonction à volonté sans avoir besoin d’effacer des objets manuellement et/ou de sélectionner une base de données en particulier.
		Comme on ne veut pas polluer AdventureWorks2022 avec cet objet, on le créera dans la base de données TIA.

		Vous devez ensuite fournir, en bas de votre script, quelques appels à votre fonction SQL afin de valider que la fonction
		retourne les informations auxquelles on s’attend en fonction des valeurs possibles des paramètres d'entrée utilisés dépendamment 
		du sexe des employé.es. 
*/


-- Step 1: ON CHECK SI LE DATABASE TIA EXISTE DEJA
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'TIA')
BEGIN
    CREATE DATABASE TIA;
END
GO

-- Step 2: utiliser TIA
USE TIA;
GO

-- Step 3: CHECK SI LA FONCTION EXISTE ( note :  i was thinking about using " if object_Id exist formulation but both return same result)
IF EXISTS (SELECT * FROM information_schema.routines
           WHERE routine_schema = 'dbo'
           AND routine_type = 'FUNCTION'
           AND routine_name = 'fn_GetEmpsByGender')
BEGIN
    DROP FUNCTION dbo.fn_GetEmpsByGender;
END
GO

-- Step 4: CREER LA FONCTION
CREATE FUNCTION dbo.fn_GetEmpsByGender (@aGender VARCHAR(1))
RETURNS TABLE
AS
RETURN (
    WITH cte AS (
        SELECT COUNT(BusinessEntityID) AS '#EmployeePerTitle',
               JobTitle
        FROM [AdventureWorks2022].[HumanResources].[Employee] he
		where  he.[CurrentFlag] = 1
        GROUP BY JobTitle
        
    )
    SELECT 
	       he.JobTitle,
           @aGender AS Gender,
           COUNT(he.BusinessEntityID) AS EmployeeCount,
           FORMAT(COUNT(he.BusinessEntityID) * 1.0 / cte.[#EmployeePerTitle], 'P2')AS FractionOfTitle,              
		   format(avg(eph.Rate) over(partition by he.JobTitle,he.[Gender]) ,'c','en-us') as 'PayRate'
    FROM [AdventureWorks2022].[HumanResources].[Employee] he
    INNER JOIN cte
    ON he.JobTitle = cte.JobTitle
	inner join [AdventureWorks2022].[HumanResources].[EmployeePayHistory] eph
	on he.[BusinessEntityID] = eph.[BusinessEntityID]
	WHERE he.[Gender] = @aGender and  eph.[RateChangeDate] = (
            SELECT MAX(eph2.[RateChangeDate])
            FROM [AdventureWorks2022].[HumanResources].[EmployeePayHistory] eph2
            WHERE eph2.[BusinessEntityID] = he.[BusinessEntityID]
        )
    GROUP BY he.JobTitle, cte.[#EmployeePerTitle],eph.Rate,he.[Gender]
);
GO

-- Step 5: Select from the function fn_GetEmpsByGender with 'M' as the parameter
SELECT * FROM dbo.fn_GetEmpsByGender('M')
where  EmployeeCount >= 3 
order by 1;

----test pour femme
SELECT * FROM dbo.fn_GetEmpsByGender('F')
where  EmployeeCount >= 3
order by 1;


/*
	Question #2 (3,25 points) :
		AdventureWorks aimerait connaître la performance de ses commis de vente (identifié(e)s dans la base de données avec des titres de poste
		de « Sales Representative »). Malheureusement, les données dans la table Sales.SalesPerson ne sont pas à jour : les attributs SalesYTD 
		et SalesLastYear ne fournissent pas les bonnes informations et surtout, ne permettent pas de connaître la performance passée des commis
		de vente. On aimerait donc permettre de comparer la performance des commis de vente d’une année sur l’autre à l’aide d’une fonction.

		Vous devez créer une fonction fn_GetSalesData qui prend en paramètre une valeur @aYear (on suppose qu’on va passer une année pour laquelle
		on a fait des ventes, notamment 2011/12/13/14). La fonction doit retourner, pour chaque commis de vente, l’information suivante :

			- L’identifiant du commis de vente
			- Son prénom
			- Son nom de famille
			- La somme des sous-totaux (en format monnaie) des ventes réalisées pour l’année passée en paramètre à la fonction
			- Le rang basé sur les sous-totaux des ventes réalisées pour l’année passée en paramètre (1 correspondant au meilleur vendeur)
			- La somme des sous-totaux (en format monnaie) des ventes réalisées pour l’année précédant celle passée en paramètre; affichez 'N/A' s'il n'y a
				pas des ventes réalisées pour l’année précédant celle passée en paramètre
			- Le rang basé sur les sous-totaux des ventes réalisées pour l’année précédant celle passée en paramètre (1 correspondant au meilleur vendeur);
				affichez 'N/A' s'il n'y a pas des ventes réalisées pour l’année précédant celle passée en paramètre
			- Une indication pour savoir si le rang entre les deux années est meilleur ('+'), pire ('-'), ou égal ('='). Si on ne dispose pas de 
				données sur les ventes pour un commis pour l’année passée en paramètre ou celle la précédant, on affichera alors 'N/A' pour cette valeur.

		Par exemple, la sortie partielle pour 2012, pourrait ressembler à ce qui suit...

		BusinessEntityID	FirstName	LastName	TotalSales		TotalSalesRank	PreviousYearSales	PreviousYearSalesRank	RankDiff
		277					Jillian		Carson		$4,317,306.57	1				$1,311,627.29		2						+
		...
		289					Jae			Pak			$3,014,278.05	4				N/A					N/A						N/A
		279					Tsvi		Reiter		$2,674,436.35	5				$1,521,289.19		1						-
		...

		Le script que vous soumettrez pour cette question doit comprendre toutes les opérations nécessaires pour créer et recréer la fonction à volonté
		sans avoir besoin d’effacer des objets manuellement et/ou de sélectionner une base de données en particulier. Comme on ne veut pas polluer
		AdventureWorks2022 avec cet objet, on le créera dans la base de données TIA.

		Vous devez ensuite fournir, en bas de votre script, quelques appels à votre fonction SQL afin de valider qu’elle retourne les informations
		auxquelles on s’attend en fonction des valeurs possibles des paramètres utilisés. Si vous utiliserez une clause SELECT assurez-vous de trier les
		resultats selon le rang des ventes pour l’année passée en paramètre.
*/
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'TIA')
BEGIN
    CREATE DATABASE TIA;
END
GO

-- Step 2: UTILISER tia
USE TIA;
GO
--- check si fonction existe ou non 

IF EXISTS (SELECT * FROM information_schema.routines
           WHERE routine_schema = 'dbo'
           AND routine_type = 'FUNCTION'
           AND routine_name = 'fn_GetSalesData')
BEGIN
    DROP FUNCTION dbo.fn_GetSalesData;
END
GO

CREATE FUNCTION dbo.fn_GetSalesData (@aYear smallint)
RETURNS TABLE
AS
RETURN (

----cte pour la date precedente
WITH cte AS (

SELECT sp.[BusinessEntityID] as 'BusinessEntityID',
sum(soh.[SubTotal]) as 'PreviousYearSales',
coalesce(RANK() OVER ( ORDER BY sum(soh.[SubTotal])DESC),'N/A') AS 'PreviousYearSalesRank'

from [AdventureWorks2022].[Sales].[SalesPerson] sp
inner join [AdventureWorks2022].[Sales].[SalesOrderHeader] soh
on soh.[SalesPersonID] = sp.[BusinessEntityID]
inner join [adventureworks2022].[humanresources].[employee] hre 
on  hre.businessentityid =soh.salespersonid

where hre.jobtitle = 'Sales Representative'  AND datepart(year,soh.[OrderDate]) =  @aYear -1

group by sp.[BusinessEntityID])

select sp.[BusinessEntityID] as 'BusinessEntityID',
pp.[FirstName] as 'FirstName',
pp.[LastName]  as 'LastName',
FORMAT(sum(soh.[SubTotal]),'C','EN-US') as 'TotalSales',
RANK() OVER ( ORDER BY sum(soh.[SubTotal] )DESC) AS 'TotalSalesRank',
coalesce(FORMAT(cte.PreviousYearSales,'C','EN-US'),'N/A') as 'PreviousYearSales',
coalesce(cast(cte.PreviousYearSalesRank AS VARCHAR), 'N/A') AS 'PreviousYearSalesRank',
case 
	when  RANK() OVER ( ORDER BY sum(soh.[SubTotal] )DESC) < cte.PreviousYearSalesRank then '+'
	when RANK() OVER ( ORDER BY sum(soh.[SubTotal] )DESC)> cte.PreviousYearSalesRank then '-'
	when RANK() OVER ( ORDER BY sum(soh.[SubTotal] )DESC) = cte.PreviousYearSalesRank then '='
	else 'N/A'
end as RankDiff


from [AdventureWorks2022].[Sales].[SalesPerson] sp
inner join [AdventureWorks2022].[Sales].[SalesOrderHeader] soh
on soh.[SalesPersonID] = sp.[BusinessEntityID]
inner join [AdventureWorks2022].[Person].[Person] pp
on pp.[BusinessEntityID] = sp.[BusinessEntityID]
inner join [adventureworks2022].[humanresources].[employee] hre 
on  hre.businessentityid =soh.salespersonid
left join cte
on cte.[BusinessEntityID] = sp.[BusinessEntityID]

where datepart(year,soh.[OrderDate]) = @aYear and  hre.jobtitle = 'Sales Representative'

group by sp.[BusinessEntityID],pp.[FirstName],pp.[LastName],cte.PreviousYearSales,cte.PreviousYearSalesRank

  );
go

---on teste la fonction pour 2011,2012,2013,2014

SELECT * FROM dbo.fn_GetSalesData(2011)
order by TotalSalesRank 

SELECT * FROM dbo.fn_GetSalesData(2012)
order by TotalSalesRank 

SELECT * FROM dbo.fn_GetSalesData(2013)
order by TotalSalesRank 

SELECT * FROM dbo.fn_GetSalesData(2014)
order by TotalSalesRank 




/*
	Question #3 (3,25 points) : 
		Comme vous avez fait un excellent travail sur le rapport analysant la performance de ses vendeurs, depuis plusieurs jours, AdventureWorks ne 
		cesse de vous demander de générer des rapports sur les achats faites par la compagnie. À chaque fois, ce sont les mêmes données qui sont 
		demandées mais les paramètres eux, changent. Vous décidez donc de mettre à profit vos connaissances pour vous faciliter la vie tout en montrant
		à la direction que vous êtes plein(e) d'initiative et vous méritez une promotion et un bonus de salaire !

		Vous devez créer, dans la base de données TIA, une fonction SQL fn_GetPurchases permettant d'afficher les informations suivantes :

			- La cote de crédit (valeur numérique) du fournisseur actif. Étiquette de la colonne : 'Cote de crédit'
			- La cote de crédit (valeur chaîne de caractères) du fournisseur actif. Étiquette de la colonne : 'Description- Cote de crédit'
				(Ici, nous voulons avoir les traductions françaises des descriptions des différentes cotes de crédit. Par exemple, 'Average' devra 
				s'afficher en tant que 'Moyenne', etc.)
			- Le nom du fournisseur actif. Étiquette de la colonne : 'Nom du fournisseur'.
			- Le montant total des achats (en utilisant le sous-total, en format monnaie) faites à partir du fournisseur actif. Étiquette de la colonne : 
				'Montant total'
			- Le rang (ascendant) basé sur le montant total des achats (en utilisant le sous-total) faites à partir du fournisseur actif. Étiquette de 
				la colonne : 'Rang' (Si nous analysons toutes les cotes de crédit, le classement des fournisseurs actifs se fait par cote de crédit.)
			- Le quartile (ascendant) basé sur le montant total des achats (en utilisant le sous-total) faites à partir du fournisseur actif. Étiquette de 
				la colonne : 'Quartile' (Si nous analysons toutes les cotes de crédit, le classement des fournisseurs actifs se fait par cote de crédit.)

		Il faudra qu'on soit capable d’interroger cet objet pour lui demander :

			- Les données pour une cote de crédit, en passant en paramètre la valeur numérique de la cote de crédit qui nous intéresse
				(Par example, selon les métadonnées contenues dans AdventureWorks, les valeurs possibles vont de 1 à 5, inclusivement.)
			- Les données pour toutes les cotes de crédit, si nous passons une cote de crédit inexistante (cette information est à vérifier
				dynamiquement !)

		Les données retournées sont donc groupées par cote de crédit (numérique), cote de crédit (chaîne de caractères) et nom du fournisseur actif.

		Par exemple, la sortie partielle pour cote de crédit 1, pourrait ressembler à ce qui suit...

		Cote de crédit	Description- Cote de crédit	Nom du fournisseur					Montant total	Rang	Quartile
		1				Supérieure					Superior Bicycles					$4,555,897.50	1		1
		1				Supérieure					Professional Athletic Consultants	$3,058,774.95	2		1
		...
		1				Supérieure					Lindell								$4,898.25		65		4
		1				Supérieure					G & K Bicycle Corp.					$4,578.32		66		4

		Le script que vous soumettrez pour cette partie doit comprendre toutes les opérations nécessaires pour créer et recréer la fonction à volonté
		sans avoir besoin d’effacer des objets manuellement et/ou de sélectionner une base de données en particulier. Comme on ne veut pas polluer
		AdventureWorks2022 avec cet objet, on le créera dans la base de données TIA.

		Vous devez ensuite fournir, en bas de votre script, quelques appels à votre fonction SQL afin de valider qu’elle retourne les informations
		auxquelles on s’attend en fonction des valeurs possibles des paramètres utilisés. Si vous utiliserez une clause SELECT assurez-vous de trier les
		resultats selon la cote de crédit et le rang du fournisseur actif, les deux de manière ascendante.
*/

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'TIA')
BEGIN
    CREATE DATABASE TIA;
END
GO

-- Step 2: Utiliser TIA
USE TIA;
GO

-- Step 3: dROP LA FONCTION SI ELLE EXISTE DEJA
IF EXISTS (SELECT * FROM information_schema.routines
           WHERE routine_schema = 'dbo'
           AND routine_type = 'FUNCTION'
           AND routine_name = 'fn_GetPurchases')
BEGIN
    DROP FUNCTION dbo.fn_GetPurchases;
END
GO


CREATE FUNCTION dbo.fn_GetPurchases (@aCreditScore tinyint)
RETURNS TABLE
AS
RETURN (

SELECT pv.[CreditRating] AS 'Cote de crédit',
      CASE	
        WHEN pv. CreditRating = 1 THEN 'Supérieure'
        WHEN pv. CreditRating = 2 THEN 'Très bien'
        WHEN pv. CreditRating = 3 THEN 'Bien'
        WHEN pv. CreditRating = 4 THEN 'Moyenne'
        WHEN pv. CreditRating = 5 THEN 'Mauvais'
     ELSE 'Inexsistante' 
     END AS 'Description - Cote de Crédit',
pv.[Name] as 'Nom du fournisseur',
format(sum(poh.[SubTotal]),'c','en-us') as 'Montant total',
rank() over( partition by pv.[CreditRating] order by sum(poh.[SubTotal]) DESC ) AS  'Rang',
NTILE(4) over( partition by pv.[CreditRating] order by sum(poh.[SubTotal]) DESC) AS 'Quartile'



from 

[AdventureWorks2022].[Purchasing].[Vendor] pv
inner join [AdventureWorks2022].[Purchasing].[PurchaseOrderHeader] poh
on pv.[BusinessEntityID] = poh.[VendorID] 

where pv.[ActiveFlag] = 1 

group by pv.[CreditRating],pv.[Name]

HAVING 
 pv.CreditRating = @aCreditScore OR @aCreditScore NOT BETWEEN 1 AND 5);

go

---- test de la fonction ( PAR EXEMPLE 1 comme parametres faisable, on peut faire pour 2,3,4,5 aussi)

select * from fn_GetPurchases(1) 
order by 1,6

---- POUR VALEUR INEXITANTE ( exemple 8)

select * from fn_GetPurchases(8) 
order by 1,6



