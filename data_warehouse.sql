use tst

--GETTING COLLUMN NAMES
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AB_NYC_2019'

-- GET NULL VALUES
SELECT DISTINCT * FROM tstStage.AB_NYC_2019
	where id  IS NOT NULL
	OR name  IS NULL or name NOT LIKE ''
	OR host_id IS NOT NULL
	OR host_name IS NOT NULL or host_name NOT LIKE ''
	OR neighbourhood_group IS NOT NULL or neighbourhood_group NOT LIKE ''
	OR neighbourhood IS NOT NULL or neighbourhood NOT LIKE ''
	OR latitude IS NOT NULL
	OR longitude IS NOT NULL
	OR room_type IS NOT NULL or room_type NOT  LIKE ''
	OR price IS NOT NULL or price NOT LIKE ''
	OR minimum_nights IS NOT NULL or minimum_nights NOT LIKE ''
	OR calculated_host_listings_count IS NOT NULL
	OR availability_365 IS NOT NULL

-- DELETE POSSIBLE ROWS WHERE THERES NULL
DELETE FROM tstStage.AB_NYC_2019 where name is null or name like ''
DELETE FROM tstStage.AB_NYC_2019 where host_id is null
DELETE FROM tstStage.AB_NYC_2019 where host_name IS NULL OR host_name LIKE ''



-- DATAWHEREHOUSE CORE
CREATE TABLE tstCore.DM_Neighbourhood 
(
	Id int identity(1,1) primary key,
	Neighbourhood_group nvarchar(100) NOT NULL,
	Neighbourhood nvarchar(100) NOT NULL,
	Latitude float NOT NULL,
	Longitude float NOT NULL
)
insert into tstCore.DM_Neighbourhood(Neighbourhood_group, Neighbourhood, Latitude, Longitude)
SELECT DISTINCT neighbourhood_group, neighbourhood,  latitude, longitude FROM tstStage.AB_NYC_2019
 

CREATE TABLE tstCore.DM_Host
(
	Id int primary key,
	Name varchar(100) NOT NULL,
	Calculated_host_listings_count int NOT NULL
)
insert into tstCore.DM_Host(Id, Name, Calculated_host_listings_count)
SELECT DISTINCT host_id, host_name, calculated_host_listings_count FROM tstStage.AB_NYC_2019


CREATE TABLE tstCore.DM_Room
(
	Id int identity(1,1) primary key,
	Type nvarchar(100) NOT NULL,
	Price float NOT NULL,
	Minimum_nights varchar(10) NOT NULL,
	Availability_365 int NOT NULL
)
insert into tstCore.DM_Room (Type,Price,Minimum_nights,Availability_365)
SELECT DISTINCT room_type, price, minimum_nights, availability_365 FROM tstStage.AB_NYC_2019


CREATE TABLE tstCore.DM_Review
(
	Id int identity(1,1) primary key,
	Number_reviews int,
	Last_review date,
	Reviews_month varchar(20)
)
insert into tstCore.DM_Review(Number_reviews, Last_review, Reviews_month)
SELECT DISTINCT number_of_reviews, last_review, reviews_per_month FROM tstStage.AB_NYC_2019


CREATE TABLE tstCore.FC_Airbnb
(
	Id int primary key,
	Name varchar(600) NOT NULL,
	FK_Host int,
	FK_Room int,
	FK_Review int,
	FK_Neighbourhood int,

CONSTRAINT FK_Host FOREIGN KEY(FK_host) REFERENCES tstCore.DM_Host(Id),
CONSTRAINT FK_Room FOREIGN KEY(FK_room) REFERENCES tstCore.DM_Room(Id),
CONSTRAINT FK_Review FOREIGN KEY(FK_Review) REFERENCES tstCore.DM_Review(Id),
CONSTRAINT FK_Neighbourhood FOREIGN KEY(FK_Neighbourhood) REFERENCES tstCore.DM_Neighbourhood(Id)
)
insert into tstCore.FC_Airbnb(Id, Name, FK_Host, FK_Room, FK_Review, FK_Neighbourhood)
SELECT DISTINCT ab.id, ab.name, hst.Id, ro.Id, rev.Id, nei.Id FROM tstStage.AB_NYC_2019 ab
	JOIN tstCore.DM_Host hst
ON ab.host_id = hst.Id
	JOIN tstCore.DM_Room ro
ON ab.room_type = ro.Type
AND ab.price = ro.Price
AND ab.minimum_nights = ro.Minimum_nights
AND ab.availability_365 = ro.Availability_365
	JOIN tstCore.DM_neighbourhood nei
ON ab.neighbourhood_group = nei.Neighbourhood_group
AND ab.neighbourhood = nei.Neighbourhood
AND ab.latitude = nei.Latitude
AND ab.longitude = nei.Longitude
	JOIN tstCore.DM_Review rev
ON ab.number_of_reviews = rev.Number_reviews
AND ab.last_review = rev.Last_review
AND ab.reviews_per_month = rev.Reviews_month



-- CREATING A DATA MART
CREATE SCHEMA dtMarts
CREATE TABLE dtMarts.PricePerRoom
(
	Id int identity(1,1) primary key,
	Room_name varchar(200) NOT NULL,
	Price varchar(200) NOT NULL
)
INSERT INTO dtMarts.PricePerRoom
SELECT ab.Name, room.Price FROM tstCore.FC_Airbnb ab
	JOIN tstCore.DM_Room room
ON ab.FK_Room = room.Id
SELECT * FROM dtMarts.PricePerRoom