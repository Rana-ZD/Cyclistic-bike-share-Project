/*
Combiner les 12 tables par mois de la base de données de Bike Trip en une seule table du 
01/01 au 31/12 de l'année 2021 en utilisant UNION function
*/

-- Convertir les columns pour avoir les mêmes type de data
Alter table BikeTripData2021_12
ADD Start_station_id_V02 Nvarchar(255),
End_station_id_V02 Nvarchar(255)

Update BikeTripData2021_12
Set Start_station_id_V02 = Convert(nvarchar(255),start_station_id),
End_station_id_V02 = Convert(nvarchar(255),end_station_id)

Alter Table BikeTripData2021_12
Drop column start_station_id, end_station_id

-- Utiliser la fonction Union pour joindre toutes les 12 tables en une seule table

select *
into BikeTripData2021.dbo.BikeTripData2021_VO2
from (
select * From BikeTripData2021_01
Union ALL
Select * From BikeTripData2021_02
Union ALL
Select * From BikeTripData2021_03
Union ALL
Select * From BikeTripData2021_04
Union ALL
Select * From BikeTripData2021_05
Union All
Select * From BikeTripData2021_06
Union All
Select * From BikeTripData2021_07
Union All
Select * From BikeTripData2021_08
Union All
Select * From BikeTripData2021_09
Union All
Select * From BikeTripData2021_10
Union All
Select * From BikeTripData2021_11
Union All
Select * From BikeTripData2021_12) as A

Select * 
from BikeTripData2021_VO2

-- Résultat, nous avons 5,595,063 lignes conforme en nombre des 12 précédentes tables addtionnées

/* 
Nous allons analyser et nettoyer chaque colonne séparément de la gauche à la droite
*/
----------#1. ride_id:
--Checker la taille de combinaison de la colonne ride_id et s'il n y a pas de doublant

Select Len(ride_id) AS LenRideID, count(*)
From BikeTripData2021_VO2
Group by Len(ride_id)

-- Il y'a 5593999 lignes qui contiennent 16 caractères, le reste est inférieur à 16 et sera nettoyer

--Checher les doublant

Select Count(distinct ride_id) 
From BikeTripData2021_VO2

-- Le nombre de ligne a baissé, il y a donc bien des doublant

----------#2. checker les variable de rideable_types colonne

select Distinct rideable_type, count(*)
from BikeTripData2021_VO2
group by rideable_type

-- La requête noue donne trois types de vélo alors que dans l'énoncé nous avons seulement deux, 'docked_bike' est l'ancienne dénomination de 'classic_bike', nous devons donc corriger cette table
Select 
	Distinct rideable_type,
	Case When rideable_type = 'docked_bike' then 'classic_bike'
	else rideable_type
	end
From BikeTripData2021_VO2

Update BikeTripData2021_VO2
SET rideable_type = Case When rideable_type = 'docked_bike' then 'classic_bike'
	else rideable_type
	end

----------#3. Checker started_at and ended_at colonnes.

Select started_at, ended_at, DATEDIFF(minute, started_at, ended_at)
From BikeTripData2021_VO2
Where DATEDIFF(minute, started_at, ended_at) > 1440 


Select started_at, ended_at, DATEDIFF(minute, started_at, ended_at)
From BikeTripData2021_VO2
and DATEDIFF(minute, started_at, ended_at) < 0

-- Il y a des trajets inférieurs à une minute et supérieur à une journée à supprimer
-- Il y a des trajets négatifs nous supposons que le début et la fin du trip ont été interverti et nous allons les corrigers

Update BikeTripData2021_VO2
Set started_at = Case when started_at > ended_at then ended_at
	Else started_at
	End,
ended_at = Case when ended_at < started_at then started_at
	Else ended_at
	End

----------#4. Checker the start/end station name/id colonne pour d'eventuelles incohérences de saisie

Select start_station_name, count(*)
from BikeTripData2021_VO2
group by start_station_name
ORder by start_station_name

Select count(distinct start_station_name),
	count(distinct end_station_name),
	count(distinct Start_station_id_V02),
	count(distinct End_station_id_V02)
from BikeTripData2021_VO2

Select distinct trim(start_station_name),
	 trim(end_station_name), Start_station_id_V02, End_station_id_V02
from BikeTripData2021_VO2

/*
Start and end station names doivent être rectifié en :
- Supprimant les espaces entre les mots.
- Revoir les lettres (Temp) si elles sont toujours d'actualité ou pas.
- Start and end station id columns contiennent beaucoup d'erreur et différentes orthographes
*/

---------- #5 checker le nombre de null dans les colonnes de start/end station_Name et ID
Select rideable_type, count(*) as NumOfRides
From BikeTripData2021_VO2
where start_station_name is null and Start_station_id_V02 is null
or end_station_name is null and End_station_id_V02 is null
Group by rideable_type

/* 
Classic_bikes/docked_bikes ne peuvent être bloqué et/ou débloqué qu'a une BikeStation 
et les electric_bike ont la possibilité d'être débloqué/bloqué à l'aide du système de bord et/ ou 
à proximité d'une station d'accueil; ainsi, les trajets ne doivent pas nécessairement commencer ou se terminer à une bikeStation.
De ce fait, nous allons procéder pour la partie cleanning à :
- Enlever les classic/docked bike qui n'ont pas de start ou end station name et non pas de start/end station ID.
- Changer the null station names to 'On Bike Lock' pour electric bikes
*/

----------#6. Checker les clonnes Start et end station Id

Select Start_station_id_V02, End_station_id_V02, count(*)
FROM BikeTripData2021_VO2
group by Start_station_id_V02, End_station_id_V02

---Diverses incohérences, colonne à supprimer

----------#7. Checker les ligne où latitude and longitude sont null

SELECT *
FROM BikeTripData2021_VO2
WHERE start_lat IS NULL OR
 start_lng IS NULL OR
 end_lat IS NULL OR
 end_lng IS NULL;

 -- On va supprimer les null afin que toutes les locations soient renseignées

 ---------- #8. Confirmer qu'il y a seulement de type de membre :

select Distinct member_casual
From BikeTripData2021_VO2

--Cette colonne est clean 