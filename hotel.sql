PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS customer_request;
DROP TABLE IF EXISTS card_scan_leave;
DROP TABLE IF EXISTS card_scan_enter;
DROP TABLE IF EXISTS billing_account_member;
DROP TABLE IF EXISTS billing_account;
DROP TABLE IF EXISTS charge;
DROP TABLE IF EXISTS bill;
DROP TABLE IF EXISTS event_usage_slot;
DROP TABLE IF EXISTS event;
DROP TABLE IF EXISTS room_adjacency;
DROP TABLE IF EXISTS room_assignment;
DROP TABLE IF EXISTS advance_deposit;
DROP TABLE IF EXISTS reservation;
DROP TABLE IF EXISTS meeting_room_rate;
DROP TABLE IF EXISTS meeting_usage_slot;
DROP TABLE IF EXISTS meeting_room;
DROP TABLE IF EXISTS sleeping_room_rate;
DROP TABLE IF EXISTS sleeping_room;
DROP TABLE IF EXISTS customer_rating;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS organization;
DROP TABLE IF EXISTS room_bed;
DROP TABLE IF EXISTS bed_type;
DROP TABLE IF EXISTS room;
DROP TABLE IF EXISTS floor;
DROP TABLE IF EXISTS wing;
DROP TABLE IF EXISTS building;
DROP TABLE IF EXISTS hotel;

PRAGMA foreign_keys = ON;

CREATE TABLE hotel (
    hotelId     INTEGER PRIMARY KEY,
    hotelName   TEXT NOT NULL
);

CREATE TABLE building (
    buildingId    INTEGER PRIMARY KEY,
    buildingName  TEXT NOT NULL,
    hotelId       INTEGER NOT NULL,
    FOREIGN KEY (hotelId) REFERENCES hotel(hotelId)
);

CREATE TABLE wing (
    wingId               INTEGER PRIMARY KEY,
    buildingId           INTEGER NOT NULL,
    proxPool             REAL,
    proxGarage           REAL,
    hasHandicappedAccess INTEGER NOT NULL DEFAULT 0,
    isSmoking            INTEGER,
    FOREIGN KEY (buildingId) REFERENCES building(buildingId)
);

CREATE TABLE floor (
    wingId    INTEGER NOT NULL,
    floorNum  INTEGER NOT NULL,
    PRIMARY KEY (wingId, floorNum),
    FOREIGN KEY (wingId) REFERENCES wing(wingId)
);

CREATE TABLE room (
    roomNum            INTEGER PRIMARY KEY,
    wingId             INTEGER NOT NULL,
    floorNum           INTEGER NOT NULL,
    roomType           TEXT NOT NULL,
    numGuests          INTEGER,
    convertible        INTEGER NOT NULL DEFAULT 0,
    availabilityStatus TEXT NOT NULL,
    FOREIGN KEY (wingId, floorNum) REFERENCES floor(wingId, floorNum)
);

CREATE TABLE bed_type (
    bedTypeId    INTEGER PRIMARY KEY,
    bedTypeName  TEXT NOT NULL,
    capacity     INTEGER NOT NULL
);

CREATE TABLE room_bed (
    roomNum    INTEGER NOT NULL,
    bedTypeId  INTEGER NOT NULL,
    quantity   INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (roomNum, bedTypeId),
    FOREIGN KEY (roomNum)   REFERENCES room(roomNum),
    FOREIGN KEY (bedTypeId) REFERENCES bed_type(bedTypeId)
);

CREATE TABLE organization (
    organizationId   INTEGER PRIMARY KEY,
    organizationName TEXT NOT NULL
);

CREATE TABLE customer (
    customerId         INTEGER PRIMARY KEY,
    customerFirstName  TEXT NOT NULL,
    customerLastName   TEXT NOT NULL,
    email              TEXT,
    phone              TEXT,
    customerType       TEXT NOT NULL,
    organizationId     INTEGER,
    FOREIGN KEY (organizationId) REFERENCES organization(organizationId)
);

CREATE TABLE customer_rating (
    customerId            INTEGER PRIMARY KEY,
    relationshipRating    INTEGER,
    flexibilityRating     INTEGER,
    cooperativenessRating INTEGER,
    paymentPromptRating   INTEGER,
    FOREIGN KEY (customerId) REFERENCES customer(customerId)
);

CREATE TABLE sleeping_room (
    roomNum   INTEGER PRIMARY KEY,
    isSmoking INTEGER NOT NULL DEFAULT 1,
    FOREIGN KEY (roomNum) REFERENCES room(roomNum)
);

CREATE TABLE sleeping_room_rate (
    roomRateId    INTEGER PRIMARY KEY,
    roomNum       INTEGER NOT NULL,
    baseRoomRate  REAL NOT NULL,
    extensionFee  REAL DEFAULT 0,
    FOREIGN KEY (roomNum) REFERENCES sleeping_room(roomNum)
);

CREATE TABLE meeting_room (
    roomNum INTEGER PRIMARY KEY,
    hasToilet INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (roomNum) REFERENCES room(roomNum)
);

CREATE TABLE meeting_usage_slot (
    slotId         INTEGER PRIMARY KEY,
    slotTime       TEXT NOT NULL,
    isEating       INTEGER NOT NULL DEFAULT 0,
    rateMultiplier REAL NOT NULL DEFAULT 1.0,
    isSmoking      INTEGER
);

CREATE TABLE meeting_room_rate (
    roomRateId  INTEGER PRIMARY KEY,
    roomNum     INTEGER NOT NULL,
    slotId      INTEGER NOT NULL,
    baseRate    REAL NOT NULL,
    FOREIGN KEY (roomNum) REFERENCES meeting_room(roomNum),
    FOREIGN KEY (slotId)  REFERENCES meeting_usage_slot(slotId),
    UNIQUE (roomNum, slotId)
);

CREATE TABLE reservation (
    reservationId        INTEGER PRIMARY KEY,
    roomNum              INTEGER NOT NULL,
    customerId           INTEGER NOT NULL,
    numGuests            INTEGER,
    bedTypePref          TEXT,
    sizePref             TEXT,
    smokingPref          TEXT,
    location             TEXT,
    proxPoolPref         REAL,
    proxGaragePref       REAL,
    reservationDateTime  TEXT NOT NULL,
    checkInDateTime      TEXT,
    checkOutDateTime     TEXT,
    hasHandicappedAccess INTEGER NOT NULL DEFAULT 0,
    needsAdvanceDeposit  INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (customerId) REFERENCES customer(customerId)
    FOREIGN KEY (roomNum) REFERENCES room(roomNum)
);

CREATE TABLE advance_deposit (
    depositId     INTEGER PRIMARY KEY,
    reservationId INTEGER NOT NULL,
    amount        REAL NOT NULL,
    receivedDate  TEXT,
    FOREIGN KEY (reservationId) REFERENCES reservation(reservationId)
);

CREATE TABLE room_assignment (
    assignmentId         INTEGER PRIMARY KEY, 
    reservationId        INTEGER NOT NULL,
    roomNum              INTEGER NOT NULL,
    wingId               INTEGER,
    extensionApplied     INTEGER NOT NULL DEFAULT 0,
    extensionFeeApplied  REAL DEFAULT 0,
    timeFromReservedDate INTEGER,
    FOREIGN KEY (reservationId) REFERENCES reservation(reservationId),
    FOREIGN KEY (roomNum)         REFERENCES room(roomNum),
    FOREIGN KEY (wingId)          REFERENCES wing(wingId)
);

CREATE TABLE room_adjacency (
    roomNum1       INTEGER NOT NULL,
    roomNum2       INTEGER NOT NULL,
    connectionType TEXT NOT NULL,
    PRIMARY KEY (roomNum1, roomNum2),
    FOREIGN KEY (roomNum1) REFERENCES room(roomNum),
    FOREIGN KEY (roomNum2) REFERENCES room(roomNum)
);

CREATE TABLE event (
    eventId        INTEGER PRIMARY KEY,
    eventName      TEXT NOT NULL,
    customerId     INTEGER NOT NULL,
    attendance     INTEGER,
    startDateTime  TEXT NOT NULL,
    endDateTime    TEXT NOT NULL,
    roomNum        INTEGER,
    FOREIGN KEY (customerId) REFERENCES customer(customerId),
    FOREIGN KEY (roomNum)    REFERENCES meeting_room(roomNum)
);

CREATE TABLE event_usage_slot (
    usageId    INTEGER PRIMARY KEY,
    eventId    INTEGER NOT NULL,
    roomNum    INTEGER NOT NULL,
    slotId     INTEGER NOT NULL,
    roomRateId INTEGER NOT NULL,
    discount   REAL DEFAULT 0,
    finalRate  REAL NOT NULL,
    notes      TEXT,
    FOREIGN KEY (eventId)    REFERENCES event(eventId),
    FOREIGN KEY (roomNum)    REFERENCES meeting_room(roomNum),
    FOREIGN KEY (slotId)     REFERENCES meeting_usage_slot(slotId),
    FOREIGN KEY (roomRateId) REFERENCES meeting_room_rate(roomRateId)
);

CREATE TABLE bill (
    billId           INTEGER PRIMARY KEY,
    roomNum          INTEGER NOT NULL,
    customerId       INTEGER NOT NULL,
    amount           REAL NOT NULL,
    description      TEXT,
    checkOutDateTime TEXT NOT NULL,
    FOREIGN KEY (roomNum)    REFERENCES room(roomNum),
    FOREIGN KEY (customerId) REFERENCES customer(customerId)
);

CREATE TABLE charge (
    chargeId          INTEGER PRIMARY KEY,
    billId            INTEGER NOT NULL,
    roomNum           INTEGER NOT NULL,
    customerId        INTEGER,
    chargeDescription TEXT NOT NULL,
    chargeType        TEXT NOT NULL,
    FOREIGN KEY (billId)     REFERENCES bill(billId),
    FOREIGN KEY (roomNum)    REFERENCES room(roomNum),
    FOREIGN KEY (customerId) REFERENCES customer(customerId)
);

CREATE TABLE billing_account (
    billingAccountId  INTEGER PRIMARY KEY,
    primaryCustomerId INTEGER,
    accountName       TEXT NOT NULL,
    billingAddress    TEXT,
    customerType      TEXT,
    organizationId    INTEGER,
    FOREIGN KEY (primaryCustomerId) REFERENCES customer(customerId),
    FOREIGN KEY (organizationId)    REFERENCES organization(organizationId)
);

CREATE TABLE billing_account_member (
    billingAccountId INTEGER NOT NULL,
    billId           INTEGER NOT NULL,
    customerId       INTEGER NOT NULL,
    sharePercent     REAL NOT NULL,
    PRIMARY KEY (billingAccountId, billId, customerId),
    FOREIGN KEY (billingAccountId) REFERENCES billing_account(billingAccountId),
    FOREIGN KEY (billId)           REFERENCES bill(billId),
    FOREIGN KEY (customerId)       REFERENCES customer(customerId)
);

CREATE TABLE card_scan_enter (
    cardScanEnterId INTEGER PRIMARY KEY,
    customerId      INTEGER NOT NULL,
    roomNum         INTEGER NOT NULL,
    scanDateTime    TEXT NOT NULL,
    location        TEXT,
    FOREIGN KEY (customerId) REFERENCES customer(customerId),
    FOREIGN KEY (roomNum)    REFERENCES room(roomNum)
);

CREATE TABLE card_scan_leave (
    cardScanLeaveId INTEGER PRIMARY KEY,
    customerId      INTEGER NOT NULL,
    roomNum         INTEGER NOT NULL,
    scanDateTime    TEXT NOT NULL,
    location        TEXT,
    FOREIGN KEY (customerId) REFERENCES customer(customerId),
    FOREIGN KEY (roomNum)    REFERENCES room(roomNum)
);

CREATE TABLE customer_request (
    callId        INTEGER PRIMARY KEY,
    isAnswered    INTEGER NOT NULL DEFAULT 0,
    customerPhone TEXT NOT NULL,
    roomNum       INTEGER NOT NULL,
    isSmoking     INTEGER,
    FOREIGN KEY (roomNum)       REFERENCES room(roomNum)
);

BEGIN TRANSACTION;

INSERT INTO hotel (hotelId, hotelName) VALUES
(1, 'Grand Plaza Hotel');

INSERT INTO building (buildingId, buildingName, hotelId) VALUES
(1, 'Main Tower', 1),
(2, 'Conference Center', 1);

INSERT INTO wing (wingId, buildingId, proxPool, proxGarage, hasHandicappedAccess, isSmoking) VALUES
(1, 1, 0.2, 0.5, 1, 0),
(2, 1, 0.5, 0.2, 0, 1),
(3, 2, 0.1, 0.3, 1, NULL);

INSERT INTO floor (wingId, floorNum) VALUES
(1,1),(1,2),(1,3),
(2,1),(2,2),(2,3),
(3,1),(3,2),(3,3);

INSERT INTO room (roomNum, wingId, floorNum, roomType, numGuests, convertible, availabilityStatus) VALUES
(101,1,1,'sleeping',2,0,'available'),
(102,1,1,'sleeping',2,0,'available'),
(103,1,1,'sleeping',4,0,'occupied'),
(104,1,2,'sleeping',2,0,'available'),
(105,1,2,'sleeping',2,0,'available'),
(106,1,2,'sleeping',3,1,'available'),
(107,1,3,'sleeping',2,0,'available'),
(108,1,3,'sleeping',4,0,'occupied'),
(109,2,1,'sleeping',2,0,'available'),
(110,2,1,'sleeping',2,0,'available'),
(111,2,1,'sleeping',3,1,'available'),
(112,2,2,'sleeping',2,0,'available'),
(113,2,2,'sleeping',4,0,'occupied'),
(114,2,2,'sleeping',2,0,'available'),
(115,2,3,'sleeping',2,0,'available'),
(116,2,3,'sleeping',2,0,'available'),
(117,2,3,'sleeping',3,1,'available'),
(118,3,1,'sleeping',2,0,'available'),
(119,3,1,'sleeping',2,0,'available'),
(120,3,1,'sleeping',4,0,'occupied'),
(121,3,2,'sleeping',2,0,'available'),
(122,3,2,'sleeping',2,0,'available'),
(123,3,2,'sleeping',3,1,'available'),
(124,3,3,'sleeping',2,0,'available'),
(125,3,3,'sleeping',2,0,'available'),
(126,3,3,'sleeping',4,0,'occupied'),
(127,1,1,'sleeping',2,0,'available'),
(128,1,2,'sleeping',2,0,'available'),
(129,2,2,'sleeping',2,0,'available'),
(130,3,3,'sleeping',2,0,'available'),
(201,2,1,'meeting',0,0,'available'),
(202,2,1,'meeting',0,0,'available'),
(203,2,2,'meeting',0,0,'available'),
(204,2,2,'meeting',0,0,'available'),
(205,2,3,'meeting',0,0,'available');

INSERT INTO bed_type (bedTypeId, bedTypeName, capacity) VALUES
(1,'Single',1),
(2,'Double',2),
(3,'King',2),
(4,'Queen',2);

INSERT INTO room_bed (roomNum, bedTypeId, quantity) VALUES
(101,1,2),
(102,2,1),
(103,2,2),
(104,3,1),
(105,2,1),
(106,3,1),
(107,1,2),
(108,2,2),
(109,2,1),
(110,2,1),
(111,3,1),
(112,2,1),
(113,2,2),
(114,3,1),
(115,2,1),
(116,2,1),
(117,3,1),
(118,1,2),
(119,2,1),
(120,2,2),
(121,3,1),
(122,2,1),
(123,3,1),
(124,2,1),
(125,2,1),
(126,2,2),
(127,1,2),
(128,2,1),
(129,2,1),
(130,3,1);

INSERT INTO sleeping_room (roomNum, isSmoking) VALUES
(101,1),(102,1),(103,1),(104,1),(105,1),(106,1),(107,1),(108,1),
(109,0),(110,0),(111,0),(112,0),(113,0),(114,0),(115,0),(116,0),
(117,1),(118,0),(119,0),(120,0),(121,0),(122,0),(123,1),(124,1),
(125,1),(126,1),(127,1),(128,1),(129,1),(130,1);

INSERT INTO sleeping_room_rate (roomRateId, roomNum, baseRoomRate, extensionFee) VALUES
(1,101,150,30),
(2,102,150,30),
(3,103,180,40),
(4,104,160,35),
(5,105,160,35),
(6,106,170,40),
(7,107,150,30),
(8,108,180,40),
(9,109,140,25),
(10,110,140,25),
(11,111,165,35),
(12,112,150,30),
(13,113,180,40),
(14,114,160,35),
(15,115,150,30),
(16,116,150,30),
(17,117,170,40),
(18,118,140,25),
(19,119,140,25),
(20,120,180,40),
(21,121,160,35),
(22,122,150,30),
(23,123,170,40),
(24,124,150,30),
(25,125,150,30),
(26,126,180,40),
(27,127,150,30),
(28,128,160,35),
(29,129,150,30),
(30,130,160,35);

INSERT INTO meeting_room (roomNum, hasToilet) VALUES
(201, 1),(202, 0),(203, 1),(204, 0),(205, 0);

INSERT INTO meeting_usage_slot (slotId, slotTime, isEating, rateMultiplier, isSmoking) VALUES
(1,'09:00-11:00',0,1.0,0),
(2,'12:00-14:00',1,1.2,NULL),
(3,'15:00-17:00',0,1.0,0),
(4,'18:00-21:00',0,1.3,1);

INSERT INTO meeting_room_rate (roomRateId, roomNum, slotId, baseRate) VALUES
(31,201,1,300),
(32,201,2,450),
(33,201,3,320),
(34,201,4,500),
(35,202,1,280),
(36,202,2,430),
(37,202,3,300),
(38,202,4,480),
(39,203,1,350),
(40,203,2,520),
(41,203,3,360),
(42,203,4,550),
(43,204,1,260),
(44,204,2,420),
(45,204,3,290),
(46,204,4,470),
(47,205,1,400),
(48,205,2,580),
(49,205,3,420),
(50,205,4,600);

INSERT INTO organization (organizationId, organizationName) VALUES
(1,'Acme Corp'),
(2,'Globex Inc'),
(3,'Initech'),
(4,'Umbrella Co'),
(5,'Wayne Enterprises');

INSERT INTO customer (customerId, customerFirstName, customerLastName, email, phone, customerType, organizationId) VALUES
(1,'Alice','Ng','alice.ng@example.com','555-0001','guest',NULL),
(2,'Bob','Smith','bob.smith@example.com','555-0002','guest',NULL),
(3,'Carol','Jones','carol.jones@example.com','555-0003','host',1),
(4,'David','Lee','david.lee@example.com','555-0004','guest',2),
(5,'Eva','Martinez','eva.martinez@example.com','555-0005','host',2),
(6,'Frank','Wong','frank.wong@example.com','555-0006','guest',3),
(7,'Grace','Kim','grace.kim@example.com','555-0007','guest',NULL),
(8,'Henry','Brown','henry.brown@example.com','555-0008','host',4),
(9,'Ivy','Chen','ivy.chen@example.com','555-0009','guest',5),
(10,'Jack','Wilson','jack.wilson@example.com','555-0010','guest',NULL);

INSERT INTO customer (customerId, customerFirstName, customerLastName, email, phone, customerType, organizationId) VALUES
(11,'Noah','Adams','noah.adams@example.com','555-0011','guest',NULL),
(12,'Kate','Lu','katelu@example.com','555-0012','guest',1),
(13,'Liam','Clark','liam.clark@example.com','555-0013','guest',NULL),
(14,'Emma','Davis','emma.davis@example.com','555-0014','guest',2),
(15,'Mason','Edwards','mason.edwards@example.com','555-0015','host',3),
(16,'Sophia','Foster','sophia.foster@example.com','555-0016','guest',NULL),
(17,'Ethan','Gibson','ethan.gibson@example.com','555-0017','guest',4),
(18,'Ava','Hughes','ava.hughes@example.com','555-0018','guest',5),
(19,'Logan','Irwin','logan.irwin@example.com','555-0019','guest',NULL),
(20,'Mia','Jenkins','mia.jenkins@example.com','555-0020','host',1),
(21,'Lucas','Kelly','lucas.kelly@example.com','555-0021','guest',2),
(22,'Isabella','Lam','isabella.lam@example.com','555-0022','guest',3),
(23,'Jackson','Mitchell','jackson.mitchell@example.com','555-0023','guest',NULL),
(24,'Charlotte','Nguyen','charlotte.nguyen@example.com','555-0024','guest',4),
(25,'Aiden','Owens','aiden.owens@example.com','555-0025','host',5),
(26,'Amelia','Parker','amelia.parker@example.com','555-0026','guest',NULL),
(27,'Oliver','Quinn','oliver.quinn@example.com','555-0027','guest',1),
(28,'Harper','Ross','harper.ross@example.com','555-0028','guest',NULL),
(29,'Elijah','Scott','elijah.scott@example.com','555-0029','guest',2),
(30,'Evelyn','Taylor','evelyn.taylor@example.com','555-0030','guest',3),
(31,'Henry','Anderson','henry.anderson@example.com','555-0031','guest',NULL),
(32,'Abigail','Bryant','abigail.bryant@example.com','555-0032','guest',4),
(33,'Sebastian','Cole','sebastian.cole@example.com','555-0033','guest',5),
(34,'Emily','Diaz','emily.diaz@example.com','555-0034','guest',NULL),
(35,'Jack','Evans','jack.evans@example.com','555-0035','host',1),
(36,'Ella','Fisher','ella.fisher@example.com','555-0036','guest',2),
(37,'Michael','Garcia','michael.garcia@example.com','555-0037','guest',3),
(38,'Scarlett','Hall','scarlett.hall@example.com','555-0038','guest',NULL),
(39,'Daniel','Ingram','daniel.ingram@example.com','555-0039','guest',4),
(40,'Victoria','James','victoria.james@example.com','555-0040','guest',5),
(41,'Matthew','King','matthew.king@example.com','555-0041','guest',NULL),
(42,'Aria','Lopez','aria.lopez@example.com','555-0042','guest',1),
(43,'Joseph','Morgan','joseph.morgan@example.com','555-0043','guest',2),
(44,'Grace','Nelson','grace.nelson@example.com','555-0044','guest',NULL),
(45,'Wyatt','Owens','wyatt.owens@example.com','555-0045','host',3),
(46,'Chloe','Perez','chloe.perez@example.com','555-0046','guest',4),
(47,'David','Reed','david.reed@example.com','555-0047','guest',NULL),
(48,'Lily','Sanders','lily.sanders@example.com','555-0048','guest',5),
(49,'Andrew','Turner','andrew.turner@example.com','555-0049','guest',1),
(50,'Zoe','Underwood','zoe.underwood@example.com','555-0050','host',2),
(51,'James','Vasquez','james.vasquez@example.com','555-0051','guest',3),
(52,'Hannah','White','hannah.white@example.com','555-0052','guest',NULL),
(53,'Owen','Young','owen.young@example.com','555-0053','guest',4),
(54,'Layla','Zimmer','layla.zimmer@example.com','555-0054','guest',5),
(55,'Nathan','Bennett','nathan.bennett@example.com','555-0055','guest',NULL),
(56,'Riley','Carter','riley.carter@example.com','555-0056','guest',1),
(57,'Samuel','Douglas','samuel.douglas@example.com','555-0057','guest',2),
(58,'Deniz Acar','Kostem','denizzy@example.com','555-0058','guest',3),
(59,'Leo','Franklin','leo.franklin@example.com','555-0059','guest',NULL),
(60,'Penelope','Griffin','penelope.griffin@example.com','555-0060','host',4),
(61,'Isaac','Hayes','isaac.hayes@example.com','555-0061','guest',5),
(62,'Victoria','Irwin','victoria.irwin@example.com','555-0062','guest',NULL),
(63,'Julian','Jensen','julian.jensen@example.com','555-0063','guest',1),
(64,'Aurora','Kerr','aurora.kerr@example.com','555-0064','guest',2),
(65,'Dylan','Lane','dylan.lane@example.com','555-0065','guest',3),
(66,'Sophia','Yan','soph.yan@example.com','555-0066','guest',NULL),
(67,'Christian','Nash','christian.nash@example.com','555-0067','guest',4),
(68,'Ellie','Ortiz','ellie.ortiz@example.com','555-0068','guest',5),
(69,'Hudson','Price','hudson.price@example.com','555-0069','guest',NULL),
(70,'Zoey','Quincy','zoey.quincy@example.com','555-0070','guest',1),
(71,'Aaron','Reeves','aaron.reeves@example.com','555-0071','guest',2),
(72,'Bella','Stevens','bella.stevens@example.com','555-0072','guest',3),
(73,'Farisa','Rahman','farisa@example.com','555-0073','guest',NULL),
(74,'Madison','Ulrich','madison.ulrich@example.com','555-0074','guest',4),
(75,'Evan','Vega','evan.vega@example.com','555-0075','guest',5),
(76,'Clara','Wallace','clara.wallace@example.com','555-0076','guest',NULL),
(77,'Jonathan','Xavier','jonathan.xavier@example.com','555-0077','guest',1),
(78,'Mila','York','mila.york@example.com','555-0078','guest',2),
(79,'Gavin','Zimmerman','gavin.zimmerman@example.com','555-0079','guest',3),
(80,'Jeffrey','Epstein','jeffrey.eppstein@example.com','555-0080','host',4);


INSERT INTO customer_rating (customerId, relationshipRating, flexibilityRating, cooperativenessRating, paymentPromptRating) VALUES
(1,5,5,4,5),
(2,4,4,4,4),
(3,5,5,5,5),
(4,3,4,3,4),
(5,5,4,5,4),
(6,4,3,4,3),
(7,3,3,3,3),
(8,5,4,4,5),
(9,4,5,4,4),
(10,5,5,5,5);

INSERT INTO reservation (reservationId, roomNum, customerId, numGuests, bedTypePref, sizePref, smokingPref, location, proxPoolPref, proxGaragePref, reservationDateTime, checkInDateTime, checkOutDateTime, hasHandicappedAccess, needsAdvanceDeposit) VALUES
(1, 201, 1,2,'King','Standard','nonsmoking','Pool side',0.1,0.1,'2025-01-01 08:00','2025-01-01 11:00','2025-01-01 15:00',0,0),
(2, 101, 2,2,'Double','Standard','smoking','Garage side',0.2,0.1,'2025-01-02 08:00','2025-01-02 11:00','2025-01-02 15:00',0,0),
(3, 102, 3,3,'King','Suite',NULL,'Pool side',0.3,0.2,'2025-01-03 08:00','2025-01-03 11:00','2025-01-03 15:00',0,1),
(4, 103, 4,4,'Double','Standard','nonsmoking','Garage side',0.4,0.2,'2025-01-04 08:00','2025-01-04 11:00','2025-01-04 15:00',1,0),
(5, 104, 5,2,'King','Standard','smoking','Pool side',0.1,0.3,'2025-01-05 08:00','2025-01-05 11:00','2025-01-05 15:00',0,1),
(6, 105, 6,3,'Double','Suite','nonsmoking','Garage side',0.2,0.3,'2025-01-06 08:00','2025-01-06 11:00','2025-01-06 15:00',0,0),
(7, 106, 7,2,'King','Standard',NULL,'Pool side',0.3,0.4,'2025-01-07 08:00','2025-01-07 11:00','2025-01-07 15:00',0,0),
(8, 107, 8,4,'Double','Suite','smoking','Garage side',0.4,0.4,'2025-01-08 08:00','2025-01-08 11:00','2025-01-08 15:00',1,1),
(9, 108, 9,2,'King','Standard','nonsmoking','Pool side',0.1,0.1,'2025-01-09 08:00','2025-01-09 11:00','2025-01-09 15:00',0,0),
(10, 109, 10,3,'Double','Standard','smoking','Garage side',0.2,0.2,'2025-01-10 08:00','2025-01-10 11:00','2025-01-10 15:00',0,1),
(11, 110, 11,2,'King','Suite',NULL,'Pool side',0.3,0.1,'2025-01-11 08:00','2025-01-11 11:00','2025-01-11 15:00',0,0),
(12, 111, 12,4,'Double','Standard','nonsmoking','Garage side',0.4,0.2,'2025-01-12 08:00','2025-01-12 11:00','2025-01-12 15:00',1,0),
(13, 112, 13,2,'King','Standard','smoking','Pool side',0.1,0.3,'2025-01-13 08:00','2025-01-13 11:00','2025-01-13 15:00',0,1),
(14, 113, 14,3,'Double','Suite','nonsmoking','Garage side',0.2,0.4,'2025-01-14 08:00','2025-01-14 11:00','2025-01-14 15:00',0,0),
(15, 114, 15,2,'King','Standard',NULL,'Pool side',0.3,0.1,'2025-01-15 08:00','2025-01-15 11:00','2025-01-15 15:00',0,0),
(16, 115, 16,4,'Double','Suite','smoking','Garage side',0.4,0.2,'2025-01-16 08:00','2025-01-16 11:00','2025-01-16 15:00',1,1),
(17, 116, 17,2,'King','Standard','nonsmoking','Pool side',0.1,0.3,'2025-01-17 08:00','2025-01-17 11:00','2025-01-17 15:00',0,0),
(18, 117, 18,3,'Double','Standard','smoking','Garage side',0.2,0.4,'2025-01-18 08:00','2025-01-18 11:00','2025-01-18 15:00',0,1),
(19, 118, 19,2,'King','Suite',NULL,'Pool side',0.3,0.1,'2025-01-19 08:00','2025-01-19 11:00','2025-01-19 15:00',0,0),
(20, 119, 20,4,'Double','Standard','nonsmoking','Garage side',0.4,0.2,'2025-01-20 08:00','2025-01-20 11:00','2025-01-20 15:00',1,0),
(21, 120, 21,2,'King','Standard','smoking','Pool side',0.1,0.3,'2025-01-21 08:00','2025-01-21 11:00','2025-01-21 15:00',0,1),
(22, 121, 22,3,'Double','Suite','nonsmoking','Garage side',0.2,0.4,'2025-01-22 08:00','2025-01-22 11:00','2025-01-22 15:00',0,0),
(23, 122, 23,2,'King','Standard',NULL,'Pool side',0.3,0.1,'2025-01-23 08:00','2025-01-23 11:00','2025-01-23 15:00',0,0),
(24, 123, 24,4,'Double','Suite','smoking','Garage side',0.4,0.2,'2025-01-24 08:00','2025-01-24 11:00','2025-01-24 15:00',1,1),
(25, 124, 25,2,'King','Standard','nonsmoking','Pool side',0.1,0.3,'2025-01-25 08:00','2025-01-25 11:00','2025-01-25 15:00',0,0),
(26, 125, 26,3,'Double','Standard','smoking','Garage side',0.2,0.4,'2025-01-26 08:00','2025-01-26 11:00','2025-01-26 15:00',0,1),
(27, 126, 27,2,'King','Suite',NULL,'Pool side',0.3,0.1,'2025-01-27 08:00','2025-01-27 11:00','2025-01-27 15:00',0,0),
(28, 127, 28,4,'Double','Standard','nonsmoking','Garage side',0.4,0.2,'2025-01-28 08:00','2025-01-28 11:00','2025-01-28 15:00',1,0),
(29, 128, 29,2,'King','Standard','smoking','Pool side',0.1,0.3,'2025-02-01 08:00','2025-02-01 11:00','2025-02-01 15:00',0,1),
(30, 129, 30,3,'Double','Suite','nonsmoking','Garage side',0.2,0.4,'2025-02-02 08:00','2025-02-02 11:00','2025-02-02 15:00',0,0),
(31, 130, 31,2,'King','Standard',NULL,'Pool side',0.3,0.1,'2025-02-03 08:00','2025-02-03 11:00','2025-02-03 15:00',0,0),
(32, 201, 32,4,'Double','Suite','smoking','Garage side',0.4,0.2,'2025-02-04 08:00','2025-02-04 11:00','2025-02-04 15:00',1,1),
(33, 101, 33,2,'King','Standard','nonsmoking','Pool side',0.1,0.3,'2025-02-05 08:00','2025-02-05 11:00','2025-02-05 15:00',0,0),
(34, 102, 34,3,'Double','Standard','smoking','Garage side',0.2,0.4,'2025-02-06 08:00','2025-02-06 11:00','2025-02-06 15:00',0,1),
(35, 103, 35,2,'King','Suite',NULL,'Pool side',0.3,0.1,'2025-02-07 08:00','2025-02-07 11:00','2025-02-07 15:00',0,0),
(36, 104, 36,4,'Double','Standard','nonsmoking','Garage side',0.4,0.2,'2025-02-08 08:00','2025-02-08 11:00','2025-02-08 15:00',1,0),
(37, 105, 37,2,'King','Standard','smoking','Pool side',0.1,0.3,'2025-02-09 08:00','2025-02-09 11:00','2025-02-09 15:00',0,1),
(38, 106, 38,3,'Double','Suite','nonsmoking','Garage side',0.2,0.4,'2025-02-10 08:00','2025-02-10 11:00','2025-02-10 15:00',0,0),
(39, 107, 39,2,'King','Standard',NULL,'Pool side',0.3,0.1,'2025-02-11 08:00','2025-02-11 11:00','2025-02-11 15:00',0,0),
(40, 108, 40,4,'Double','Suite','smoking','Garage side',0.4,0.2,'2025-02-12 08:00','2025-02-12 11:00','2025-02-12 15:00',1,1),
(41, 109, 41,2,'King','Standard','nonsmoking','Pool side',0.1,0.3,'2025-02-13 08:00','2025-02-13 11:00','2025-02-13 15:00',0,0),
(42, 110, 42,3,'Double','Standard','smoking','Garage side',0.2,0.4,'2025-02-14 08:00','2025-02-14 11:00','2025-02-14 15:00',0,1),
(43, 111, 43,2,'King','Suite',NULL,'Pool side',0.3,0.1,'2025-02-15 08:00','2025-02-15 11:00','2025-02-15 15:00',0,0),
(44, 112, 44,4,'Double','Standard','nonsmoking','Garage side',0.4,0.2,'2025-02-16 08:00','2025-02-16 11:00','2025-02-16 15:00',1,0),
(45, 113, 45,2,'King','Standard','smoking','Pool side',0.1,0.3,'2025-02-17 08:00','2025-02-17 11:00','2025-02-17 15:00',0,1),
(46, 114, 46,3,'Double','Suite','nonsmoking','Garage side',0.2,0.4,'2025-02-18 08:00','2025-02-18 11:00','2025-02-18 15:00',0,0),
(47, 115, 47,2,'King','Standard',NULL,'Pool side',0.3,0.1,'2025-02-19 08:00','2025-02-19 11:00','2025-02-19 15:00',0,0),
(48, 116, 48,4,'Double','Suite','smoking','Garage side',0.4,0.2,'2025-02-20 08:00','2025-02-20 11:00','2025-02-20 15:00',1,1),
(49, 117, 49,2,'King','Standard','nonsmoking','Pool side',0.1,0.3,'2025-02-21 08:00','2025-02-21 11:00','2025-02-21 15:00',0,0),
(50, 118, 50,3,'Double','Standard','smoking','Garage side',0.2,0.4,'2025-02-22 08:00','2025-02-22 11:00','2025-02-22 15:00',0,1),
(51, 119, 51,2,'King','Suite',NULL,'Pool side',0.3,0.1,'2025-03-01 08:00','2025-03-01 11:00','2025-03-01 15:00',0,0),
(52, 120, 52,4,'Double','Standard','nonsmoking','Garage side',0.4,0.2,'2025-03-02 08:00','2025-03-02 11:00','2025-03-02 15:00',1,0),
(53, 121, 53,2,'King','Standard','smoking','Pool side',0.1,0.3,'2025-03-03 08:00','2025-03-03 11:00','2025-03-03 15:00',0,1),
(54, 122, 54,3,'Double','Suite','nonsmoking','Garage side',0.2,0.4,'2025-03-04 08:00','2025-03-04 11:00','2025-03-04 15:00',0,0),
(55, 123, 55,2,'King','Standard',NULL,'Pool side',0.3,0.1,'2025-03-05 08:00','2025-03-05 11:00','2025-03-05 15:00',0,0),
(56, 124, 56,4,'Double','Suite','smoking','Garage side',0.4,0.2,'2025-03-06 08:00','2025-03-06 11:00','2025-03-06 15:00',1,1),
(57, 125, 57,2,'King','Standard','nonsmoking','Pool side',0.1,0.3,'2025-03-07 08:00','2025-03-07 11:00','2025-03-07 15:00',0,0),
(58, 126, 58,3,'Double','Standard','smoking','Garage side',0.2,0.4,'2025-03-08 08:00','2025-03-08 11:00','2025-03-08 15:00',0,1),
(59, 127, 59,2,'King','Suite',NULL,'Pool side',0.3,0.1,'2025-03-09 08:00','2025-03-09 11:00','2025-03-09 15:00',0,0),
(60, 128, 60,4,'Double','Standard','nonsmoking','Garage side',0.4,0.2,'2025-03-10 08:00','2025-03-10 11:00','2025-03-10 15:00',1,0),
(61, 129, 61,2,'King','Standard','smoking','Pool side',0.1,0.3,'2025-03-11 08:00','2025-03-11 11:00','2025-03-11 15:00',0,1),
(62, 130, 62,3,'Double','Suite','nonsmoking','Garage side',0.2,0.4,'2025-03-12 08:00','2025-03-12 11:00','2025-03-12 15:00',0,0),
(63, 201, 63,2,'King','Standard',NULL,'Pool side',0.3,0.1,'2025-03-13 08:00','2025-03-13 11:00','2025-03-13 15:00',0,0),
(64, 101, 64,4,'Double','Suite','smoking','Garage side',0.4,0.2,'2025-03-14 08:00','2025-03-14 11:00','2025-03-14 15:00',1,1),
(65, 102, 65,2,'King','Standard','nonsmoking','Pool side',0.1,0.3,'2025-03-15 08:00','2025-03-15 11:00','2025-03-15 15:00',0,0),
(66, 103, 66,3,'Double','Standard','smoking','Garage side',0.2,0.4,'2025-03-16 08:00','2025-03-16 11:00','2025-03-16 15:00',0,1),
(67, 104, 67,2,'King','Suite',NULL,'Pool side',0.3,0.1,'2025-03-17 08:00','2025-03-17 11:00','2025-03-17 15:00',0,0),
(68, 105, 68,4,'Double','Standard','nonsmoking','Garage side',0.4,0.2,'2025-03-18 08:00','2025-03-18 11:00','2025-03-18 15:00',1,0),
(69, 106, 69,2,'King','Standard','smoking','Pool side',0.1,0.3,'2025-03-19 08:00','2025-03-19 11:00','2025-03-19 15:00',0,1),
(70, 107, 70,3,'Double','Suite','nonsmoking','Garage side',0.2,0.4,'2025-03-20 08:00','2025-03-20 11:00','2025-03-20 15:00',0,0),
(71, 108, 71,2,'King','Standard',NULL,'Pool side',0.3,0.1,'2025-03-21 08:00','2025-03-21 11:00','2025-03-21 15:00',0,0),
(72, 109, 72,4,'Double','Suite','smoking','Garage side',0.4,0.2,'2025-03-22 08:00','2025-03-22 11:00','2025-03-22 15:00',1,1),
(73, 110, 73,2,'King','Standard','nonsmoking','Pool side',0.1,0.3,'2025-03-23 08:00','2025-03-23 11:00','2025-03-23 15:00',0,0),
(74, 111, 74,3,'Double','Standard','smoking','Garage side',0.2,0.4,'2025-03-24 08:00','2025-03-24 11:00','2025-03-24 15:00',0,1),
(75, 112, 75,2,'King','Suite',NULL,'Pool side',0.3,0.1,'2025-03-25 08:00','2025-03-25 11:00','2025-03-25 15:00',0,0),
(76, 113, 76,4,'Double','Standard','nonsmoking','Garage side',0.4,0.2,'2025-03-26 08:00','2025-03-26 11:00','2025-03-26 15:00',1,0),
(77, 114, 77,2,'King','Standard','smoking','Pool side',0.1,0.3,'2025-03-27 08:00','2025-03-27 11:00','2025-03-27 15:00',0,1),
(78, 115, 78,3,'Double','Suite','nonsmoking','Garage side',0.2,0.4,'2025-03-28 08:00','2025-03-28 11:00','2025-03-28 15:00',0,0),
(79, 116, 79,2,'King','Standard',NULL,'Pool side',0.3,0.1,'2025-03-29 08:00','2025-03-29 11:00','2025-03-29 15:00',0,0),
(80, 117, 80,4,'Double','Suite','smoking','Garage side',0.4,0.2,'2025-03-30 08:00','2025-03-30 11:00','2025-03-30 15:00',1,1);

INSERT INTO reservation (reservationId, roomNum, customerId, numGuests, bedTypePref, sizePref, smokingPref, location, proxPoolPref, proxGaragePref, reservationDateTime, checkInDateTime, checkOutDateTime, hasHandicappedAccess, needsAdvanceDeposit) VALUES
(81, 202, 1,2,'King','Standard','nonsmoking','Pool side',0.1,0.4,'2025-01-01 08:00','2025-01-01 11:00','2025-01-01 15:00',1,1),
(82, 101, 2,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-01-02 08:00','2025-01-02 11:00','2025-01-02 15:00',0,0),
(83, 102, 3,3,'King','Suite',NULL,'Pool side',0.3,0.2,'2025-01-03 08:00','2025-01-03 11:00','2025-01-03 15:00',0,0),
(84, 103, 4,4,'Double','Standard','nonsmoking','Garage side',0.4,0.1,'2025-01-04 08:00','2025-01-04 11:00','2025-01-04 15:00',0,0),
(85, 104, 5,2,'King','Standard','smoking','Pool side',0.1,0.4,'2025-01-05 08:00','2025-01-05 11:00','2025-01-05 15:00',0,1),
(86, 105, 6,2,'Double','Suite',NULL,'Garage side',0.2,0.3,'2025-01-06 08:00','2025-01-06 11:00','2025-01-06 15:00',1,0),
(87, 106, 7,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-01-07 08:00','2025-01-07 11:00','2025-01-07 15:00',0,0),
(88, 107, 8,4,'Double','Standard','smoking','Garage side',0.4,0.1,'2025-01-08 08:00','2025-01-08 11:00','2025-01-08 15:00',0,0),
(89, 108, 9,2,'King','Suite',NULL,'Pool side',0.1,0.4,'2025-01-09 08:00','2025-01-09 11:00','2025-01-09 15:00',0,1),
(90, 109, 10,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-01-10 08:00','2025-01-10 11:00','2025-01-10 15:00',0,0),
(91, 110, 11,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-01-11 08:00','2025-01-11 11:00','2025-01-11 15:00',0,0),
(92, 111, 12,4,'Double','Suite',NULL,'Garage side',0.4,0.1,'2025-01-12 08:00','2025-01-12 11:00','2025-01-12 15:00',0,0),
(93, 112, 13,2,'King','Standard','smoking','Pool side',0.1,0.4,'2025-01-13 08:00','2025-01-13 11:00','2025-01-13 15:00',0,1),
(94, 113, 14,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-01-14 08:00','2025-01-14 11:00','2025-01-14 15:00',1,0),
(95, 114, 15,3,'King','Suite',NULL,'Pool side',0.3,0.2,'2025-01-15 08:00','2025-01-15 11:00','2025-01-15 15:00',0,0),
(96, 115, 16,4,'Double','Standard','nonsmoking','Garage side',0.4,0.1,'2025-01-16 08:00','2025-01-16 11:00','2025-01-16 15:00',0,0),
(97, 116, 17,2,'King','Standard','smoking','Pool side',0.1,0.4,'2025-01-17 08:00','2025-01-17 11:00','2025-01-17 15:00',0,1),
(98, 117, 18,2,'Double','Suite',NULL,'Garage side',0.2,0.3,'2025-01-18 08:00','2025-01-18 11:00','2025-01-18 15:00',0,0),
(99, 118, 19,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-01-19 08:00','2025-01-19 11:00','2025-01-19 15:00',1,0),
(100, 119, 20,4,'Double','Standard','smoking','Garage side',0.4,0.1,'2025-01-20 08:00','2025-01-20 11:00','2025-01-20 15:00',0,0),
(101, 120,21,2,'King','Suite',NULL,'Pool side',0.1,0.4,'2025-01-21 08:00','2025-01-21 11:00','2025-01-21 15:00',0,1),
(102, 121, 22,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-01-22 08:00','2025-01-22 11:00','2025-01-22 15:00',0,0),
(103, 122, 23,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-01-23 08:00','2025-01-23 11:00','2025-01-23 15:00',0,0),
(104, 123, 24,4,'Double','Suite',NULL,'Garage side',0.4,0.1,'2025-01-24 08:00','2025-01-24 11:00','2025-01-24 15:00',0,0),
(105, 124, 25,2,'King','Standard','smoking','Pool side',0.1,0.4,'2025-01-25 08:00','2025-01-25 11:00','2025-01-25 15:00',0,1),
(106, 125, 26,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-01-26 08:00','2025-01-26 11:00','2025-01-26 15:00',1,0),
(107, 126, 27,3,'King','Suite',NULL,'Pool side',0.3,0.2,'2025-01-27 08:00','2025-01-27 11:00','2025-01-27 15:00',0,0),
(108, 127, 28,4,'Double','Standard','nonsmoking','Garage side',0.4,0.1,'2025-01-28 08:00','2025-01-28 11:00','2025-01-28 15:00',0,0),
(109, 128, 29,2,'King','Standard','smoking','Pool side',0.1,0.4,'2025-01-29 08:00','2025-01-29 11:00','2025-01-29 15:00',0,1),
(110, 129, 30,2,'Double','Suite',NULL,'Garage side',0.2,0.3,'2025-01-30 08:00','2025-01-30 11:00','2025-01-30 15:00',0,0),
(111, 130, 31,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-01-31 08:00','2025-01-31 11:00','2025-01-31 15:00',0,0),
(112, 201, 32,4,'Double','Standard','smoking','Garage side',0.4,0.1,'2025-02-01 08:00','2025-02-01 11:00','2025-02-01 15:00',0,0),
(113, 101, 33,2,'King','Suite',NULL,'Pool side',0.1,0.4,'2025-02-02 08:00','2025-02-02 11:00','2025-02-02 15:00',0,1),
(114, 102, 34,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-02-03 08:00','2025-02-03 11:00','2025-02-03 15:00',0,0),
(115, 103, 35,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-02-04 08:00','2025-02-04 11:00','2025-02-04 15:00',1,0),
(116, 104, 36,4,'Double','Suite',NULL,'Garage side',0.4,0.1,'2025-02-05 08:00','2025-02-05 11:00','2025-02-05 15:00',0,0),
(117, 105, 37,2,'King','Standard','smoking','Pool side',0.1,0.4,'2025-02-06 08:00','2025-02-06 11:00','2025-02-06 15:00',0,1),
(118, 106, 38,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-02-07 08:00','2025-02-07 11:00','2025-02-07 15:00',0,0),
(119, 107, 39,3,'King','Suite',NULL,'Pool side',0.3,0.2,'2025-02-08 08:00','2025-02-08 11:00','2025-02-08 15:00',0,0),
(120, 108, 40,4,'Double','Standard','nonsmoking','Garage side',0.4,0.1,'2025-02-09 08:00','2025-02-09 11:00','2025-02-09 15:00',0,0),
(121, 109, 41,2,'King','Standard','smoking','Pool side',0.1,0.4,'2025-02-10 08:00','2025-02-10 11:00','2025-02-10 15:00',0,1),
(122, 110, 42,2,'Double','Suite',NULL,'Garage side',0.2,0.3,'2025-02-11 08:00','2025-02-11 11:00','2025-02-11 15:00',0,0),
(123, 112, 43,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-02-12 08:00','2025-02-12 11:00','2025-02-12 15:00',0,0),
(124, 113, 44,4,'Double','Standard','smoking','Garage side',0.4,0.1,'2025-02-13 08:00','2025-02-13 11:00','2025-02-13 15:00',1,0),
(125, 114, 45,2,'King','Suite',NULL,'Pool side',0.1,0.4,'2025-02-14 08:00','2025-02-14 11:00','2025-02-14 15:00',0,1),
(126, 115, 46,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-02-15 08:00','2025-02-15 11:00','2025-02-15 15:00',0,0),
(127, 116, 47,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-02-16 08:00','2025-02-16 11:00','2025-02-16 15:00',0,0),
(128, 117, 48,4,'Double','Suite',NULL,'Garage side',0.4,0.1,'2025-02-17 08:00','2025-02-17 11:00','2025-02-17 15:00',0,0),
(129, 118, 49,2,'King','Standard','smoking','Pool side',0.1,0.4,'2025-02-18 08:00','2025-02-18 11:00','2025-02-18 15:00',0,1),
(130, 119, 50,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-02-19 08:00','2025-02-19 11:00','2025-02-19 15:00',1,0),
(131, 120, 51,3,'King','Suite',NULL,'Pool side',0.3,0.2,'2025-02-20 08:00','2025-02-20 11:00','2025-02-20 15:00',0,0),
(132, 121, 52,4,'Double','Standard','nonsmoking','Garage side',0.4,0.1,'2025-02-21 08:00','2025-02-21 11:00','2025-02-21 15:00',0,0),
(133, 122, 53,2,'King','Standard','smoking','Pool side',0.1,0.4,'2025-02-22 08:00','2025-02-22 11:00','2025-02-22 15:00',0,1),
(134, 123, 54,2,'Double','Suite',NULL,'Garage side',0.2,0.3,'2025-02-23 08:00','2025-02-23 11:00','2025-02-23 15:00',0,0),
(135, 124, 55,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-02-24 08:00','2025-02-24 11:00','2025-02-24 15:00',0,0),
(136, 125, 56,4,'Double','Standard','smoking','Garage side',0.4,0.1,'2025-02-25 08:00','2025-02-25 11:00','2025-02-25 15:00',0,0),
(137, 126, 57,2,'King','Suite',NULL,'Pool side',0.1,0.4,'2025-02-26 08:00','2025-02-26 11:00','2025-02-26 15:00',0,1),
(138, 127, 58,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-02-27 08:00','2025-02-27 11:00','2025-02-27 15:00',1,0),
(139, 128, 59,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-02-28 08:00','2025-02-28 11:00','2025-02-28 15:00',0,0),
(140, 129, 60,4,'Double','Suite',NULL,'Garage side',0.4,0.1,'2025-03-01 08:00','2025-03-01 11:00','2025-03-01 15:00',0,0),
(141, 130, 61,2,'King','Standard','smoking','Pool side',0.1,0.4,'2025-03-02 08:00','2025-03-02 11:00','2025-03-02 15:00',0,1),
(142, 201, 62,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-03-03 08:00','2025-03-03 11:00','2025-03-03 15:00',0,0),
(143, 101, 63,3,'King','Suite',NULL,'Pool side',0.3,0.2,'2025-03-04 08:00','2025-03-04 11:00','2025-03-04 15:00',0,0),
(144, 102, 64,4,'Double','Standard','nonsmoking','Garage side',0.4,0.1,'2025-03-05 08:00','2025-03-05 11:00','2025-03-05 15:00',1,0),
(145, 103, 65,2,'King','Standard','smoking','Pool side',0.1,0.4,'2025-03-06 08:00','2025-03-06 11:00','2025-03-06 15:00',0,1),
(146, 104, 66,2,'Double','Suite',NULL,'Garage side',0.2,0.3,'2025-03-07 08:00','2025-03-07 11:00','2025-03-07 15:00',0,0),
(147, 105, 67,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-03-08 08:00','2025-03-08 11:00','2025-03-08 15:00',0,0),
(148, 106, 68,4,'Double','Standard','smoking','Garage side',0.4,0.1,'2025-03-09 08:00','2025-03-09 11:00','2025-03-09 15:00',0,0),
(149, 107, 69, 2,'King','Suite',NULL,'Pool side',0.1,0.4,'2025-03-10 08:00','2025-03-10 11:00','2025-03-10 15:00',0,1),
(150, 108, 70,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-03-11 08:00','2025-03-11 11:00','2025-03-11 15:00',1,0),
(151, 109, 71,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-03-12 08:00','2025-03-12 11:00','2025-03-12 15:00',0,0),
(152, 110, 72,4,'Double','Suite',NULL,'Garage side',0.4,0.1,'2025-03-13 08:00','2025-03-13 11:00','2025-03-13 15:00',0,0),
(153, 111, 73,2,'King','Standard','nonsmoking','Pool side',0.1,0.4,'2025-03-14 08:00','2025-03-14 11:00','2025-03-14 15:00',0,1),
(154, 112, 74,2,'Double','Standard','smoking','Garage side',0.2,0.3,'2025-03-15 08:00','2025-03-15 11:00','2025-03-15 15:00',0,0),
(155, 113, 75,3,'King','Suite',NULL,'Pool side',0.3,0.2,'2025-03-16 08:00','2025-03-16 11:00','2025-03-16 15:00',1,0),
(156, 114, 76,4,'Double','Standard','nonsmoking','Garage side',0.4,0.1,'2025-03-17 08:00','2025-03-17 11:00','2025-03-17 15:00',0,0),
(157, 115, 77,2,'King','Standard','smoking','Pool side',0.1,0.4,'2025-03-18 08:00','2025-03-18 11:00','2025-03-18 15:00',0,1),
(158, 116, 78,2,'Double','Suite',NULL,'Garage side',0.2,0.3,'2025-03-19 08:00','2025-03-19 11:00','2025-03-19 15:00',0,0),
(159, 117, 79,3,'King','Standard','nonsmoking','Pool side',0.3,0.2,'2025-03-20 08:00','2025-03-20 11:00','2025-03-20 15:00',0,0),
(160, 118, 80,4,'Double','Standard','smoking','Garage side',0.4,0.1,'2025-03-21 08:00','2025-03-21 11:00','2025-03-21 15:00',0,0);


INSERT INTO advance_deposit (depositId, reservationId, amount, receivedDate) VALUES
(1,3,200,'2025-01-01'),
(2,5,150,'2025-01-02'),
(3,8,250,'2025-01-03'),
(4,10,200,'2025-01-04'),
(5,13,200,'2025-01-05'),
(6,16,250,'2025-01-06'),
(7,18,150,'2025-01-07'),
(8,21,200,'2025-01-08'),
(9,24,250,'2025-01-09'),
(10,26,150,'2025-01-10'),
(11,29,200,'2025-02-01'),
(12,32,250,'2025-02-02'),
(13,34,150,'2025-02-03'),
(14,37,200,'2025-02-04'),
(15,40,250,'2025-02-05'),
(16,42,150,'2025-02-06'),
(17,45,200,'2025-02-07'),
(18,48,250,'2025-02-08'),
(19,50,150,'2025-02-09'),
(20,51,200,'2025-03-01'),
(21,56,250,'2025-03-02'),
(22,58,150,'2025-03-03'),
(23,60,200,'2025-03-04'),
(24,62,250,'2025-03-05'),
(25,64,150,'2025-03-06'),
(26,66,200,'2025-03-07'),
(27,68,250,'2025-03-08'),
(28,70,150,'2025-03-09'),
(29,72,200,'2025-03-10'),
(30,80,250,'2025-03-11');

INSERT INTO room_assignment (assignmentId, reservationId, roomNum, wingId, extensionApplied, extensionFeeApplied, timeFromReservedDate) VALUES
(1,1,101,1,0,0,0),
(2,2,102,1,0,0,30),
(3,3,103,1,1,30,60),
(4,4,104,1,0,0,90),
(5,5,105,1,0,0,120),
(6,6,106,1,1,30,150),
(7,7,107,1,0,0,180),
(8,8,108,1,0,0,210),
(9,9,109,2,0,0,240),
(10,10,110,2,1,30,270),
(11,11,111,2,0,0,300),
(12,12,112,2,0,0,330),
(13,13,113,2,1,30,360),
(14,14,114,2,0,0,390),
(15,15,115,2,0,0,420),
(16,16,116,2,1,30,450),
(17,17,117,2,0,0,480),
(18,18,118,3,0,0,510),
(19,19,119,3,1,30,540),
(20,20,120,3,0,0,570),
(21,21,121,3,0,0,600),
(22,22,122,3,1,30,630),
(23,23,123,3,0,0,660),
(24,24,124,3,0,0,690),
(25,25,125,3,1,30,720),
(26,26,126,3,0,0,750),
(27,27,127,1,0,0,780),
(28,28,128,1,1,30,810),
(29,29,129,2,0,0,840),
(30,30,130,3,0,0,870),
(31,31,101,1,0,0,900),
(32,32,102,1,1,30,930),
(33,33,103,1,0,0,960),
(34,34,104,1,0,0,990),
(35,35,105,1,1,30,1020),
(36,36,106,1,0,0,1050),
(37,37,107,1,0,0,1080),
(38,38,108,1,1,30,1110),
(39,39,109,2,0,0,1140),
(40,40,110,2,0,0,1170),
(41,41,111,2,1,30,1200),
(42,42,112,2,0,0,1230),
(43,43,113,2,0,0,1260),
(44,44,114,2,1,30,1290),
(45,45,115,2,0,0,1320),
(46,46,116,2,0,0,1350),
(47,47,117,2,1,30,1380),
(48,48,118,3,0,0,1410),
(49,49,119,3,0,0,1440),
(50,50,120,3,1,30,1470),
(51,51,121,3,0,0,1500),
(52,52,122,3,0,0,1530),
(53,53,123,3,1,30,1560),
(54,54,124,3,0,0,1590),
(55,55,125,3,0,0,1620),
(56,56,126,3,1,30,1650),
(57,57,127,1,0,0,1680),
(58,58,128,1,0,0,1710),
(59,59,129,2,1,30,1740),
(60,60,130,3,0,0,1770),
(61,61,101,1,0,0,1800),
(62,62,102,1,0,0,1830),
(63,63,103,1,1,30,1860),
(64,64,104,1,0,0,1890),
(65,65,105,1,0,0,1920),
(66,66,106,1,1,30,1950),
(67,67,107,1,0,0,1980),
(68,68,108,1,0,0,2010),
(69,69,109,2,1,30,2040),
(70,70,110,2,0,0,2070),
(71,71,111,2,0,0,2100),
(72,72,112,2,1,30,2130),
(73,73,113,2,0,0,2160),
(74,74,114,2,0,0,2190),
(75,75,115,2,1,30,2220),
(76,76,116,2,0,0,2250),
(77,77,117,2,0,0,2280),
(78,78,118,3,1,30,2310),
(79,79,119,3,0,0,2340),
(80,80,120,3,0,0,2370);

INSERT INTO room_adjacency (roomNum1, roomNum2, connectionType) VALUES
(101,102,'moveable wall'),
(103,104,'private door'),
(105,106,'moveable wall'),
(107,108,'private door'),
(119,120,'moveable wall');

INSERT INTO event (eventId, eventName, customerId, attendance, startDateTime, endDateTime, roomNum) VALUES
(1,'Tech Conference',3,120,'2025-02-10 09:00','2025-02-10 17:00',201),
(2,'Board Meeting',5,20,'2025-02-15 13:00','2025-02-15 18:00',202),
(3,'Wedding Reception',8,200,'2025-03-01 18:00','2025-03-01 23:00',205),
(4,'Training Workshop',3,40,'2025-03-05 09:00','2025-03-05 16:00',203),
(5,'Product Launch',5,80,'2025-03-10 10:00','2025-03-10 14:00',204);

INSERT INTO event_usage_slot (usageId, eventId, roomNum, slotId, roomRateId, discount, finalRate, notes) VALUES
(1,1,201,1,31,0,300,'standard non-eating morning slot'),
(2,1,201,3,33,50,270,'discount for multiple non-eating usages'),
(3,2,202,2,36,0,430,'lunch slot includes eating surcharge'),
(4,2,202,3,37,30,270,'waived fee for free noneating slot'),
(5,3,205,4,50,100,500,'discount for large number of guests'),
(6,4,203,1,39,0,350,'training morning slot'),
(7,4,203,3,41,40,320,'repeat non-eating usage discount'),
(8,5,204,2,44,0,420,'authorized lunch event');


INSERT INTO bill (billId, roomNum, customerId, amount, description, checkOutDateTime) VALUES
(1,101,1,600,'Weekend stay with mini bar','2025-01-05 11:00'),
(2,103,2,450,'Business stay','2025-01-06 11:00'),
(3,201,3,950,'Conference room and services','2025-02-10 18:00'),
(4,205,8,1500,'Wedding reception','2025-03-02 01:00'),
(5,110,4,300,'Short stay','2025-01-07 11:00'),
(6,120,9,520,'Family stay','2025-01-08 11:00'),
(7,202,5,700,'Board meeting','2025-02-15 19:00'),
(8,203,3,500,'Workshop','2025-03-05 17:00'),
(9,204,5,650,'Product launch','2025-03-10 15:00'),
(10,115,6,400,'Leisure stay','2025-01-09 11:00');

INSERT INTO charge (chargeId, billId, roomNum, customerId, chargeDescription, chargeType) VALUES
(1,1,101,1,'room charge','expected'),
(2,1,101,1,'mini bar','ordered'),
(3,1,101,1,'phone usage','authorized'),
(4,2,103,2,'room charge','expected'),
(5,2,103,2,'phone usage','authorized'),
(6,3,201,3,'meeting room charge','expected'),
(7,3,201,3,'catering','ordered'),
(8,3,201,3,'phone usage','authorized'),
(9,4,205,8,'banquet hall','expected'),
(10,4,205,8,'extra decoration','ordered'),
(11,5,110,4,'room charge','expected'),
(12,6,120,9,'room charge','expected'),
(13,6,120,9,'phone usage','authorized'),
(14,7,202,5,'meeting room charge','expected'),
(15,8,203,3,'meeting room charge','expected'),
(16,9,204,5,'meeting room charge','expected'),
(17,10,115,6,'room charge','expected');

INSERT INTO billing_account (billingAccountId, primaryCustomerId, accountName, billingAddress, customerType, organizationId) VALUES
(1,1,'Alice Personal Account','123 Main St','guest',NULL),
(2,NULL,'Acme Corp Master Account','1 Corporate Plaza','organization',1),
(3,5,'Globex Board Account','500 Business Rd','host',2);

INSERT INTO billing_account_member (billingAccountId, billId, customerId, sharePercent) VALUES
(1,1,1,100.0),
(2,3,3,50.0),
(2,3,5,50.0),
(2,4,8,100.0),
(3,7,5,70.0),
(3,7,4,30.0);

INSERT INTO card_scan_enter (cardScanEnterId, customerId, roomNum, scanDateTime, location) VALUES
(1,1,101,'2025-01-03 15:05','Main Tower - Wing 1'),
(2,2,103,'2025-01-04 16:10','Main Tower - Wing 1'),
(3,3,201,'2025-02-10 08:30','Conference Center'),
(4,8,205,'2025-03-01 17:30','Conference Center');

INSERT INTO card_scan_leave (cardScanLeaveId, customerId, roomNum, scanDateTime, location) VALUES
(1,1,101,'2025-01-05 10:55','Main Tower - Wing 1'),
(2,2,103,'2025-01-06 10:45','Main Tower - Wing 1'),
(3,3,201,'2025-02-10 18:15','Conference Center'),
(4,8,205,'2025-03-02 00:45','Conference Center');

INSERT INTO customer_request (callId, isAnswered, customerPhone, roomNum, isSmoking) VALUES
(1,0,'555-0001',101,1),
(2,1,'555-0002',103,0),
(3,1,'555-0003',110,NULL),
(4,0,'555-0004',120,1);

COMMIT;
