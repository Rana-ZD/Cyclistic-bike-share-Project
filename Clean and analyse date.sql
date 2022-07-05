--Maintenant on est prêt à nettoyer les données et les analyser

-----------------------------------------------------------------------------------------------------
----------------------------------------CLEAN THE DATA-----------------------------------------------
-----------------------------------------------------------------------------------------------------

----------#1. Isoler les lignes qui ne contiennent pas de valeur de station pour les classic_bike

Select ride_id as NullBadId
into NullStationName
From(
	Select ride_id, rideable_type, start_station_name,
	Start_station_id_V02, end_station_name, End_station_id_V02
	From BikeTripData2021_VO2
	Where rideable_type = 'classic_bike') AS T1
where start_station_name is null and Start_station_id_V02 is null
or end_station_name is null and End_station_id_V02 is null

Select *
from NullStationName

----------#2. Supprimes les lignes qui ne contiennent pas de valeur de station pour les classic_bike  
----------------et également les lignes de starting/ending latitude et longitude qui ne contiennent pas de valeur

Select *
Into NullStationNameCleaned
From (BikeTripData2021_VO2 AS T1
Left join NullStationName AS T2
	on T1.ride_id = T2.NullBadId)
where T2.NullBadId is null
and T1.start_lat is not null
and T1.start_lng is not null
and T1.end_lat is not null
and T1.end_lng is not null

Select *
From NullStationNameCleaned

----------#3. Replace null station names pour 'electric_bike' par 'automatic lock' 
------------- Ajout de plusieurs colonnes afin d'avoir les journées de location, le mois et la durée de location 

Select *
Into DraftCleanedBikeData_V01
From (Select 
	ride_id, rideable_type, 
	member_casual AS memberType,
	started_at, ended_at, 
	DATEDIFF(minute, started_at, ended_at) as RideLenght,
	DATENAME(WEEKDAY,started_at) as DayofWeek,
	DATENAME(MONTH,started_at) as Month,
	ISNULL(TRIM(REPLACE(start_station_name,'(Temp)','')), 'automatic lock') AS StartingStationNames,
	ISNULL(TRIM(REPLACE(end_station_name,'(Temp)','')), 'automatic lock') As EndStationNames,
	start_lat, start_lng, end_lat, end_lng
From NullStationNameCleaned) AS T3

select *
from DraftCleanedBikeData_V01

---------- #4 Enlever les lignes qui contiennent des chiffres dans le nom des stations 
----------------et dont la durée de location est inférieur à 5 et supérieur à 1440mn

select *
into CleanedBikeData2021
from (Select *
	From DraftCleanedBikeData_V01
	where ISNUMERIC(StartingStationNames) = 0
		and ISNUMERIC(EndStationNames) = 0
		and RideLenght > 5 and RideLenght < 1440) AS T4

---------- DATA IS CLEAN

----------------------------------------------------------------------------
------------------------------Analyze DATA---------------------------------
-----------------------------------------------------------------------------

Select *
from CleanedBikeData2021
---------- Type de location :

Select rideable_type, memberType, count(*) as NumberOfRides
from CleanedBikeData2021
Group by rideable_type, memberType
Order by NumberOfRides DESC

---------- Nombre de location par mois :

Select memberType, [Month], count(*)AS NumberRidesPerMonths
from CleanedBikeData2021
group by memberType, [Month]
Order by memberType, NumberRidesPerMonths DESC

---------- Nombre de location par semaine :

Select memberType, DayofWeek, count(*) AS NumberRidesPerDays
from CleanedBikeData2021
Group by memberType, DayofWeek
Order by memberType, NumberRidesPerDays DESC

---------- Nombre de location par heure :

Select memberType, DATENAME(hour,started_at) AS TimeOfDay, count(*) AS NumberRidesPerDays
from CleanedBikeData2021
Group by memberType, DATENAME(hour,started_at)
Order by NumberRidesPerDays DESC, TimeOfDay DESC

---------- Moyenne de la durée de location par jour de semaine :

Select memberType, 
	DayofWeek,
	AVG(RideLenght) AS AvgRideTimeMinutes
From CleanedBikeData2021
Group by memberType, DayofWeek
Order by memberType, AvgRideTimeMinutes DESC

---------- TOP 10 des Stations de démarrage pour les casuals members :

Select TOP 10 StartingStationNames, 
	Count(*) AS NumberOfRides,
	AVG(CAST(start_lat AS float)) AS start_lat,
	AVG(CAST(start_lng AS float)) AS start_lng
from CleanedBikeData2021
Where memberType = 'casual' and StartingStationNames <> 'automatic lock'
group by StartingStationNames
Order by NumberOfRides DESC

---------- TOP 10 Station de démarrage pour les annuels members :

Select TOP 10 StartingStationNames, 
	Count(*) AS NumberOfRides,
	AVG(CAST(start_lat AS float)) AS start_lat,
	AVG(CAST(start_lng AS float)) AS start_lng
from CleanedBikeData2021
Where memberType = 'member' and StartingStationNames <> 'automatic lock'
group by StartingStationNames
Order by NumberOfRides DESC

---------- TOP 10 des Stations de stop pour les casuals members :

Select TOP 10 EndStationNames, 
	Count(*) AS NumberOfRides,
	AVG(CAST(end_lat AS float)) AS end_lat,
	AVG(CAST(end_lng AS float)) AS end_lng
from CleanedBikeData2021
Where memberType = 'casual' and EndStationNames <> 'automatic lock'
group by EndStationNames
Order by NumberOfRides DESC

---------- TOP 10 Station de stop pour les annuels members :

Select TOP 10 EndStationNames, 
	Count(*) AS NumberOfRides,
	AVG(CAST(end_lat AS float)) AS end_lat,
	AVG(CAST(end_lng AS float)) AS end_lng
from CleanedBikeData2021
Where memberType = 'member' and EndStationNames <> 'automatic lock'
group by EndStationNames
Order by NumberOfRides DESC

---------- Maximum de la durée de location par type de membre:

Select memberType, DATEDIFF(hour, started_at, ended_at) AS RideLenghtHours, Count(*) AS NumberRide
From CleanedBikeData2021
Where DATEDIFF(hour, started_at, ended_at) >1 
Group by memberType, DATEDIFF(hour, started_at, ended_at)
Order by RideLenghtHours DESC, NumberRide DESC