
if not exists (select * from sys.databases where name = 'TIA')
Begin Create database TIA
end
GO

Use TIA
GO

----------------CREATION TABLE DIMENSION DATE -----------------------------
IF OBJECT_ID('dim_date', 'U') IS NOT NULL 
  DROP TABLE dim_date;

create table [dim_date] (

date_id	int	identity(1,1)  CONSTRAINT PK_dim_date primary key,
[date]	datetime	not null,
jour	tinyint	not null,
mois	tinyint	not null,
trimestre	tinyint	not null ,
annee_civile	smallint	not null,
annee_fiscale	smallint	not null,
trimestre_fiscal	tinyint	not null,
plan_strategique	smallint	not null,

CONSTRAINT CK_jour_mois_valide CHECK (
    (mois IN (1, 3, 5, 7, 8, 10, 12) AND jour BETWEEN 1 AND 31) OR
    (mois IN (4, 6, 9, 11) AND jour BETWEEN 1 AND 30) OR
    (mois = 2 AND jour BETWEEN 1 AND 28) OR
    (mois = 2 AND jour BETWEEN 1 AND 29 AND ((annee_civile % 4 = 0 AND annee_civile % 100 <> 0) OR (annee_civile % 400 = 0)))),
CONSTRAINT CK_trimestre_valide CHECK (
        (trimestre BETWEEN 1 AND 4) AND 
        ((mois BETWEEN 1 AND 3 AND trimestre = 1) OR 
        (mois BETWEEN 4 AND 6 AND trimestre = 2) OR 
        (mois BETWEEN 7 AND 9 AND trimestre = 3) OR 
        (mois BETWEEN 10 AND 12 AND trimestre = 4))),
CONSTRAINT CK_annee_civile_valide CHECK (annee_civile >= annee_fiscale),
CONSTRAINT CK_annee_fiscale_valide CHECK (
        ((mois BETWEEN 6 AND 12 AND annee_fiscale = annee_civile) OR
        (mois BETWEEN 1 AND 5 AND annee_fiscale = annee_civile - 1))),
CONSTRAINT CK_trimestre_fiscal_valide CHECK 
        (trimestre_fiscal in (1,2,3,4) AND 
        (((mois BETWEEN 6 AND 8 AND trimestre_fiscal = 1) OR 
        (mois BETWEEN 9 AND 11 AND trimestre_fiscal = 2) OR 
        (mois IN (12, 1, 2) AND trimestre_fiscal = 3) OR 
        (mois BETWEEN 3 AND 5 AND trimestre_fiscal = 4))))

);
GO

  
------------------CREATION TABLE DIMENSION PRODUIT ----------------------------------------
----cette table est type 2 car ces attributs ( ex : nom du produit) peuvent changer--------

IF OBJECT_ID('dim_produit', 'U') IS NOT NULL 
  DROP TABLE dim_produit;

CREATE TABLE dim_produit(
    produit_No int identity(1,1) CONSTRAINT PK_dim_produit primary key,
	product_name nvarchar(50) not null,
	ProductNumber nvarchar(25) not null,
	Jours_Sur_Le_Marche int not null,
	Evaluation_Moyenne decimal(3,2),
	Margeproduit decimal(10,2) not null,
	Style_Produit nvarchar(11),
	EffectiveDate datetime not null,
	ExpirationDate datetime not null default ('9999-12-31'),
	CurrentStatus varchar(7) not null default ('Current'),
	constraint rating_entry check (Evaluation_Moyenne between 1 and 5),
	CONSTRAINT CK_Jours_Sur_Le_Marche CHECK (Jours_Sur_Le_Marche >= 0),
    CONSTRAINT CK_Evaluation_Moyenne CHECK (Evaluation_Moyenne BETWEEN 1 AND 5),
    CONSTRAINT CK_Style_Produit CHECK (Style_Produit IN ('Women', 'Men', 'Universal', 'Unavailable')),
	CONSTRAINT CK_DATE_TYPE2 check (EffectiveDate < ExpirationDate)                                            ---- a ajouter metadonees et index -------
);
GO

  
	

---------------------- CREATION TABLE SalesTerritory-------------------------------
----------------------AUSSI TYPE 2 (EX: LES ZONES GEOGRAPHIQUES PEUVENT CHANGER) -----------------------------------------

IF OBJECT_ID('dim_SalesTerritory ', 'U') IS NOT NULL  
  DROP TABLE dim_SalesTerritory ;

CREATE TABLE dim_SalesTerritory(
    SalesTerritory_ID int identity(1,1) CONSTRAINT PK_dim_SalesTerritory primary key,
    Nom_Territoire NVARCHAR(50) NOT NULL,
    Code_Pays_Region_ISO NVARCHAR(3) NOT NULL,
    Zone_Geographique NVARCHAR(50) NOT NULL,
    Annee_Vente SMALLINT NOT NULL,
    Total_Ventes_Annee_Courante money NOT NULL,
    Total_Ventes_Annee_Precedente money NOT NULL ,
    Difference_Ventes money NOT NULL,
    Difference_Pourcentage DECIMAL(5, 2),
	EffectiveDate datetime not null,
	ExpirationDate datetime not null default ('9999-12-31'),
	CurrentStatus varchar(7) not null default ('Current'),
	CONSTRAINT CK_DATE2_TYPE2 check (EffectiveDate < ExpirationDate) 
	);
GO

  


--------------CREATION TABLE fait_Vente------------------------------------

IF OBJECT_ID('fait_vente', 'U') IS NOT NULL 
  DROP TABLE fait_vente;

Create table fait_vente(

Vente_ID int identity(1,1) CONSTRAINT PK_dim_fait_vente primary key,
Quantite_vendue int not null,
Valeur_Rabais money not null,
Benefice_Percu money not null,
produit_No int not null CONSTRAINT FK_dim_produit references dim_produit(produit_No),
SalesTerritory_ID int not null CONSTRAINT FK_dim_SalesTerritory references dim_SalesTerritory (SalesTerritory_ID),
date_id	int	not null CONSTRAINT FK_dim_date references dim_date(date_id)

);
GO

  


    




    



