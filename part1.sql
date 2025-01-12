/*
 *		TECH 60701 -- Technologies de l'intelligence d'affaires
 *					HEC Montr�al
 *		Travail Pratique 1
 *					Enseignant :
 *						J01 : Bogdan Negoita
 *		
 *		Instructions de remise :
 *			- R�pondre � la question de mod�lisation dans un fichier Word (.docx)
 *			- R�pondre aux questions SQL directement dans ce fichier .sql
 *			- Les deux fichiers (.docx et .sql) sont � remettre via ZoneCours dans l'outil de remise de travaux
 *			- Date de remise : voir les dates sur ZoneCours, aucun retard permis
 *
 *		Correction :
 *			- 9% de la note finale, /9
 *			- Une question qui g�n�re une erreur (ne s'ex�cute pas) se verra attribuer automatiquement la note de 0.
 *				Par cons�quent, testez votre code fr�quemment !
 *			
 */

use AdventureWorks2022
go

/*
	Question #1 :

	Vous faites face au probl�me suivant : � AdventureWorks aimerait que vous d�veloppiez un sch�ma en �toile facilitant l�analyse du 
	processus de fabrication des produits en termes de quantit� � fabriquer, quantit� qui a �chou� � l'inspection de la qualit� et 
	quantit� fabriqu�e et mise en inventaire. La compagnie veut que vous lui fournissiez une table de fait et des tables dimension 
	qui pourront d�tailler les jours de fabrication (par exemple, les dates de d�but et de fin du processus de fabrication), les produits 
	fabriqu�s, les raisons �ventuelles pour la perte en cours de production (� scrap �). Il serait �galement int�ressant de pouvoir analyser
	le processus de fabrication de mani�re � voir s'il y a plus de pertes le matin lorsque les machines sont froides et que les employ�(e)s 
	ne sont pas encore suffisamment caf�in�(e)s. Safety first ! (Note : m�me si dans AdventureWorks, les heures ne sont actuellement pas 
	enregistr�es (elles apparaissent sous la forme de '00:00'), vos coll�gues vous assurent que ces donn�es sont disponibles sur une autre
	source de donn�es, donc le ou les mod�les que vous produisiez doivent tenir compte du temps.)

	En plus des attributs que vous souhaitez inclure, les utilisateurs vous indiquent certains de leurs besoins sp�cifiques li�s � l�analyse
	comme, par exemple :

	�	Pour la date, il faudra �tre facile � acc�der i) au jour de la semaine, ii) la semaine de l�ann�e et iii) le trimestre.
	�	Pour le produit, il faudra inclure son i) nom, ii) sous-cat�gorie, iii) cat�gorie , iv) gamme (productline). �

	a)	Quel est le � grain � (ou le niveau de granularit�) de cette probl�matique ?
	b)	D�veloppez le mod�le conceptuel d�un sch�ma en �toile de cette probl�matique.
	c)	D�veloppez le mod�le logique d�un sch�ma en �toile de cette probl�matique.
	d)	Quelles dimensions peuvent �tre mod�lis�es logiquement en tant que dimensions de type 2 ? Pourquoi ?
		
	D�taillez vos r�ponses dans un fichier Word (.docx). 
		
	Vous pouvez d�velopper vos mod�les � la main (tout en vous assurant qu'ils sont lisibles), prendre une photo et les inclure dans le document
	Word.
*/


/*
	Question #2 :

	Le directeur du service des ressources humaines chez AdventureWorks vous demande de lui fournir un rapport affichant le nombre de d�partements ayant
	le m�me nombre d'employ�s actifs � leur service. Il vous demande donc d��crire une requ�te d�taillant les informations suivantes :
		- Le nombre d�employ�s actuellement au service d'un d�partement
		- Le nombre de d�partements avec exactement le m�me nombre d'employ�s
		- Un petit texte convivial d�taillant chaque ligne de r�sultat, comme suit : � Il y a xxx d�partement(s) avec yyy employ�(s). �

	Le tout ordonn� par nombre d�employ�s (ordre descendant).
*/

use AdventureWorks2022
go

SELECT 
    sub.Employ�sActifs,
    COUNT(sub.DepartmentID) AS NbDepartements,
    CONCAT('Il y a ', COUNT(sub.DepartmentID), ' department(s) avec ', sub.Employ�sActifs, ' employ�(s).') AS TexteConvivial
FROM 
(
    SELECT 
        edh.DepartmentID,
        COUNT(hre.BusinessEntityID) AS Employ�sActifs
    FROM HumanResources.Employee hre 
    INNER JOIN HumanResources.EmployeeDepartmentHistory edh
        ON hre.BusinessEntityID = edh.BusinessEntityID
    WHERE edh.EndDate IS NULL -- contrainte d'employ� 'actif'
    GROUP BY edh.DepartmentID
) sub

GROUP BY sub.Employ�sActifs
ORDER BY sub.Employ�sActifs DESC;




/*
	Question #3 :

	Votre r�putation chez AdventureWorks commence � grandir !! Comme faire du bon travail ne reste jamais impuni, vous recevez une autre t�che :)

	Impressionn�e par votre travail jusqu'� maintenant, la directrice des ventes aimerait avoir un rapport sur les produits de l'entreprise. Plus
	pr�cis�ment, pour chaque produit de l'entreprise qui s'est vendu plus de 100 fois, elle aimerait savoir combien de fois il s'est vendu (et non 
	pas combien d'unit�s ont �t� vendus), la moyenne de ces ventes (en format monnaie) et le mod�le du produit, s�il y en a. De plus, elle souhaite
	que le titre du produit soit pr�sent� dans un format particulier et que sa couleur soit affich�e en fran�ais.
	
	Elle souhaite que le rapport soit tri� par identifiant de produit dans l'ordre croissant. Votre rapport doit contenir seulement les colonnes
	suivantes avec les donn�es dans le format qui appara�t :

	ProductID	|Description du produit				|Couleur	|Mod�le du produit		|Nombre de fois que le produit a �t� vendu	|Moyenne des ventes
	...
	709			|Mountain Bike Socks, M (SO-B909-M)	|Blanc		|Mountain Bike Socks	|188										|$32.24
	711			|Sport-100 Helmet, Blue (HL-U509-B)	|Bleu		|Sport-100				|3090										|$53.53
	712			|AWC Logo Cap (CA-1098)				|Multi		|Cycling Cap			|3382										|$15.15
	...
*/

select DISTINCT([Color]) FROM [Production].[Product]

---- juste pour connaitre les diff�rentes couleurs (resultats : Null, Black, Blue, Grey, Multi, Red, Silver, Silver/Black, White ,Yellow) 

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
        ELSE 'Non sp�cifi�'
    END AS Couleur,
	pm.[Name] as 'Mod�le du produit',
	count(s.[SalesOrderID]) as 'Nombre de fois que le produit a �t� vendu',
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

	Nous sommes vendredi en fin d'apr�s-midi et la directrice des ventes a une derni�re demande pour la semaine !! (C'est du moins ce que vous
	esp�rez...) 

	Essentiellement, elle aimerait avoir un rapport des produits vendus � rabais et quelques informations li�es au mode de paiement. Plus
	particuli�rement, les donn�es suivantes :

		-le "ProductNumber" du produit vendu � prix r�duit
		-le num�ro de facture (identifi� en tant que le "SalesOrderNumber")
		-le num�ro de facture transform� en gardant les deux premiers caract�res, suivis du "_" et termin� par le reste des chiffres
		-l'identifiant (le "ID") de rabais
		-la description de rabais
		-le pourcentage de rabais (en format %)
		-le type de rabais
		-un indicateur (Yes/No) indiquant si le produit a �t� pay� par carte bancaire ou non.

	Elle souhaite que le rapport soit tri� par le pourcentage du rabais dans l'ordre decroissant.
*/


SELECT 
    p.ProductNumber,
    soh.SalesOrderNumber,
    CONCAT(SUBSTRING(soh.SalesOrderNumber, 1, 2), '-', SUBSTRING(soh.SalesOrderNumber, 3, LEN(soh.SalesOrderNumber))) AS SalesOrderNumber_transform�,
    so.SpecialOfferID as ' ID du rabais',
    so.Description as ' Description rabais',
    FORMAT(so.DiscountPct, 'P0') AS PourcentageRabais,
    so.Type,
    CASE 
        WHEN soh.CreditCardID IS NULL THEN 'NON'
        ELSE 'OUI'
    END AS [Le produit a �t� pay� par carte ?]
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

