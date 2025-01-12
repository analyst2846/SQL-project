/*
 *		TECH 60701 -- Technologies de l'intelligence d'affaires
 *					HEC Montréal
 *		Travail Pratique 1
 *					Enseignant :
 *						J01 : Bogdan Negoita
 *		
 *		Instructions de remise :
 *			- Répondre à la question de modélisation dans un fichier Word (.docx)
 *			- Répondre aux questions SQL directement dans ce fichier .sql
 *			- Les deux fichiers (.docx et .sql) sont à remettre via ZoneCours dans l'outil de remise de travaux
 *			- Date de remise : voir les dates sur ZoneCours, aucun retard permis
 *
 *		Correction :
 *			- 9% de la note finale, /9
 *			- Une question qui génère une erreur (ne s'exécute pas) se verra attribuer automatiquement la note de 0.
 *				Par conséquent, testez votre code fréquemment !
 *			
 */

use AdventureWorks2022
go

/*
	Question #1 :

	Vous faites face au problème suivant : « AdventureWorks aimerait que vous développiez un schéma en étoile facilitant l’analyse du 
	processus de fabrication des produits en termes de quantité à fabriquer, quantité qui a échoué à l'inspection de la qualité et 
	quantité fabriquée et mise en inventaire. La compagnie veut que vous lui fournissiez une table de fait et des tables dimension 
	qui pourront détailler les jours de fabrication (par exemple, les dates de début et de fin du processus de fabrication), les produits 
	fabriqués, les raisons éventuelles pour la perte en cours de production (« scrap »). Il serait également intéressant de pouvoir analyser
	le processus de fabrication de manière à voir s'il y a plus de pertes le matin lorsque les machines sont froides et que les employé(e)s 
	ne sont pas encore suffisamment caféiné(e)s. Safety first ! (Note : même si dans AdventureWorks, les heures ne sont actuellement pas 
	enregistrées (elles apparaissent sous la forme de '00:00'), vos collègues vous assurent que ces données sont disponibles sur une autre
	source de données, donc le ou les modèles que vous produisiez doivent tenir compte du temps.)

	En plus des attributs que vous souhaitez inclure, les utilisateurs vous indiquent certains de leurs besoins spécifiques liés à l’analyse
	comme, par exemple :

	•	Pour la date, il faudra être facile à accéder i) au jour de la semaine, ii) la semaine de l’année et iii) le trimestre.
	•	Pour le produit, il faudra inclure son i) nom, ii) sous-catégorie, iii) catégorie , iv) gamme (productline). »

	a)	Quel est le « grain » (ou le niveau de granularité) de cette problématique ?
	b)	Développez le modèle conceptuel d’un schéma en étoile de cette problématique.
	c)	Développez le modèle logique d’un schéma en étoile de cette problématique.
	d)	Quelles dimensions peuvent être modélisées logiquement en tant que dimensions de type 2 ? Pourquoi ?
		
	Détaillez vos réponses dans un fichier Word (.docx). 
		
	Vous pouvez développer vos modèles à la main (tout en vous assurant qu'ils sont lisibles), prendre une photo et les inclure dans le document
	Word.
*/


/*
	Question #2 :

	Le directeur du service des ressources humaines chez AdventureWorks vous demande de lui fournir un rapport affichant le nombre de départements ayant
	le même nombre d'employés actifs à leur service. Il vous demande donc d’écrire une requête détaillant les informations suivantes :
		- Le nombre d’employés actuellement au service d'un département
		- Le nombre de départements avec exactement le même nombre d'employés
		- Un petit texte convivial détaillant chaque ligne de résultat, comme suit : « Il y a xxx département(s) avec yyy employé(s). »

	Le tout ordonné par nombre d’employés (ordre descendant).
*/

use AdventureWorks2022
go

SELECT 
    sub.EmployésActifs,
    COUNT(sub.DepartmentID) AS NbDepartements,
    CONCAT('Il y a ', COUNT(sub.DepartmentID), ' department(s) avec ', sub.EmployésActifs, ' employé(s).') AS TexteConvivial
FROM 
(
    SELECT 
        edh.DepartmentID,
        COUNT(hre.BusinessEntityID) AS EmployésActifs
    FROM HumanResources.Employee hre 
    INNER JOIN HumanResources.EmployeeDepartmentHistory edh
        ON hre.BusinessEntityID = edh.BusinessEntityID
    WHERE edh.EndDate IS NULL -- contrainte d'employé 'actif'
    GROUP BY edh.DepartmentID
) sub

GROUP BY sub.EmployésActifs
ORDER BY sub.EmployésActifs DESC;




/*
	Question #3 :

	Votre réputation chez AdventureWorks commence à grandir !! Comme faire du bon travail ne reste jamais impuni, vous recevez une autre tâche :)

	Impressionnée par votre travail jusqu'à maintenant, la directrice des ventes aimerait avoir un rapport sur les produits de l'entreprise. Plus
	précisément, pour chaque produit de l'entreprise qui s'est vendu plus de 100 fois, elle aimerait savoir combien de fois il s'est vendu (et non 
	pas combien d'unités ont été vendus), la moyenne de ces ventes (en format monnaie) et le modèle du produit, s’il y en a. De plus, elle souhaite
	que le titre du produit soit présenté dans un format particulier et que sa couleur soit affichée en français.
	
	Elle souhaite que le rapport soit trié par identifiant de produit dans l'ordre croissant. Votre rapport doit contenir seulement les colonnes
	suivantes avec les données dans le format qui apparaît :

	ProductID	|Description du produit				|Couleur	|Modèle du produit		|Nombre de fois que le produit a été vendu	|Moyenne des ventes
	...
	709			|Mountain Bike Socks, M (SO-B909-M)	|Blanc		|Mountain Bike Socks	|188										|$32.24
	711			|Sport-100 Helmet, Blue (HL-U509-B)	|Bleu		|Sport-100				|3090										|$53.53
	712			|AWC Logo Cap (CA-1098)				|Multi		|Cycling Cap			|3382										|$15.15
	...
*/

select DISTINCT([Color]) FROM [Production].[Product]

---- juste pour connaitre les différentes couleurs (resultats : Null, Black, Blue, Grey, Multi, Red, Silver, Silver/Black, White ,Yellow) 

select 
	p.[ProductID],
	CONCAT(p.[Name],' ','(',P.[ProductNumber],')') as 'Description du produit',
	CASE p.Color
        WHEN 'Black' THEN 'Noir'
        WHEN 'Blue' THEN 'Bleu'
        WHEN 'Grey' THEN 'Gris'
        WHEN 'Multi' THEN 'Multicolore'
        WHEN 'Red' THEN 'Rouge'
        WHEN 'Silver' THEN 'Argent'
        WHEN 'Silver/Black' THEN 'Argent/Noir'
        WHEN 'White' THEN 'Blanc'
        WHEN 'Yellow' THEN 'Jaune'
        ELSE 'Non spécifié'
    END AS Couleur,
	pm.[Name] as 'Modèle du produit',
	count(s.[SalesOrderID]) as 'Nombre de fois que le produit a été vendu',
	 FORMAT(avg((s.LineTotal)), 'C', 'en-us') as ' Moyenne des ventes'

from [Production].[Product] p
inner join [Sales].[SalesOrderDetail] s
on p.ProductID = s.ProductID
left join [Production].[ProductModel] pm
on p.[ProductModelID] = pm.[ProductModelID]

GROUP BY 
    p.[ProductID], 
    p.[Name], 
    p.[ProductNumber], 
    p.[Color],
	pm.[Name]
HAVING count(s.[SalesOrderID]) > 100
order by p.[ProductID]



/*
	Question #4 :

	Nous sommes vendredi en fin d'après-midi et la directrice des ventes a une dernière demande pour la semaine !! (C'est du moins ce que vous
	espérez...) 

	Essentiellement, elle aimerait avoir un rapport des produits vendus à rabais et quelques informations liées au mode de paiement. Plus
	particulièrement, les données suivantes :

		-le "ProductNumber" du produit vendu à prix réduit
		-le numéro de facture (identifié en tant que le "SalesOrderNumber")
		-le numéro de facture transformé en gardant les deux premiers caractères, suivis du "_" et terminé par le reste des chiffres
		-l'identifiant (le "ID") de rabais
		-la description de rabais
		-le pourcentage de rabais (en format %)
		-le type de rabais
		-un indicateur (Yes/No) indiquant si le produit a été payé par carte bancaire ou non.

	Elle souhaite que le rapport soit trié par le pourcentage du rabais dans l'ordre decroissant.
*/


SELECT 
    p.ProductNumber,
    soh.SalesOrderNumber,
    CONCAT(SUBSTRING(soh.SalesOrderNumber, 1, 2), '-', SUBSTRING(soh.SalesOrderNumber, 3, LEN(soh.SalesOrderNumber))) AS SalesOrderNumber_transformé,
    so.SpecialOfferID as ' ID du rabais',
    so.Description as ' Description rabais',
    FORMAT(so.DiscountPct, 'P0') AS PourcentageRabais,
    so.Type,
    CASE 
        WHEN soh.CreditCardID IS NULL THEN 'NON'
        ELSE 'OUI'
    END AS [Le produit a été payé par carte ?]
FROM 
    Production.Product p
INNER JOIN 
    Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
INNER JOIN 
    Sales.SpecialOffer so ON sod.SpecialOfferID = so.SpecialOfferID
INNER JOIN 
    Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID

WHERE so.DiscountPct > 0
Group by p.ProductNumber, soh.SalesOrderNumber, so.SpecialOfferID ,so.Description,so.DiscountPct,so.Type,soh.CreditCardID
Order by so.DiscountPct DESC

