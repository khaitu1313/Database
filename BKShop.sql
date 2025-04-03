DROP DATABASE BKShop;
CREATE DATABASE BKShop;

CREATE TABLE BKShop.Employee (
    ID INT PRIMARY KEY,
    SSN VARCHAR(255) UNIQUE NOT NULL,
    Name VARCHAR(255) NOT NULL
);

CREATE TABLE BKShop.Store_Manager (
    ID INT PRIMARY KEY,
    FOREIGN KEY (ID) REFERENCES Employee(ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE BKShop.Warehouse_Manager (
    ID INT PRIMARY KEY,
    FOREIGN KEY (ID) REFERENCES Employee(ID) ON DELETE CASCADE ON UPDATE CASCADE
);

DELIMITER $$
CREATE TRIGGER BKShop.Disjoint_SM BEFORE INSERT ON BKShop.Store_Manager
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM BKShop.Warehouse_Manager WHERE ID = New.ID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee cannot be both a Store Manager and a Warehouse Manager.';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER BKShop.Disjoint_WM BEFORE INSERT ON BKShop.Warehouse_Manager
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM BKShop.Store_Manager WHERE ID = New.ID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee cannot be both a Store Manager and a Warehouse Manager.';
    END IF;
END$$
DELIMITER ;

CREATE TABLE BKShop.Warehouse (
    Address VARCHAR(255) PRIMARY KEY,
    Name VARCHAR(255),
    Area DECIMAL(10,2) CHECK (Area > 0),
    WM_ID INT,
    FOREIGN KEY (WM_ID) REFERENCES Warehouse_Manager(ID) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE BKShop.Discount_Program (
    ID INT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Description VARCHAR(255),
    FromDate DATE NOT NULL,
    ToDate DATE NOT NULL,
    Percent INT NOT NULL CHECK (Percent>=20 AND Percent<=80),
    CHECK (FromDate < ToDate) 
);

CREATE TABLE BKShop.Brand (
    Name VARCHAR(255) PRIMARY KEY
);

CREATE TABLE BKShop.Payment_Method (
    Type VARCHAR(255) PRIMARY KEY,
    Description VARCHAR(255)
);

CREATE TABLE BKShop.Transaction (
    ID INT PRIMARY KEY,
    Date DATE NOT NULL,
    Time TIME NOT NULL,
    Status VARCHAR(255) NOT NULL,
    PM_Type VARCHAR(255),
    Total INT NOT NULL DEFAULT 0 CHECK (Total >= 0),
    FOREIGN KEY (PM_Type) REFERENCES Payment_Method(Type) ON DELETE SET NULL
);

CREATE TABLE BKShop.Customer (
    ID INT PRIMARY KEY,
    SSN VARCHAR(255) UNIQUE NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Address VARCHAR(255) NOT NULL,
    Phone VARCHAR(255) NOT NULL
);

DELIMITER $$
CREATE TRIGGER BKShop.Delete_Customer BEFORE DELETE ON BKShop.Customer
FOR EACH ROW
BEGIN
    UPDATE BKShop.Product P JOIN BKShop.Transaction T ON T.ID = P.T_ID
    SET P.Status = CASE 
                      WHEN P.Status = 'New_Ordering' THEN 'New'
                      WHEN P.Status = '2nd_Ordering' THEN '2nd'
                      ELSE P.Status
				   END
    WHERE P.C_ID = OLD.ID AND T.Status = 'Pending';
    
    DELETE FROM BKShop.Transaction WHERE ID = OLD.ID AND Status = 'Pending';
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER BKShop.Create_Transaction AFTER INSERT ON BKShop.Customer
FOR EACH ROW
BEGIN
    INSERT INTO BKShop.Transaction (ID, Date, Time, Status)
    VALUES (New.ID, CURRENT_DATE, CURRENT_TIME, 'Pending');
END$$
DELIMITER ;

CREATE TABLE BKShop.Product (
    ID INT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Image VARCHAR(255) NOT NULL,
    Price INT NOT NULL CHECK (Price >= 0),
    M_Date DATE NOT NULL,
    E_Date DATE NOT NULL,
    Status VARCHAR(255) NOT NULL,
    B_Name VARCHAR(255) NOT NULL,
    W_Addr VARCHAR(255),
    C_ID INT DEFAULT NULL,
    T_ID INT DEFAULT NULL,
    FOREIGN KEY (B_Name) REFERENCES Brand(Name) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (W_Addr) REFERENCES Warehouse(Address) ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (C_ID) REFERENCES Customer(ID) ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (T_ID) REFERENCES Transaction(ID) ON UPDATE CASCADE ON DELETE SET NULL,
    CHECK (M_Date < E_Date) 
);

DELIMITER $$
CREATE TRIGGER BKShop.Product_2Hand BEFORE INSERT ON BKShop.Product
FOR EACH ROW
BEGIN
    IF NEW.Status = '2nd' THEN
        SET NEW.Price = ROUND(NEW.Price*0.95, 0);
    END IF;
END$$
DELIMITER $$

DELIMITER $$
CREATE TRIGGER BKShop.Product_Status AFTER UPDATE ON BKShop.Transaction
FOR EACH ROW
BEGIN
    IF New.Status = 'Finished' THEN
        UPDATE BKShop.Product SET Status = 'Sold' WHERE T_ID = New.ID;
    END IF;
END$$
DELIMITER ;

CREATE TABLE BKShop.Laptop (
	ID INT PRIMARY KEY,
    RAM INT NOT NULL,
    CPU VARCHAR(255) NOT NULL,
    Graphic_Card VARCHAR(255) NOT NULL,
    Purpose VARCHAR(255),
    FOREIGN KEY (ID) REFERENCES Product(ID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE BKShop.Electronic_Accessories 
(
	ID INT PRIMARY KEY,
    Connection VARCHAR(255) NOT NULL, 
    FOREIGN KEY (ID) REFERENCES Product(ID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE BKShop.Mouse (
	ID INT PRIMARY KEY,
    LED_Color VARCHAR(255) NOT NULL,
    DPI INT NOT NULL,
    FOREIGN KEY (ID) REFERENCES Electronic_Accessories(ID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE BKShop.Keyboard (
	ID INT PRIMARY KEY,
    Switch_Type VARCHAR(255) NOT NULL,
    Layout VARCHAR(255) NOT NULL,
    FOREIGN KEY (ID) REFERENCES Electronic_Accessories(ID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE BKShop.Headphone (
	ID INT PRIMARY KEY,
    Type VARCHAR(255) NOT NULL,
    FOREIGN KEY (ID) REFERENCES Electronic_Accessories(ID) ON UPDATE CASCADE ON DELETE CASCADE
);

DELIMITER $$
CREATE TRIGGER BKShop.Disjoint_Laptop BEFORE INSERT ON BKShop.Laptop
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM Mouse WHERE ID = New.ID)
       OR EXISTS (SELECT 1 FROM Keyboard WHERE ID = New.ID)
       OR EXISTS (SELECT 1 FROM Headphone WHERE ID = New.ID) THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'A Product can only belong to one type category.';
	END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER BKShop.Disjoint_Mouse BEFORE INSERT ON BKShop.Mouse
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM Laptop WHERE ID = New.ID)
       OR EXISTS (SELECT 1 FROM Keyboard WHERE ID = New.ID)
       OR EXISTS (SELECT 1 FROM Headphone WHERE ID = New.ID) THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'A Product can only belong to one type category.';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER BKShop.Disjoint_Keyboard BEFORE INSERT ON BKShop.Keyboard
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM Laptop WHERE ID = New.ID)
       OR EXISTS (SELECT 1 FROM Mouse WHERE ID = New.ID)
       OR EXISTS (SELECT 1 FROM Headphone WHERE ID = New.ID) THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'A Product can only belong to one type category.';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER BKShop.Disjoint_Headphone BEFORE INSERT ON BKShop.Headphone
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM Laptop WHERE ID = New.ID)
       OR EXISTS (SELECT 1 FROM Mouse WHERE ID = New.ID)
       OR EXISTS (SELECT 1 FROM Keyboard WHERE ID = New.ID) THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'A Product can only belong to one type category.';
    END IF;
END$$
DELIMITER ;

CREATE TABLE BKShop.Request (
    No INT PRIMARY KEY,
    Requirement VARCHAR(255),
    Feedback VARCHAR(255),
    Date DATE NOT NULL,
    C_ID INT NOT NULL,
    P_ID INT NOT NULL,
    SM_ID INT,
    FOREIGN KEY (C_ID) REFERENCES Customer(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (P_ID) REFERENCES Product(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (SM_ID) REFERENCES Store_Manager(ID) ON UPDATE CASCADE ON DELETE SET NULL
);

DELIMITER $$
CREATE TRIGGER BKShop.Exchange_Request AFTER INSERT ON BKShop.Request
FOR EACH ROW
BEGIN
	DECLARE CustomerID INT;
    DECLARE NewProduct INT;
    
    IF NEW.Requirement = 'Exchange' THEN
        SELECT P.ID INTO NewProduct
        FROM BKShop.Product P
        WHERE P.Name = (SELECT Name FROM BKShop.Product WHERE ID = NEW.P_ID AND Status = 'Sold') 
        AND P.Status = 'New' AND CURRENT_DATE BETWEEN P.M_Date AND P.E_Date
        LIMIT 1;

        IF NewProduct IS NOT NULL THEN
			SELECT C_ID INTO CustomerID FROM BKShop.Product WHERE ID = NEW.P_ID;
            UPDATE BKShop.Product SET Status = 'Sold', C_ID = CustomerID, T_ID = CustomerID WHERE ID = NewProduct;
            UPDATE BKShop.Product SET Status = '2nd', C_ID = NULL, T_ID = NULL WHERE ID = NEW.P_ID;
		ELSE 
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot handle this request because no product is available for exchange.';
        END IF;
    END IF;
END$$
DELIMITER ;

CREATE TABLE BKShop.applies ( 
    P_ID INT NOT NULL,
    D_ID INT NOT NULL,
    Saving INT NOT NULL DEFAULT 0 CHECK (Saving >= 0),
    PRIMARY KEY (P_ID, D_ID),
    FOREIGN KEY (P_ID) REFERENCES Product(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (D_ID) REFERENCES Discount_Program(ID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE BKShop.has (
    B_Name VARCHAR(255) NOT NULL,
    D_ID INT NOT NULL,
    PRIMARY KEY (B_Name, D_ID),
    FOREIGN KEY (B_Name) REFERENCES Brand(Name) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (D_ID) REFERENCES Discount_Program(ID) ON UPDATE CASCADE ON DELETE CASCADE
); 

DELIMITER $$
CREATE TRIGGER BKShop.applies_discount AFTER INSERT ON BKShop.has
FOR EACH ROW
BEGIN
    INSERT INTO BKShop.applies(P_ID, D_ID, Saving)
    SELECT P.ID, NEW.D_ID, ROUND((P.Price*D.Percent/100), 2) AS Saving
    FROM BKShop.Product P JOIN BKShop.Discount_Program D ON D.ID = NEW.D_ID
    WHERE P.B_Name = NEW.B_Name AND CURRENT_DATE BETWEEN D.FromDate AND D.ToDate AND (P.Status = 'New' OR P.Status = '2nd');

    UPDATE BKShop.Product P JOIN BKShop.Discount_Program D ON D.ID = NEW.D_ID
    SET P.Price = P.Price - ROUND((P.Price*D.Percent/100), 2)
    WHERE P.B_Name = NEW.B_Name AND CURRENT_DATE BETWEEN D.FromDate AND D.ToDate AND (P.Status = 'New' OR P.Status = '2nd');
END$$
DELIMITER $$

DELIMITER $$
CREATE TRIGGER BKShop.restore_price BEFORE DELETE ON BKShop.Discount_Program
FOR EACH ROW
BEGIN
    UPDATE BKShop.Product P JOIN BKShop.applies A ON P.ID = A.P_ID 
    SET P.Price = P.Price + A.Saving 
    WHERE A.D_ID = OLD.ID AND (P.Status = 'New' OR P.Status = '2nd');
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE BKShop.CreateCustomer(
    IN New_SSN VARCHAR(255),
    IN New_Name VARCHAR(255),
    IN New_Address VARCHAR(255),
    IN New_Phone VARCHAR(255)
)
BEGIN
    DECLARE New_ID INT;
    SELECT IFNULL(MAX(ID), 0) + 1 INTO New_ID FROM BKShop.Customer;
    INSERT INTO BKShop.Customer (ID, SSN, Name, Address, Phone) VALUES (New_ID, New_SSN, New_Name, New_Address, New_Phone);
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE BKShop.Put2Transaction(IN ProductID INT, IN TransactionID INT)
BEGIN
    DECLARE NewProductID INT;
    DECLARE ProductName VARCHAR(255);
    DECLARE ProductPrice INT;
    DECLARE ProductStatus VARCHAR(255);
    SELECT Name, Price, Status INTO ProductName, ProductPrice, ProductStatus FROM BKShop.Product WHERE ID = ProductID;

    IF EXISTS (SELECT 1 FROM BKShop.Product WHERE ID = ProductID AND (Status = '2nd' OR Status = 'New') AND T_ID IS NULL) THEN
        UPDATE BKShop.Product 
        SET 
            C_ID = TransactionID, T_ID = TransactionID, 
            Status = CASE 
                        WHEN Status = 'New' THEN 'New_Ordering' 
                        WHEN Status = '2nd' THEN '2nd_Ordering' 
                     END
        WHERE ID = ProductID;
        UPDATE BKShop.Transaction SET Total = Total + ProductPrice WHERE ID = TransactionID;
    ELSE
        SELECT ID, Price, Status INTO NewProductID, ProductPrice, ProductStatus
        FROM BKShop.Product WHERE Name = ProductName AND (Status = '2nd' OR Status = 'New') AND T_ID IS NULL
        LIMIT 1;

        IF NewProductID IS NOT NULL THEN
            UPDATE BKShop.Product 
            SET 
                C_ID = TransactionID, T_ID = TransactionID, 
                Status = CASE 
                            WHEN Status = 'New' THEN 'New_Ordering' 
                            WHEN Status = '2nd' THEN '2nd_Ordering' 
                         END
            WHERE ID = NewProductID;
            UPDATE BKShop.Transaction SET Total = Total + ProductPrice WHERE ID = TransactionID;
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No valid product available.';
        END IF;
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE BKShop.Pop2Transaction(IN ProductID INT)
BEGIN
    DECLARE TransactionID INT;
    DECLARE ProductPrice INT;
    DECLARE ProductStatus VARCHAR(255);

    SELECT T_ID, Price, Status INTO TransactionID, ProductPrice, ProductStatus 
    FROM BKShop.Product WHERE ID = ProductID AND T_ID IS NOT NULL;

    IF TransactionID IS NOT NULL THEN
        UPDATE BKShop.Product 
        SET 
            T_ID = NULL, C_ID = NULL, 
            Status = CASE 
                        WHEN Status = 'New_Ordering' THEN 'New' 
                        WHEN Status = '2nd_Ordering' THEN '2nd' 
                     END
        WHERE ID = ProductID;
        UPDATE BKShop.Transaction SET Total = Total - ProductPrice WHERE ID = TransactionID;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The product is not associated with any transaction.';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE BKShop.CreateRequest(IN CustomerID INT, IN ProductID INT, IN Requirement VARCHAR(255), IN Feedback VARCHAR(255))
BEGIN
	DECLARE ReqNo INT;
    DECLARE MDate DATE;
    DECLARE EDate DATE;
    DECLARE ProductName VARCHAR(255);
    DECLARE StoreManagerID INT;
    SELECT COALESCE(MAX(No), 0) + 1 INTO ReqNo FROM BKShop.Request;
    SELECT M_Date, E_Date, Name INTO MDate, EDate, ProductName FROM BKShop.Product WHERE ID = ProductID;

	CASE LEFT(ProductName, 1)
        WHEN 'L' THEN SET StoreManagerID = 1; 
        WHEN 'C' THEN SET StoreManagerID = 2; 
        WHEN 'B' THEN SET StoreManagerID = 3; 
        WHEN 'T' THEN SET StoreManagerID = 4; 
        ELSE SET StoreManagerID = 0;     
    END CASE;
	
    IF CURRENT_DATE BETWEEN MDate AND EDate THEN
        INSERT INTO BKShop.Request (No, Requirement, Feedback, Date, C_ID, P_ID, SM_ID)
        VALUES (ReqNo, Requirement, Feedback, CURRENT_DATE, CustomerID, ProductID, StoreManagerID);
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The current date is EXPIRED for the selected product.';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE BKShop.AddLaptop(
    IN p_ID INT, IN p_Name VARCHAR(255), IN p_Image VARCHAR(255),
    IN p_Price INT, IN p_M_Date DATE, IN p_E_Date DATE, IN p_Status VARCHAR(255), 
    IN p_B_Name VARCHAR(255), IN p_W_Addr VARCHAR(255), IN p_C_ID INT, IN p_T_ID INT,
    IN p_RAM INT, IN p_CPU VARCHAR(255), IN p_Graphic_Card VARCHAR(255), IN p_Purpose VARCHAR(255)
)
BEGIN
    INSERT INTO BKShop.Product (ID, Name, Image, Price, M_Date, E_Date, Status, B_Name, W_Addr, C_ID, T_ID)
    VALUES (p_ID, p_Name, p_Image, p_Price, p_M_Date, p_E_Date, p_Status, p_B_Name, p_W_Addr, p_C_ID, p_T_ID);

    INSERT INTO BKShop.Laptop (ID, RAM, CPU, Graphic_Card, Purpose)
    VALUES (p_ID, p_RAM, p_CPU, p_Graphic_Card, p_Purpose);
END$$
DELIMITER ;
DELIMITER $$

DELIMITER $$
CREATE PROCEDURE BKShop.DeleteLaptop(
    IN p_Name VARCHAR(255), IN p_RAM INT, IN p_CPU VARCHAR(255), IN p_Graphic_Card VARCHAR(255), IN p_Purpose VARCHAR(255)
)
BEGIN
    DECLARE LaptopID INT;

    SELECT L.ID INTO LaptopID FROM BKShop.Laptop L JOIN BKShop.Product P ON L.ID = P.ID
    WHERE (p_Name IS NULL OR P.Name = p_Name)
        AND (p_RAM IS NULL OR L.RAM = p_RAM)
        AND (p_CPU IS NULL OR L.CPU = p_CPU)
        AND (p_Graphic_Card IS NULL OR L.Graphic_Card = p_Graphic_Card)
        AND (p_Purpose IS NULL OR L.Purpose = p_Purpose);

    IF LaptopID IS NOT NULL THEN
        DELETE FROM BKShop.Laptop WHERE ID = LaptopID;
        DELETE FROM BKShop.Product WHERE ID = LaptopID;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No laptop found with the specified attributes.';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE BKShop.SearchLaptop(
	IN SearchRAM INT, 
    IN SearchCPU VARCHAR(255), 
    IN SearchGPU VARCHAR(255), 
    IN SearchPurpose VARCHAR(255),
    IN SearchPrice INT
)
BEGIN
    SELECT * FROM BKShop.Product P JOIN BKShop.Laptop L ON P.ID = L.ID
    WHERE 
        (L.RAM = SearchRAM OR SearchRAM IS NULL)               
        AND (L.CPU = SearchCPU OR SearchCPU IS NULL)         
        AND (L.Graphic_Card = SearchGPU OR SearchGPU IS NULL) 
        AND (L.Purpose = SearchPurpose OR SearchPurpose IS NULL) 
        AND (P.Price <= SearchPrice OR SearchPrice IS NULL)
        ORDER BY P.Price ASC;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE BKShop.SearchMouse(
    IN SearchConnection VARCHAR(255), 
    IN SearchLED VARCHAR(255),   
    IN SearchDPI INT,
    IN SearchPrice INT
)
BEGIN
    SELECT * FROM BKShop.Product P
    JOIN BKShop.Electronic_Accessories E_A ON P.ID = E_A.ID
    JOIN BKShop.Mouse M ON E_A.ID = M.ID
    WHERE 
        (E_A.Connection = SearchConnection OR SearchConnection IS NULL) 
        AND (M.LED_Color = SearchLED OR SearchLED IS NULL)  
        AND (M.DPI = SearchDPI OR SearchDPI IS NULL)   
        AND (P.Price <= SearchPrice OR SearchPrice IS NULL)
    ORDER BY P.Price ASC; 
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE BKShop.SearchKeyboard(
    IN SearchConnection VARCHAR(255), 
    IN SearchSwitch VARCHAR(255),   
    IN SearchLayout VARCHAR(255),
    IN SearchPrice INT
)
BEGIN
    SELECT * FROM BKShop.Product P
    JOIN BKShop.Electronic_Accessories E_A ON P.ID = E_A.ID
    JOIN BKShop.Keyboard K ON E_A.ID = K.ID
    WHERE 
        (E_A.Connection = SearchConnection OR SearchConnection IS NULL) 
        AND (K.Switch_Type = SearchSwitch OR SearchSwitch IS NULL)  
        AND (K.Layout = SearchLayout OR SearchLayout IS NULL)  
        AND (P.Price <= SearchPrice OR SearchPrice IS NULL)
    ORDER BY P.Price ASC; 
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE BKShop.SearchHeadphone(
    IN SearchConnection VARCHAR(255), 
    IN SearchType VARCHAR(255),
    IN SearchPrice INT
)
BEGIN
    SELECT * FROM BKShop.Product P
    JOIN BKShop.Electronic_Accessories E_A ON P.ID = E_A.ID
    JOIN BKShop.Headphone H ON E_A.ID = H.ID
    WHERE 
        (E_A.Connection = SearchConnection OR SearchConnection IS NULL) 
        AND (H.Type = SearchType OR SearchType IS NULL)   
        AND (P.Price <= SearchPrice OR SearchPrice IS NULL)
    ORDER BY P.Price ASC; 
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE BKShop.UpdatePrice(IN ProductID INT, IN NewPrice INT)
BEGIN
    DECLARE ProductStatus VARCHAR(255);
    DECLARE DiscountID INT;
    DECLARE DiscountPercent INT;
    DECLARE Done INT DEFAULT 0;

    DECLARE DiscountCursor CURSOR FOR
        SELECT D.ID, D.Percent
        FROM BKShop.Discount_Program D JOIN BKShop.Product P ON CURRENT_DATE BETWEEN D.FromDate AND D.ToDate
        WHERE P.ID = ProductID;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET Done = 1;

    SELECT Status INTO ProductStatus FROM BKShop.Product WHERE ID = ProductID;
    UPDATE BKShop.Product SET Price = NewPrice WHERE ID = ProductID;

    IF ProductStatus = '2nd' THEN
        UPDATE BKShop.Product SET Price = ROUND(Price*0.95, 2) WHERE ID = ProductID;
    END IF;

    DELETE FROM BKShop.applies WHERE P_ID = ProductID;
    OPEN DiscountCursor;
    DiscountLoop: LOOP
        FETCH DiscountCursor INTO DiscountID, DiscountPercent;
        IF Done = 1 THEN
            LEAVE DiscountLoop;
        END IF;
		
        INSERT INTO BKShop.applies (P_ID, D_ID, Saving)
        VALUES (ProductID, DiscountID, ROUND(NewPrice*DiscountPercent/100, 2));
        SET NewPrice = NewPrice - ROUND(NewPrice*DiscountPercent/100, 2);
    END LOOP;
    CLOSE DiscountCursor;

    UPDATE BKShop.Product P 
    SET P.Price = P.Price - (SELECT SUM(Saving) FROM BKShop.applies A WHERE A.P_ID = ProductID)
    WHERE P.ID = ProductID;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE BKShop.UpdateDiscount(IN DiscountID INT, IN NewPercent INT)
BEGIN
    DECLARE OldName VARCHAR(255);
    DECLARE OldDescription VARCHAR(255);
    DECLARE OldFromDate DATE;
    DECLARE OldToDate DATE;
    CREATE TEMPORARY TABLE TempHas (B_Name VARCHAR(255));

	INSERT INTO TempHas(B_Name) SELECT B_Name FROM BKShop.has WHERE D_ID = DiscountID;
    SELECT Name, Description, FromDate, ToDate INTO OldName, OldDescription, OldFromDate, OldToDate
    FROM BKShop.Discount_Program WHERE ID = DiscountID;
    
    DELETE FROM BKShop.Discount_Program WHERE ID = DiscountID;
    INSERT INTO BKShop.Discount_Program (ID, Name, Description, FromDate, ToDate, Percent)
    VALUES (DiscountID, OldName, OldDescription, OldFromDate, OldToDate, NewPercent);
    
    INSERT INTO BKShop.has (B_Name, D_ID) SELECT B_Name, DiscountID FROM TempHas;
    DROP TEMPORARY TABLE TempHas;
END$$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION BKShop.IsAvailable(p_Name VARCHAR(255))
RETURNS BOOLEAN 
DETERMINISTIC
BEGIN
    DECLARE isAvailable BOOLEAN DEFAULT FALSE;
    IF EXISTS (SELECT 1 FROM BKShop.Product WHERE Name = p_Name AND (Status = 'New' OR Status = '2nd')) THEN
        SET isAvailable = TRUE;
    ELSE
        SET isAvailable = FALSE;
    END IF;
    RETURN isAvailable;
END$$
DELIMITER ;

INSERT INTO BKShop.Employee (ID, SSN, Name) VALUES
(1, '1372', 'Vũ Song Anh'),
(2, '1831', 'Hồ Công Gia'),
(3, '1019', 'Nguyễn Đức Gia'),
(4, '1297', 'Lê Quốc Bình'),
(5, '1750', 'Trường Vĩnh Cường'),
(6, '1973', 'Lê Thanh Duy'),
(7, '1092', 'Lê Quang Minh'),
(8, '1832', 'Lê Đức Nghĩa'), 
(9, '1293', 'Lý Kim Phong'),
(10, '1738', 'Bùi Võ Công'),
(11, '1532', 'Biện Công Thanh'),
(12, '1435', 'Huỳnh Lan Phương'),
(13, '1418', 'Nguyễn Ngọc Song Thương'),
(14, '1209', 'Phạm Nguyễn Viết Trí'),
(15, '1994', 'Lê Vũ Công Vinh'),
(16, '1874', 'Nguyễn Tôn Vĩnh'),
(17, '1152', 'Phan Quốc Đại'),
(18, '1496', 'Lý Trần Tân'),
(19, '1593', 'Nguyễn Anh Tuyển');
    
INSERT INTO BKShop.Store_Manager (ID) VALUES (1), (2), (3), (4);
INSERT INTO BKShop.Warehouse_Manager (ID) VALUES (5), (6), (7);
INSERT INTO BKShop.Warehouse (Address, Name, Area, WM_ID) VALUES 
('268 Lý Thường Kiệt', 'Kho 1', 1024, 5),
('15/17 Cộng Hòa', 'Kho 2', 1024, 6),
('516 Cách Mạng Tháng 8', 'Kho 3', 1024, 7);

-- DELETE FROM BKShop.Employee WHERE ID = 5;
-- SELECT * FROM bkshop.Warehouse_Manager;

INSERT INTO BKShop.Customer (ID, SSN, Name, Address, Phone) VALUES
(1, '1868', 'Cát Như Khang', '257 Đ. Trần Quang Khải, Phường Tân Định, Quận 1, Hồ Chí Minh, Việt Nam', '0617658325');

CALL BKShop.CreateCustomer('1992', 'Khâu Minh Tiến', 'CC 16 Trường Sơn, Phường 15, Quận 10, Hồ Chí Minh, Việt Nam', '0840848353');
CALL BKShop.CreateCustomer('1621', 'Tuấn Ngọc Hiển', 'Y1B, Hồng Lĩnh, Phường 15, Quận 10, Hồ Chí Minh, Việt Nam', '0378662878');
CALL BKShop.CreateCustomer('1867', 'Ngạc Hải Ðăng', '334 Đ. Tô Hiến Thành, Phường 14, Quận 10, Hồ Chí Minh 700000, Việt Nam', '0714400215');
CALL BKShop.CreateCustomer('1989', 'Sơn Hải Thanh', '68/106C, Đ. Đồng Nai, Phường 15, Quận 10, Hồ Chí Minh, Việt Nam', '0123142298');
CALL BKShop.CreateCustomer('1022', 'Ngũ Quốc Hùng', '318 Đ. Phan Văn Trị, Phường 11, Bình Thạnh, Hồ Chí Minh 70000, Việt Nam', '0848813005');
CALL BKShop.CreateCustomer('1426', 'Giáp Thiện Sinh', '401/40 Bình Lợi, Phường 13, Bình Thạnh, Hồ Chí Minh, Việt Nam', '0871859533');
CALL BKShop.CreateCustomer('1503', 'Bình Hiểu Vân', 'Nguyễn Hiền/6 Tân Lập, Đông Hoà, Dĩ An, Bình Dương, Việt Nam', '0191076511');
CALL BKShop.CreateCustomer('1828', 'Vũ Quốc Huy', '191B/A2, Đường Đặng Đại Độ, Hiệp Hoà, Biên Hòa, Đồng Nai, Việt Nam', '0757652753');
CALL BKShop.CreateCustomer('1157', 'Đôn Xuân Kiên', '167/6A Đ. Chiêu Liêu, Tân Đông Hiệp, Dĩ An, Bình Dương, Việt Nam', '0257878745');
CALL BKShop.CreateCustomer('1581', 'Cống Thế Anh', 'G7/37, Bình Chánh, Hồ Chí Minh, Việt Nam', '0195658735');
CALL BKShop.CreateCustomer('1123', 'Luyện Huy Tường', 'ĐH80, Vĩnh Lộc B, Bình Chánh, Hồ Chí Minh, Việt Nam', '0429454757');
CALL BKShop.CreateCustomer('1652', 'Khương Thành Trung', 'Ấp 1, Bình Chánh, Hồ Chí Minh, Việt Nam', '0692868072');
CALL BKShop.CreateCustomer('1113', 'Đôn Gia Khánh', 'Chung cư Green River, 2225 Đ. Phạm Thế Hiển, Quận 8, Hồ Chí Minh, Việt Nam', '0709045740');
CALL BKShop.CreateCustomer('1414', 'Tống Thùy Dung', '325 Đ. Vành Đai Trong, Bình Trị Đông B, Bình Tân, Hồ Chí Minh 700000, Việt Nam', '0603589699');
CALL BKShop.CreateCustomer('1979', 'Đào Ngọc Ẩn', '193 Đường Số 6, Bình Hưng Hoà B, Bình Tân, Hồ Chí Minh, Việt Nam', '0504937288');
CALL BKShop.CreateCustomer('1249', 'Bình Việt Khoa', 'ĐT825, Đức Hòa Hạ, Bình Chánh, Long An, Việt Nam', '0480651073');
CALL BKShop.CreateCustomer('1871', 'Thoa Thái Minh', '20-34 Liên Khu 4-5, Bình Hưng Hoà B, Bình Tân, Hồ Chí Minh, Việt Nam', '0606507485');
CALL BKShop.CreateCustomer('1602', 'Cai Thanh Huyền', '255/52 Đường Liên Khu 4-5, Bình Hưng Hoà B, Bình Tân, Hồ Chí Minh 70000, Việt Nam', '0736850055');

-- DELETE FROM BKShop.Customer WHERE ID = 1;
-- SELECT * FROM bkshop.Customer;

INSERT INTO BKShop.Discount_Program (ID, Name, Description, FromDate, ToDate, Percent) VALUES
(1, '11-Nov', 'định kì tháng', '2024-11-11', '2026-11-11', 50),
(2, 'black friday', 'ví đen tối', '2024-11-29', '2026-12-02', 50);

-- DELETE FROM BKShop.Discount_Program WHERE ID = 1;
-- SELECT * FROM bkshop.Discount_Program;

INSERT INTO BKShop.Brand (Name) VALUES
('Asus'), ('Logitech'), ('Acer'), ('Dell'), ('Gigabyte'), ('Lenovo'), ('MSI'),
('Steelseries'), ('Corsair'), ('Edifier'), ('Hyperx'), ('Akko'), ('Dare-u'), ('E-dra'), ('Rapoo'), ('Pulsar');

INSERT INTO BKShop.Payment_Method (Type, Description) VALUES
('cash', 'customer pay with cash at store'),
('card', 'customer pay with card at store'),
('e-money', 'customer pay with e banking online');

INSERT INTO BKShop.Product (ID, Name, Price, M_Date, E_Date, Status, B_Name, W_Addr, Image) VALUES
(1001, 'Laptop gaming Lenovo Legion 5 16IRX9 83DG0051VN', 42990000, '2024-11-15', '2026-11-15', 'New', 'Lenovo', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_48385ba1307849189dd774c9d489ddef_grande.png'),
(1002, 'Laptop Acer Swift Go 14 SFG14 73 57FZ', 23490000, '2023-02-28', '2025-02-27', 'New', 'MSI', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/wift-go-ai-2024-gen-2-sfg14-73-71zx_1_ccc2cc55cf11451086e09eac92cae064_ed8a6356d9374b53a4c13abaea1658a8_grande.png'),
(1003, 'Laptop gaming Lenovo Legion 5 16IRX9 83DG004XVN', 10000000, '2024-11-21', '2026-11-21', 'New', 'Lenovo', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_577c6f6219cd41a0b56764d9e66cd06d_grande.png'),
(1004, 'Laptop ASUS Vivobook S 14 OLED S5406MA PP046WS', 24990000, '2024-02-28', '2026-02-27', 'New', 'MSI', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/s5406ma-pp046ws_opi_1__c32544a0a1924215842dca8aaf3df95a_grande.jpg'),
(1005, 'Laptop Lenovo V15 G4 IRU 83A1000RVN', 16490000, '2024-08-04', '2026-08-04', 'New', 'Lenovo', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/83a1000rvn_bcefb3c06c89400db011b7be80e20f01_grande.png'),
(1006, 'Laptop gaming Gigabyte G5 MF F2VN333SH', 19990000, '2024-10-15', '2026-10-15', 'New', 'Gigabyte', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/g5_ge_51vn213sh_9e945568d75145b48fdfb2d3d589bf0b_large_2129e0f3b85842419e9c2f8fe071be74_grande.png'),
(1007, 'Laptop gaming Gigabyte G5 KF E3VN333SH', 23990000, '2023-11-16', '2025-11-15', 'New', 'Gigabyte', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/top-gaming-gigabyte-g5-kf-e3vn333sh-1_8aff817b80a24809acb39e8db8b2f811_72f79966523348d9aecc90d1136edae9_grande.png'),
(1008, 'Laptop gaming Acer Nitro V ANV15 51 76B9', 30990000, '2024-08-27', '2026-08-27', 'New', 'Acer', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/nitro-v_755588bd95514b6386940d73d3951e2d_1024x1024_e1587d0e15b642a2a568f52a8a2829c2_grande.png'),
(1009, 'Laptop gaming ASUS TUF Gaming F15 FX507VU LP315W', 27790000, '2023-04-01', '2025-03-31', 'New', 'Asus', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/14c37b78bc34161b45a87_large_3c00edfcc07d4928b682a0f675620c81_1024x1024_c3f115e37ead4a0e87832b3ae47cb4b5_grande.png'),
(1010, 'Laptop gaming ASUS ROG Zephyrus G14 GA402RK L8072W', 56792000, '2024-07-03', '2026-07-03', 'New', 'Asus', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/sus-rog-zephyrus-g14-ga402rk-l8072w-1_2f1ddd0ca5ec458ba47740eee3f32670_2c77f74723fd4e4abbe5a8c28e978222_grande.png'),
(1011, 'Laptop gaming Acer Nitro 16 Phoenix AN16 41 R60F', 24990000, '2023-09-28', '2025-09-27', 'New', 'Acer', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava1_5a226b37a3db45b98caca9337da40b88_grande.png'),
(1012, 'Laptop gaming Gigabyte AORUS 15 BKF 73VN754SH', 37990000, '2023-06-24', '2025-06-23', 'New', 'Gigabyte', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ing-gigabyte-aorus-15-bkf-73vn754sh-1_04b56f71384745f39540af4808bdd118_d73fc5656fea4c58a45de334f6fec0f3_grande.png'),
(1013, 'Laptop gaming ASUS TUF Gaming F15 FX507VV LP304W', 30490000, '2023-08-22', '2025-08-21', 'New', 'Asus', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_c8a92176125145c5a743e6a836ebef42_grande.png'),
(1014, 'Laptop gaming Gigabyte G5 MF5 52VN353SH', 21990000, '2023-06-26', '2025-06-25', 'New', 'Gigabyte', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_0cdface5f1b24b0e830d63fd5f594e84_grande.png'),
(1015, 'Laptop gaming Acer Nitro V ANV16 41 R7EN', 27490000, '2023-06-19', '2025-06-18', 'New', 'MSI', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_ded8eaa81f5f4850a4f6fea27adc83b2_grande.png'),
(1016, 'Laptop Lenovo ThinkPad X13 Gen 5 21LU004TVN', 39990000, '2023-06-24', '2025-06-23', 'New', 'MSI', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_1c68829547de49f0acd0cf4cf7cb9da3_grande.png'),
(1017, 'Laptop gaming Lenovo LOQ 15ARP9 83JC003YVN', 28890000, '2023-06-05', '2025-06-04', 'New', 'Lenovo', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava-trang_96d26f2b6f5443e78f5ef21b5c6a6b7e_grande.png'),
(1018, 'Laptop gaming Lenovo Legion 5 16IRX9 83DG004YVN', 41990000, '2024-09-14', '2026-09-14', 'New', 'Lenovo', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_cc330f9ffc984c0db1d1d0a342b78e66_grande.png'),
(1019, 'Laptop Dell Inspiron 3530 N3530I716W1 Silver', 22790000, '2023-03-06', '2025-03-05', 'New', 'Dell', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/dell-inspiron-3530_99379d1e575240878fb8cad02396a1ce_grande.png'),
(1020, 'Laptop gaming Gigabyte G5 KF E3PH333SH', 22990000, '2023-09-13', '2025-09-12', 'New', 'Gigabyte', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/g5_ge_51vn213sh_9e945568d75145b48fdfb2d3d589bf0b_large_36dc72b773d942b1a66a60e44e1d3757_grande.png'),
(1021, 'Laptop Lenovo ThinkPad X1 Carbon G12 21KC008MVN', 53990000, '2024-03-26', '2026-03-26', 'New', 'MSI', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_979c41b2a83a4ad6939fd1f3f2d3fbd6_grande.png'),
(1022, 'Laptop Dell Inspiron 15 3530 71011775', 20490000, '2023-01-17', '2025-01-16', 'New', 'Dell', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/71011775_2788e230ef9749c2b30b78de3dd2afe9_1a6e23a361134d7c8384a3ad0503a2fe_grande.png'),
(1023, 'Laptop gaming Acer Predator Helios Neo 14 PHN14 51 96HG', 56990000, '2023-02-17', '2025-02-16', 'New', 'Acer', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_38c16c82bf0843de8a092b99952dd14a_grande.png'),
(1024, 'Laptop gaming Acer Nitro V ANV16 41 R6NA', 32990000, '2024-05-13', '2026-05-13', 'New', 'Acer', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_491b9a92bc484241ad85d6f8bbecbc7d_grande.png'),
(1025, 'Laptop gaming Acer Nitro V ANV15 41 R7AP', 21490000, '2023-03-16', '2025-03-15', 'New', 'Acer', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/acer_nitro_v_15_propanel_anv15-41_-_nh_i_di_n_-_a_nh.qpgsv.002-b1_77d8e9053aee44759c66750dc4547e60_grande.jpg'),
(1026, 'Laptop gaming Acer Predator Helios 300 PH315 55 751D', 30990000, '2023-06-05', '2025-06-04', 'New', 'Acer', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_9e22fefdef4944628d7876311ec29230_grande.png'),
(1027, 'Laptop gaming Gigabyte G6 KF H3VN853SH', 27490000, '2024-03-30', '2026-03-30', 'New', 'Gigabyte', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_81d030b73ea840dca2f009918f3b6a98_grande.png'),
(1028, 'Laptop Dell Inspiron T7430 N7430I58W1 Silver', 21990000, '2023-11-29', '2025-11-28', 'New', 'Dell', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/n7430i58w1_97351009345a4702bf2d4edbf560bc3f_grande.png'),
(1029, 'Laptop gaming Gigabyte AORUS 5 SE4 73VN313SH', 38990000, '2023-09-13', '2025-09-12', 'New', 'Gigabyte', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/gaming-gigabyte-aorus-5-se4-73vn313sh_3e9e0a11f035494dbe479de49769c3da_b5f170352b8f48a69e1956b58dc94074_grande.jpg'),
(1030, 'Laptop gaming ASUS TUF Gaming FA401WV RG062WS', 42490000, '2023-01-17', '2025-01-16', 'New', 'MSI', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ava_dea980b662854ab8a4dd359d3bd8d2b4_grande.png'),
(1031, 'Chuột Pulsar X2 Red', 2490000, '2023-07-13', '2025-07-12', 'New', 'Pulsar', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ezgif-1-50b65a0ec7_50e93b9ed6ae4a5bb444389471be493b_master_5308595cba9c4e6c89d8e532cf1aea22_grande.png'),
(1032, 'Chuột Gaming Asus TUF M4 Wireless', 790000, '2024-09-18', '2026-09-18', 'New', 'Asus', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/tuf-gaming-m4-wireless-02_56fe3b15890748738508eb07f20c43c5_grande.jpg'),
(1033, 'Chuột Logitech MX Anywhere 3 Graphite', 1690000, '2024-11-26', '2026-11-26', 'New', 'Logitech', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/eless_bluetooth_den_910_005992_0001_2_59dc815385ac41b79c0ca274ec999b32_596e9a5a55224b4eb72c536a9f6714aa_grande.jpg'),
(1034, 'Chuột Logitech G Pro X Superlight 2 Dex Wireless Black', 3390000, '2023-07-27', '2025-07-26', 'New', 'Logitech', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/pro-x-superlight-2-dex-black-gal_8e2163b06e86419eb2f99ecb7dccda8f_grande.png'),
(1035, 'Chuột Logitech MX Master 3S Graphite', 2390000, '2024-01-27', '2026-01-26', 'New', 'Logitech', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/mx-master-3s-mouse-top-view-graphite_880f7c80882541c2b4e349b7ed0fa439_de0fb8d222ec49bfb11d909a1f116f7e_grande.png'),
(1036, 'Chuột Pulsar Xlite Wireless V2 Blue', 1790000, '2024-06-30', '2026-06-30', 'New', 'Pulsar', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/wireless-v2-competition-blue-01_320fe5e44110483b8bc1405926b8019c_large_9e85184ec07f489fbaff79825a2230b5_grande.jpg'),
(1037, 'Chuột Corsair M65 RGB Elite White (CH-9309111-AP)', 1490000, '2024-03-16', '2026-03-16', 'New', 'Corsair', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/m65proelite-white-gearvn_9b2b3bcfc3b54e43b4162861f880c41e_grande.jpg'),
(1038, 'Chuột Rapoo không dây VT9 Pro White Orange', 1490000, '2024-02-16', '2026-02-15', 'New', 'Rapoo', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/gearvn-chuot-rapoo-khong-day-vt9-pro-white-orange-1_1e5f4681c4b348edaf014f5c3eac0890_grande.png'),
(1039, 'Chuột Asus Rog Keris Wireless Aimpoint White', 2590000, '2023-06-30', '2025-06-29', 'New', 'Asus', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/2_11b39f50b7fc443485a8ee56b4db6905_grande.jpg'),
(1040, 'Chuột Rapoo MT760 Mini Không Dây Đen', 790000, '2023-09-07', '2025-09-06', 'New', 'Rapoo', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/gearvn-chuot-rapoo-mt760-mini-khong-day-den-1_b58d194a97c545cfa71ca6ae6125a64e_grande.png'),
(1042, 'Bàn phím cơ AKKO 3098N Multi-modes Blue On White TTC Flame Red', 2290000, '2024-10-25', '2026-10-25', 'New', 'Akko', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/phim_9a02ee4b8aef40cfa7d79511fb029d37_7a1d7923d6e947ee82ee6b1c749b8a8d_da58e57f1a004b5b926a32496731f3db_grande.png'),
(1044, 'Bàn phím Rapoo V700-A8 Dark Grey Brown Switch', 1090000, '2024-01-07', '2026-01-06', 'New', 'Rapoo', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/1690514986896_61eb82b1f54948bc897366f53ce2bc99_grande.jpg'),
(1045, 'Bàn phím E-Dra EK312 Alpha Brown Switch', 579000, '2024-03-29', '2026-03-29', 'New', 'E-dra', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/477_ek312_png_ffbfb136554a4a1bb78ba3c59967f083_grande.png'),
(1046, 'Bàn phím AKKO 5108 SE Joy of Life', 2390000, '2023-07-20', '2025-07-19', 'New', 'Akko', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/n_phim_co_khong_day_akko_5108_se_joy_of_life_rgb_hotswap__akko_sw__-_6_ce567fce587f4631836517ca7abf8126_grande.png'),
(1047, 'Bàn phím không dây Logitech MX Keys Mini for Mac - Pale Gray', 2490000, '2024-10-15', '2026-10-15', 'New', 'Logitech', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/mx-keys-mini-top-mac-us_1034b8d26df1443eb7c8e2fb92f10a88_88da75d321094e82b2969d9af9b60dcc_grande.png'),
(1048, 'Bàn phím Rapoo V500 Alloy', 390000, '2024-06-08', '2026-06-08', 'New', 'Rapoo', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/9602_21e9b7c37f5bdc5db1c022c21ba4ca38_78a0f6e0f2194ad59c53c7cc0c377912_7a9519dd934e4aa78f76eb03d4fc2149_grande.jpg'), 
(1050, 'Bàn phím Logitech G512 GX RGB (Clicky)', 1990000, '2023-05-07', '2025-05-06', 'New', 'Logitech', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/thumbphim_f3885b3f5138471a957514abaece8391_e98f818bf36649899e0a0232d0a889b0_grande.png'),
(1051, 'Tai nghe Asus ROG Cetra II Core Moonlight', 1090000, '2023-05-17', '2025-05-16', 'New', 'Asus', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/10249_rog_cetra_ii_core_moonlight_white_2_33df49bdb12244509291cae8c0ecf5a6_medium.jpg'),
(1052, 'Tai nghe Logitech G PRO X 2 LIGHTSPEED White', 4668000, '2024-07-03', '2026-07-03', 'New', 'Logitech', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/keoh8zko_73e0f853672741e89304c1054deb0e78_medium.png'),
(1053, 'Tai nghe Corsair HS80 RGB Wireless', 3790000, '2023-06-26', '2025-06-25', 'New', 'Corsair', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/led_rgb_wireless_ca_9011235_ap_0001_2_436fee75cc8d499e9d7619b9efef8acd_8f3b7e1f606c49b8b209034703d29d54_medium.jpg'),
(1054, 'Tai nghe Logitech G Pro X Gaming Black', 2390000, '2023-05-20', '2025-05-19', 'New', 'Logitech', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/gvn_logitech_prox_79c556630c454086baf1bee06c577ab7_3471d9d886fd4dbe8ab5ae6bed9f4d78_medium.png'),
(1055, 'Tai nghe SteelSeries Arctis Nova 1', 1690000, '2023-05-17', '2025-05-16', 'New', 'Steelseries', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/thumbtainghe-recovered_98cd6388269344c8a5a051edc3609aef_cc8120e49835498aae344671b8018378_medium.gif'),
(1056, 'Tai nghe Edifier Không dây W820NB Xanh Dương', 1050000, '2024-01-29', '2026-01-28', 'New', 'Edifier', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/d14a80cafe9eb5c44dd5e1f826dd9bf_32a5b028d5034e1e8340d24b27aca92b_large_7707b842735d493b859483923c7501b2_medium.png'),
(1057, 'Tai nghe Steelseries Arctis Nova Pro Wireless', 9490000, '2024-10-04', '2026-10-04', 'New', 'Steelseries', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/800_crop-scale_optimize_subsampling-2_85403d08f58e43de8be56cbc40688980_92aaa444113d491c92b3096a44a385f9_medium.png'),
(1058, 'Tai nghe Logitech G733 LIGHTSPEED Wireless Black', 2250000, '2023-09-07', '2025-09-06', 'New', 'Logitech', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/ch-g733-lightspeed-wireless-black-666_2eb1a71d562e4a6d853a0f086723cbe3_f7f15fa3c25c4d6190c05c6db168fbf7_medium.png'),
(1059, 'Tai nghe Corsair HS65 Surround White', 1850000, '2024-03-31', '2026-03-31', 'New', 'Corsair', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/thumbtainghe_dcded1dce11c468fa3b139e9a82b8efd_0b9f408fdc0445d1b1269484afc45aad_medium.png'),
(1060, 'Tai nghe Không dây Logitech Zone 300 Đen', 1450000, '2023-10-01', '2025-09-30', 'New', 'Logitech', '268 Lý Thường Kiệt', '//product.hstatic.net/200000722513/product/icz2qubb_56b4a8177f6f489e91fa2c41e28bf963_medium.png'),
(1061, 'Laptop gaming Lenovo Legion 5 16IRX9 83DG0051VN', 42990000, '2024-11-15', '2026-11-15', 'New', 'Lenovo', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_48385ba1307849189dd774c9d489ddef_grande.png'),
(1062, 'Laptop Acer Swift Go 14 SFG14 73 57FZ', 23490000, '2023-02-28', '2025-02-27', 'New', 'MSI', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/wift-go-ai-2024-gen-2-sfg14-73-71zx_1_ccc2cc55cf11451086e09eac92cae064_ed8a6356d9374b53a4c13abaea1658a8_grande.png'),
(1063, 'Laptop gaming Lenovo Legion 5 16IRX9 83DG004XVN', 38990000, '2024-11-21', '2026-11-21', 'New', 'Lenovo', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_577c6f6219cd41a0b56764d9e66cd06d_grande.png'),
(1064, 'Laptop ASUS Vivobook S 14 OLED S5406MA PP046WS', 24990000, '2024-02-28', '2026-02-27', 'New', 'MSI', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/s5406ma-pp046ws_opi_1__c32544a0a1924215842dca8aaf3df95a_grande.jpg'),
(1065, 'Laptop Lenovo V15 G4 IRU 83A1000RVN', 16490000, '2024-08-04', '2026-08-04', 'New', 'Lenovo', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/83a1000rvn_bcefb3c06c89400db011b7be80e20f01_grande.png'),
(1066, 'Laptop gaming Gigabyte G5 MF F2VN333SH', 19990000, '2024-10-15', '2026-10-15', 'New', 'Gigabyte', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/g5_ge_51vn213sh_9e945568d75145b48fdfb2d3d589bf0b_large_2129e0f3b85842419e9c2f8fe071be74_grande.png'),
(1067, 'Laptop gaming Gigabyte G5 KF E3VN333SH', 23990000, '2023-11-16', '2025-11-15', 'New', 'Gigabyte', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/top-gaming-gigabyte-g5-kf-e3vn333sh-1_8aff817b80a24809acb39e8db8b2f811_72f79966523348d9aecc90d1136edae9_grande.png'),
(1068, 'Laptop gaming Acer Nitro V ANV15 51 76B9', 30990000, '2024-08-27', '2026-08-27', 'New', 'Acer', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/nitro-v_755588bd95514b6386940d73d3951e2d_1024x1024_e1587d0e15b642a2a568f52a8a2829c2_grande.png'),
(1069, 'Laptop gaming ASUS TUF Gaming F15 FX507VU LP315W', 27790000, '2023-04-01', '2025-03-31', 'New', 'Asus', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/14c37b78bc34161b45a87_large_3c00edfcc07d4928b682a0f675620c81_1024x1024_c3f115e37ead4a0e87832b3ae47cb4b5_grande.png'),
(1070, 'Laptop gaming ASUS ROG Zephyrus G14 GA402RK L8072W', 56792000, '2024-07-03', '2026-07-03', 'New', 'Asus', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/sus-rog-zephyrus-g14-ga402rk-l8072w-1_2f1ddd0ca5ec458ba47740eee3f32670_2c77f74723fd4e4abbe5a8c28e978222_grande.png'),
(1071, 'Laptop gaming Acer Nitro 16 Phoenix AN16 41 R60F', 24990000, '2023-09-28', '2025-09-27', 'New', 'Acer', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava1_5a226b37a3db45b98caca9337da40b88_grande.png'),
(1072, 'Laptop gaming Gigabyte AORUS 15 BKF 73VN754SH', 37990000, '2023-06-24', '2025-06-23', 'New', 'Gigabyte', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ing-gigabyte-aorus-15-bkf-73vn754sh-1_04b56f71384745f39540af4808bdd118_d73fc5656fea4c58a45de334f6fec0f3_grande.png'),
(1073, 'Laptop gaming ASUS TUF Gaming F15 FX507VV LP304W', 30490000, '2023-08-22', '2025-08-21', 'New', 'Asus', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_c8a92176125145c5a743e6a836ebef42_grande.png'),
(1074, 'Laptop gaming Gigabyte G5 MF5 52VN353SH', 21990000, '2023-06-26', '2025-06-25', 'New', 'Gigabyte', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_0cdface5f1b24b0e830d63fd5f594e84_grande.png'),
(1075, 'Laptop gaming Acer Nitro V ANV16 41 R7EN', 27490000, '2023-06-19', '2025-06-18', 'New', 'MSI', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_ded8eaa81f5f4850a4f6fea27adc83b2_grande.png'),
(1076, 'Laptop Lenovo ThinkPad X13 Gen 5 21LU004TVN', 39990000, '2023-06-24', '2025-06-23', 'New', 'MSI', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_1c68829547de49f0acd0cf4cf7cb9da3_grande.png'),
(1077, 'Laptop gaming Lenovo LOQ 15ARP9 83JC003YVN', 28890000, '2023-06-05', '2025-06-04', 'New', 'Lenovo', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava-trang_96d26f2b6f5443e78f5ef21b5c6a6b7e_grande.png'),
(1078, 'Laptop gaming Lenovo Legion 5 16IRX9 83DG004YVN', 41990000, '2024-09-14', '2026-09-14', 'New', 'Lenovo', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_cc330f9ffc984c0db1d1d0a342b78e66_grande.png'),
(1079, 'Laptop Dell Inspiron 3530 N3530I716W1 Silver', 22790000, '2023-03-06', '2025-03-05', 'New', 'Dell', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/dell-inspiron-3530_99379d1e575240878fb8cad02396a1ce_grande.png'),
(1080, 'Laptop gaming Gigabyte G5 KF E3PH333SH', 22990000, '2023-09-13', '2025-09-12', 'New', 'Gigabyte', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/g5_ge_51vn213sh_9e945568d75145b48fdfb2d3d589bf0b_large_36dc72b773d942b1a66a60e44e1d3757_grande.png'),
(1081, 'Laptop Lenovo ThinkPad X1 Carbon G12 21KC008MVN', 53990000, '2024-03-26', '2026-03-26', 'New', 'MSI', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_979c41b2a83a4ad6939fd1f3f2d3fbd6_grande.png'),
(1082, 'Laptop Dell Inspiron 15 3530 71011775', 20490000, '2023-01-17', '2025-01-16', 'New', 'Dell', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/71011775_2788e230ef9749c2b30b78de3dd2afe9_1a6e23a361134d7c8384a3ad0503a2fe_grande.png'),
(1083, 'Laptop gaming Acer Predator Helios Neo 14 PHN14 51 96HG', 56990000, '2023-02-17', '2025-02-16', 'New', 'Acer', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_38c16c82bf0843de8a092b99952dd14a_grande.png'),
(1084, 'Laptop gaming Acer Nitro V ANV16 41 R6NA', 32990000, '2024-05-13', '2026-05-13', 'New', 'Acer', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_491b9a92bc484241ad85d6f8bbecbc7d_grande.png'),
(1085, 'Laptop gaming Acer Nitro V ANV15 41 R7AP', 21490000, '2023-03-16', '2025-03-15', 'New', 'Acer', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/acer_nitro_v_15_propanel_anv15-41_-_nh_i_di_n_-_a_nh.qpgsv.002-b1_77d8e9053aee44759c66750dc4547e60_grande.jpg'),
(1086, 'Laptop gaming Acer Predator Helios 300 PH315 55 751D', 30990000, '2023-06-05', '2025-06-04', 'New', 'Acer', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_9e22fefdef4944628d7876311ec29230_grande.png'),
(1087, 'Laptop gaming Gigabyte G6 KF H3VN853SH', 27490000, '2024-03-30', '2026-03-30', 'New', 'Gigabyte', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_81d030b73ea840dca2f009918f3b6a98_grande.png'),
(1088, 'Laptop Dell Inspiron T7430 N7430I58W1 Silver', 21990000, '2023-11-29', '2025-11-28', 'New', 'Dell', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/n7430i58w1_97351009345a4702bf2d4edbf560bc3f_grande.png'),
(1089, 'Laptop gaming Gigabyte AORUS 5 SE4 73VN313SH', 38990000, '2023-09-13', '2025-09-12', 'New', 'Gigabyte', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/gaming-gigabyte-aorus-5-se4-73vn313sh_3e9e0a11f035494dbe479de49769c3da_b5f170352b8f48a69e1956b58dc94074_grande.jpg'),
(1090, 'Laptop gaming ASUS TUF Gaming FA401WV RG062WS', 42490000, '2023-01-17', '2025-01-16', 'New', 'MSI', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ava_dea980b662854ab8a4dd359d3bd8d2b4_grande.png'),
(1091, 'Chuột Pulsar X2 Red', 2490000, '2023-07-13', '2025-07-12', 'New', 'Pulsar', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ezgif-1-50b65a0ec7_50e93b9ed6ae4a5bb444389471be493b_master_5308595cba9c4e6c89d8e532cf1aea22_grande.png'),
(1092, 'Chuột Gaming Asus TUF M4 Wireless', 790000, '2024-09-18', '2026-09-18', 'New', 'Asus', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/tuf-gaming-m4-wireless-02_56fe3b15890748738508eb07f20c43c5_grande.jpg'),
(1093, 'Chuột Logitech MX Anywhere 3 Graphite', 1690000, '2024-11-26', '2026-11-26', 'New', 'Logitech', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/eless_bluetooth_den_910_005992_0001_2_59dc815385ac41b79c0ca274ec999b32_596e9a5a55224b4eb72c536a9f6714aa_grande.jpg'),
(1094, 'Chuột Logitech G Pro X Superlight 2 Dex Wireless Black', 3390000, '2023-07-27', '2025-07-26', 'New', 'Logitech', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/pro-x-superlight-2-dex-black-gal_8e2163b06e86419eb2f99ecb7dccda8f_grande.png'),
(1095, 'Chuột Logitech MX Master 3S Graphite', 2390000, '2024-01-27', '2026-01-26', 'New', 'Logitech', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/mx-master-3s-mouse-top-view-graphite_880f7c80882541c2b4e349b7ed0fa439_de0fb8d222ec49bfb11d909a1f116f7e_grande.png'),
(1096, 'Chuột Pulsar Xlite Wireless V2 Blue', 1790000, '2024-06-30', '2026-06-30', 'New', 'Pulsar', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/wireless-v2-competition-blue-01_320fe5e44110483b8bc1405926b8019c_large_9e85184ec07f489fbaff79825a2230b5_grande.jpg'),
(1097, 'Chuột Corsair M65 RGB Elite White (CH-9309111-AP)', 1490000, '2024-03-16', '2026-03-16', 'New', 'Corsair', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/m65proelite-white-gearvn_9b2b3bcfc3b54e43b4162861f880c41e_grande.jpg'),
(1098, 'Chuột Rapoo không dây VT9 Pro White Orange', 1490000, '2024-02-16', '2026-02-15', 'New', 'Rapoo', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/gearvn-chuot-rapoo-khong-day-vt9-pro-white-orange-1_1e5f4681c4b348edaf014f5c3eac0890_grande.png'),
(1099, 'Chuột Asus Rog Keris Wireless Aimpoint White', 2590000, '2023-06-30', '2025-06-29', 'New', 'Asus', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/2_11b39f50b7fc443485a8ee56b4db6905_grande.jpg'),
(1100, 'Chuột Rapoo MT760 Mini Không Dây Đen', 790000, '2023-09-07', '2025-09-06', 'New', 'Rapoo', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/gearvn-chuot-rapoo-mt760-mini-khong-day-den-1_b58d194a97c545cfa71ca6ae6125a64e_grande.png'),
(1102, 'Bàn phím cơ AKKO 3098N Multi-modes Blue On White TTC Flame Red', 2290000, '2024-10-25', '2026-10-25', 'New', 'Akko', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/phim_9a02ee4b8aef40cfa7d79511fb029d37_7a1d7923d6e947ee82ee6b1c749b8a8d_da58e57f1a004b5b926a32496731f3db_grande.png'),
(1104, 'Bàn phím Rapoo V700-A8 Dark Grey Brown Switch', 1090000, '2024-01-07', '2026-01-06', 'New', 'Rapoo', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/1690514986896_61eb82b1f54948bc897366f53ce2bc99_grande.jpg'),
(1105, 'Bàn phím E-Dra EK312 Alpha Brown Switch', 579000, '2024-03-29', '2026-03-29', 'New', 'E-dra', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/477_ek312_png_ffbfb136554a4a1bb78ba3c59967f083_grande.png'),
(1106, 'Bàn phím AKKO 5108 SE Joy of Life', 2390000, '2023-07-20', '2025-07-19', 'New', 'Akko', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/n_phim_co_khong_day_akko_5108_se_joy_of_life_rgb_hotswap__akko_sw__-_6_ce567fce587f4631836517ca7abf8126_grande.png'),
(1107, 'Bàn phím không dây Logitech MX Keys Mini for Mac - Pale Gray', 2490000, '2024-10-15', '2026-10-15', 'New', 'Logitech', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/mx-keys-mini-top-mac-us_1034b8d26df1443eb7c8e2fb92f10a88_88da75d321094e82b2969d9af9b60dcc_grande.png'),
(1108, 'Bàn phím Rapoo V500 Alloy', 390000, '2024-06-08', '2026-06-08', 'New', 'Rapoo', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/9602_21e9b7c37f5bdc5db1c022c21ba4ca38_78a0f6e0f2194ad59c53c7cc0c377912_7a9519dd934e4aa78f76eb03d4fc2149_grande.jpg'),
(1110, 'Bàn phím Logitech G512 GX RGB (Clicky)', 1990000, '2023-05-07', '2025-05-06', 'New', 'Logitech', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/thumbphim_f3885b3f5138471a957514abaece8391_e98f818bf36649899e0a0232d0a889b0_grande.png'),
(1111, 'Tai nghe Asus ROG Cetra II Core Moonlight', 1090000, '2023-05-17', '2025-05-16', 'New', 'Asus', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/10249_rog_cetra_ii_core_moonlight_white_2_33df49bdb12244509291cae8c0ecf5a6_medium.jpg'),
(1112, 'Tai nghe Logitech G PRO X 2 LIGHTSPEED White', 4668000, '2024-07-03', '2026-07-03', 'New', 'Logitech', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/keoh8zko_73e0f853672741e89304c1054deb0e78_medium.png'),
(1113, 'Tai nghe Corsair HS80 RGB Wireless', 3790000, '2023-06-26', '2025-06-25', 'New', 'Corsair', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/led_rgb_wireless_ca_9011235_ap_0001_2_436fee75cc8d499e9d7619b9efef8acd_8f3b7e1f606c49b8b209034703d29d54_medium.jpg'),
(1114, 'Tai nghe Logitech G Pro X Gaming Black', 2390000, '2023-05-20', '2025-05-19', 'New', 'Logitech', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/gvn_logitech_prox_79c556630c454086baf1bee06c577ab7_3471d9d886fd4dbe8ab5ae6bed9f4d78_medium.png'),
(1115, 'Tai nghe SteelSeries Arctis Nova 1', 1690000, '2023-05-17', '2025-05-16', 'New', 'Steelseries', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/thumbtainghe-recovered_98cd6388269344c8a5a051edc3609aef_cc8120e49835498aae344671b8018378_medium.gif'),
(1116, 'Tai nghe Edifier Không dây W820NB Xanh Dương', 1050000, '2024-01-29', '2026-01-28', 'New', 'Edifier', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/d14a80cafe9eb5c44dd5e1f826dd9bf_32a5b028d5034e1e8340d24b27aca92b_large_7707b842735d493b859483923c7501b2_medium.png'),
(1117, 'Tai nghe Steelseries Arctis Nova Pro Wireless', 9490000, '2024-10-04', '2026-10-04', 'New', 'Steelseries', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/800_crop-scale_optimize_subsampling-2_85403d08f58e43de8be56cbc40688980_92aaa444113d491c92b3096a44a385f9_medium.png'),
(1118, 'Tai nghe Logitech G733 LIGHTSPEED Wireless Black', 2250000, '2023-09-07', '2025-09-06', 'New', 'Logitech', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/ch-g733-lightspeed-wireless-black-666_2eb1a71d562e4a6d853a0f086723cbe3_f7f15fa3c25c4d6190c05c6db168fbf7_medium.png'),
(1119, 'Tai nghe Corsair HS65 Surround White', 1850000, '2024-03-31', '2026-03-31', 'New', 'Corsair', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/thumbtainghe_dcded1dce11c468fa3b139e9a82b8efd_0b9f408fdc0445d1b1269484afc45aad_medium.png'),
(1120, 'Tai nghe Không dây Logitech Zone 300 Đen', 1450000, '2023-10-01', '2025-09-30', 'New', 'Logitech', '15/17 Cộng Hòa', '//product.hstatic.net/200000722513/product/icz2qubb_56b4a8177f6f489e91fa2c41e28bf963_medium.png'),
(1121, 'Laptop gaming Lenovo Legion 5 16IRX9 83DG0051VN', 42990000, '2024-11-15', '2026-11-15', '2nd', 'Lenovo', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_48385ba1307849189dd774c9d489ddef_grande.png'),
(1122, 'Laptop Acer Swift Go 14 SFG14 73 57FZ', 23490000, '2023-02-28', '2025-02-27', '2nd', 'MSI', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/wift-go-ai-2024-gen-2-sfg14-73-71zx_1_ccc2cc55cf11451086e09eac92cae064_ed8a6356d9374b53a4c13abaea1658a8_grande.png'),
(1123, 'Laptop gaming Lenovo Legion 5 16IRX9 83DG004XVN', 38990000, '2024-11-21', '2026-11-21', '2nd', 'Lenovo', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_577c6f6219cd41a0b56764d9e66cd06d_grande.png'),
(1124, 'Laptop ASUS Vivobook S 14 OLED S5406MA PP046WS', 24990000, '2024-02-28', '2026-02-27', '2nd', 'MSI', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/s5406ma-pp046ws_opi_1__c32544a0a1924215842dca8aaf3df95a_grande.jpg'),
(1125, 'Laptop Lenovo V15 G4 IRU 83A1000RVN', 16490000, '2024-08-04', '2026-08-04', '2nd', 'Lenovo', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/83a1000rvn_bcefb3c06c89400db011b7be80e20f01_grande.png'),
(1126, 'Laptop gaming Gigabyte G5 MF F2VN333SH', 19990000, '2024-10-15', '2026-10-15', '2nd', 'Gigabyte', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/g5_ge_51vn213sh_9e945568d75145b48fdfb2d3d589bf0b_large_2129e0f3b85842419e9c2f8fe071be74_grande.png'),
(1127, 'Laptop gaming Gigabyte G5 KF E3VN333SH', 23990000, '2023-11-16', '2025-11-15', '2nd', 'Gigabyte', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/top-gaming-gigabyte-g5-kf-e3vn333sh-1_8aff817b80a24809acb39e8db8b2f811_72f79966523348d9aecc90d1136edae9_grande.png'),
(1128, 'Laptop gaming Acer Nitro V ANV15 51 76B9', 30990000, '2024-08-27', '2026-08-27', '2nd', 'Acer', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/nitro-v_755588bd95514b6386940d73d3951e2d_1024x1024_e1587d0e15b642a2a568f52a8a2829c2_grande.png'),
(1129, 'Laptop gaming ASUS TUF Gaming F15 FX507VU LP315W', 27790000, '2023-04-01', '2025-03-31', '2nd', 'Asus', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/14c37b78bc34161b45a87_large_3c00edfcc07d4928b682a0f675620c81_1024x1024_c3f115e37ead4a0e87832b3ae47cb4b5_grande.png'),
(1130, 'Laptop gaming ASUS ROG Zephyrus G14 GA402RK L8072W', 56792000, '2024-07-03', '2026-07-03', '2nd', 'Asus', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/sus-rog-zephyrus-g14-ga402rk-l8072w-1_2f1ddd0ca5ec458ba47740eee3f32670_2c77f74723fd4e4abbe5a8c28e978222_grande.png'),
(1131, 'Laptop gaming Acer Nitro 16 Phoenix AN16 41 R60F', 24990000, '2023-09-28', '2025-09-27', '2nd', 'Acer', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava1_5a226b37a3db45b98caca9337da40b88_grande.png'),
(1132, 'Laptop gaming Gigabyte AORUS 15 BKF 73VN754SH', 37990000, '2023-06-24', '2025-06-23', '2nd', 'Gigabyte', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ing-gigabyte-aorus-15-bkf-73vn754sh-1_04b56f71384745f39540af4808bdd118_d73fc5656fea4c58a45de334f6fec0f3_grande.png'),
(1133, 'Laptop gaming ASUS TUF Gaming F15 FX507VV LP304W', 30490000, '2023-08-22', '2025-08-21', '2nd', 'Asus', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_c8a92176125145c5a743e6a836ebef42_grande.png'),
(1134, 'Laptop gaming Gigabyte G5 MF5 52VN353SH', 21990000, '2023-06-26', '2025-06-25', '2nd', 'Gigabyte', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_0cdface5f1b24b0e830d63fd5f594e84_grande.png'),
(1135, 'Laptop gaming Acer Nitro V ANV16 41 R7EN', 27490000, '2023-06-19', '2025-06-18', '2nd', 'MSI', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_ded8eaa81f5f4850a4f6fea27adc83b2_grande.png'),
(1136, 'Laptop Lenovo ThinkPad X13 Gen 5 21LU004TVN', 39990000, '2023-06-24', '2025-06-23', '2nd', 'MSI', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_1c68829547de49f0acd0cf4cf7cb9da3_grande.png'),
(1137, 'Laptop gaming Lenovo LOQ 15ARP9 83JC003YVN', 28890000, '2023-06-05', '2025-06-04', '2nd', 'Lenovo', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava-trang_96d26f2b6f5443e78f5ef21b5c6a6b7e_grande.png'),
(1138, 'Laptop gaming Lenovo Legion 5 16IRX9 83DG004YVN', 41990000, '2024-09-14', '2026-09-14', '2nd', 'Lenovo', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_cc330f9ffc984c0db1d1d0a342b78e66_grande.png'),
(1139, 'Laptop Dell Inspiron 3530 N3530I716W1 Silver', 22790000, '2023-03-06', '2025-03-05', '2nd', 'Dell', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/dell-inspiron-3530_99379d1e575240878fb8cad02396a1ce_grande.png'),
(1140, 'Laptop gaming Gigabyte G5 KF E3PH333SH', 22990000, '2023-09-13', '2025-09-12', '2nd', 'Gigabyte', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/g5_ge_51vn213sh_9e945568d75145b48fdfb2d3d589bf0b_large_36dc72b773d942b1a66a60e44e1d3757_grande.png'),
(1141, 'Laptop Lenovo ThinkPad X1 Carbon G12 21KC008MVN', 53990000, '2024-03-26', '2026-03-26', '2nd', 'MSI', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_979c41b2a83a4ad6939fd1f3f2d3fbd6_grande.png'),
(1142, 'Laptop Dell Inspiron 15 3530 71011775', 20490000, '2023-01-17', '2025-01-16', '2nd', 'Dell', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/71011775_2788e230ef9749c2b30b78de3dd2afe9_1a6e23a361134d7c8384a3ad0503a2fe_grande.png'),
(1143, 'Laptop gaming Acer Predator Helios Neo 14 PHN14 51 96HG', 56990000, '2023-02-17', '2025-02-16', '2nd', 'Acer', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_38c16c82bf0843de8a092b99952dd14a_grande.png'),
(1144, 'Laptop gaming Acer Nitro V ANV16 41 R6NA', 32990000, '2024-05-13', '2026-05-13', '2nd', 'Acer', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_491b9a92bc484241ad85d6f8bbecbc7d_grande.png'),
(1145, 'Laptop gaming Acer Nitro V ANV15 41 R7AP', 21490000, '2023-03-16', '2025-03-15', '2nd', 'Acer', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/acer_nitro_v_15_propanel_anv15-41_-_nh_i_di_n_-_a_nh.qpgsv.002-b1_77d8e9053aee44759c66750dc4547e60_grande.jpg'),
(1146, 'Laptop gaming Acer Predator Helios 300 PH315 55 751D', 30990000, '2023-06-05', '2025-06-04', '2nd', 'Acer', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_9e22fefdef4944628d7876311ec29230_grande.png'),
(1147, 'Laptop gaming Gigabyte G6 KF H3VN853SH', 27490000, '2024-03-30', '2026-03-30', '2nd', 'Gigabyte', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_81d030b73ea840dca2f009918f3b6a98_grande.png'),
(1148, 'Laptop Dell Inspiron T7430 N7430I58W1 Silver', 21990000, '2023-11-29', '2025-11-28', '2nd', 'Dell', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/n7430i58w1_97351009345a4702bf2d4edbf560bc3f_grande.png'),
(1149, 'Laptop gaming Gigabyte AORUS 5 SE4 73VN313SH', 38990000, '2023-09-13', '2025-09-12', '2nd', 'Gigabyte', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/gaming-gigabyte-aorus-5-se4-73vn313sh_3e9e0a11f035494dbe479de49769c3da_b5f170352b8f48a69e1956b58dc94074_grande.jpg'),
(1150, 'Laptop gaming ASUS TUF Gaming FA401WV RG062WS', 42490000, '2023-01-17', '2025-01-16', '2nd', 'MSI', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ava_dea980b662854ab8a4dd359d3bd8d2b4_grande.png'),
(1151, 'Chuột Pulsar X2 Red', 2490000, '2023-07-13', '2025-07-12', '2nd', 'Pulsar', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ezgif-1-50b65a0ec7_50e93b9ed6ae4a5bb444389471be493b_master_5308595cba9c4e6c89d8e532cf1aea22_grande.png'),
(1152, 'Chuột Gaming Asus TUF M4 Wireless', 790000, '2024-09-18', '2026-09-18', '2nd', 'Asus', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/tuf-gaming-m4-wireless-02_56fe3b15890748738508eb07f20c43c5_grande.jpg'),
(1153, 'Chuột Logitech MX Anywhere 3 Graphite', 1690000, '2024-11-26', '2026-11-26', '2nd', 'Logitech', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/eless_bluetooth_den_910_005992_0001_2_59dc815385ac41b79c0ca274ec999b32_596e9a5a55224b4eb72c536a9f6714aa_grande.jpg'),
(1154, 'Chuột Logitech G Pro X Superlight 2 Dex Wireless Black', 3390000, '2023-07-27', '2025-07-26', '2nd', 'Logitech', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/pro-x-superlight-2-dex-black-gal_8e2163b06e86419eb2f99ecb7dccda8f_grande.png'),
(1155, 'Chuột Logitech MX Master 3S Graphite', 2390000, '2024-01-27', '2026-01-26', '2nd', 'Logitech', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/mx-master-3s-mouse-top-view-graphite_880f7c80882541c2b4e349b7ed0fa439_de0fb8d222ec49bfb11d909a1f116f7e_grande.png'),
(1156, 'Chuột Pulsar Xlite Wireless V2 Blue', 1790000, '2024-06-30', '2026-06-30', '2nd', 'Pulsar', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/wireless-v2-competition-blue-01_320fe5e44110483b8bc1405926b8019c_large_9e85184ec07f489fbaff79825a2230b5_grande.jpg'),
(1157, 'Chuột Corsair M65 RGB Elite White (CH-9309111-AP)', 1490000, '2024-03-16', '2026-03-16', '2nd', 'Corsair', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/m65proelite-white-gearvn_9b2b3bcfc3b54e43b4162861f880c41e_grande.jpg'),
(1158, 'Chuột Rapoo không dây VT9 Pro White Orange', 1490000, '2024-02-16', '2026-02-15', '2nd', 'Rapoo', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/gearvn-chuot-rapoo-khong-day-vt9-pro-white-orange-1_1e5f4681c4b348edaf014f5c3eac0890_grande.png'),
(1159, 'Chuột Asus Rog Keris Wireless Aimpoint White', 2590000, '2023-06-30', '2025-06-29', '2nd', 'Asus', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/2_11b39f50b7fc443485a8ee56b4db6905_grande.jpg'),
(1160, 'Chuột Rapoo MT760 Mini Không Dây Đen', 790000, '2023-09-07', '2025-09-06', '2nd', 'Rapoo', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/gearvn-chuot-rapoo-mt760-mini-khong-day-den-1_b58d194a97c545cfa71ca6ae6125a64e_grande.png'),
(1162, 'Bàn phím cơ AKKO 3098N Multi-modes Blue On White TTC Flame Red', 2290000, '2024-10-25', '2026-10-25', '2nd', 'Akko', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/phim_9a02ee4b8aef40cfa7d79511fb029d37_7a1d7923d6e947ee82ee6b1c749b8a8d_da58e57f1a004b5b926a32496731f3db_grande.png'),
(1164, 'Bàn phím Rapoo V700-A8 Dark Grey Brown Switch', 1090000, '2024-01-07', '2026-01-06', '2nd', 'Rapoo', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/1690514986896_61eb82b1f54948bc897366f53ce2bc99_grande.jpg'),
(1165, 'Bàn phím E-Dra EK312 Alpha Brown Switch', 579000, '2024-03-29', '2026-03-29', '2nd', 'E-dra', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/477_ek312_png_ffbfb136554a4a1bb78ba3c59967f083_grande.png'),
(1166, 'Bàn phím AKKO 5108 SE Joy of Life', 2390000, '2023-07-20', '2025-07-19', '2nd', 'Akko', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/n_phim_co_khong_day_akko_5108_se_joy_of_life_rgb_hotswap__akko_sw__-_6_ce567fce587f4631836517ca7abf8126_grande.png'),
(1167, 'Bàn phím không dây Logitech MX Keys Mini for Mac - Pale Gray', 2490000, '2024-10-15', '2026-10-15', '2nd', 'Logitech', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/mx-keys-mini-top-mac-us_1034b8d26df1443eb7c8e2fb92f10a88_88da75d321094e82b2969d9af9b60dcc_grande.png'),
(1168, 'Bàn phím Rapoo V500 Alloy', 390000, '2024-06-08', '2026-06-08', '2nd', 'Rapoo', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/9602_21e9b7c37f5bdc5db1c022c21ba4ca38_78a0f6e0f2194ad59c53c7cc0c377912_7a9519dd934e4aa78f76eb03d4fc2149_grande.jpg'),
(1170, 'Bàn phím Logitech G512 GX RGB (Clicky)', 1990000, '2023-05-07', '2025-05-06', '2nd', 'Logitech', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/thumbphim_f3885b3f5138471a957514abaece8391_e98f818bf36649899e0a0232d0a889b0_grande.png'),
(1171, 'Tai nghe Asus ROG Cetra II Core Moonlight', 1090000, '2023-05-17', '2025-05-16', '2nd', 'Asus', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/10249_rog_cetra_ii_core_moonlight_white_2_33df49bdb12244509291cae8c0ecf5a6_medium.jpg'),
(1172, 'Tai nghe Logitech G PRO X 2 LIGHTSPEED White', 4668000, '2024-07-03', '2026-07-03', '2nd', 'Logitech', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/keoh8zko_73e0f853672741e89304c1054deb0e78_medium.png'),
(1173, 'Tai nghe Corsair HS80 RGB Wireless', 3790000, '2023-06-26', '2025-06-25', '2nd', 'Corsair', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/led_rgb_wireless_ca_9011235_ap_0001_2_436fee75cc8d499e9d7619b9efef8acd_8f3b7e1f606c49b8b209034703d29d54_medium.jpg'),
(1174, 'Tai nghe Logitech G Pro X Gaming Black', 2390000, '2023-05-20', '2025-05-19', '2nd', 'Logitech', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/gvn_logitech_prox_79c556630c454086baf1bee06c577ab7_3471d9d886fd4dbe8ab5ae6bed9f4d78_medium.png'),
(1175, 'Tai nghe SteelSeries Arctis Nova 1', 1690000, '2023-05-17', '2025-05-16', '2nd', 'Steelseries', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/thumbtainghe-recovered_98cd6388269344c8a5a051edc3609aef_cc8120e49835498aae344671b8018378_medium.gif'),
(1176, 'Tai nghe Edifier Không dây W820NB Xanh Dương', 1050000, '2024-01-29', '2026-01-28', '2nd', 'Edifier', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/d14a80cafe9eb5c44dd5e1f826dd9bf_32a5b028d5034e1e8340d24b27aca92b_large_7707b842735d493b859483923c7501b2_medium.png'),
(1177, 'Tai nghe Steelseries Arctis Nova Pro Wireless', 9490000, '2024-10-04', '2026-10-04', '2nd', 'Steelseries', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/800_crop-scale_optimize_subsampling-2_85403d08f58e43de8be56cbc40688980_92aaa444113d491c92b3096a44a385f9_medium.png'),
(1178, 'Tai nghe Logitech G733 LIGHTSPEED Wireless Black', 2250000, '2023-09-07', '2025-09-06', '2nd', 'Logitech', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/ch-g733-lightspeed-wireless-black-666_2eb1a71d562e4a6d853a0f086723cbe3_f7f15fa3c25c4d6190c05c6db168fbf7_medium.png'),
(1179, 'Tai nghe Corsair HS65 Surround White', 1850000, '2024-03-31', '2026-03-31', '2nd', 'Corsair', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/thumbtainghe_dcded1dce11c468fa3b139e9a82b8efd_0b9f408fdc0445d1b1269484afc45aad_medium.png'),
(1180, 'Tai nghe Không dây Logitech Zone 300 Đen', 1450000, '2023-10-01', '2025-09-30', '2nd', 'Logitech', '516 Cách Mạng Tháng 8', '//product.hstatic.net/200000722513/product/icz2qubb_56b4a8177f6f489e91fa2c41e28bf963_medium.png');

INSERT INTO BKShop.Laptop (ID, RAM, CPU, Graphic_Card, Purpose) VALUES
(1001, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1002, 16, 'Core ultra', 'Intel Arc', 'Gaming'),
(1003, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1004, 16, 'Core ultra', 'Intel Arc', 'Gaming'),
(1005, 8, 'Core i5', 'Integrated Graphics Card', 'Office'),
(1006, 8, 'Core i5', 'NVDIA  4050', 'Gaming'),
(1007, 8, 'Core i5', 'NVDIA  4060', 'Gaming'),
(1008, 16, 'Core i7', 'NVDIA  4050', 'Gaming'),
(1009, 16, 'Core i7', 'NVDIA  4050', 'Gaming'),
(1010, 32, 'Ryzen 9', 'AMD Radeon', 'Gaming'),
(1011, 8, 'Ryzen 7', 'NVDIA  4050', 'Gaming'),
(1012, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1013, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1014, 16, 'Core i5', 'NVDIA  4050', 'Gaming'),
(1015, 16, 'Ryzen 7', 'NVDIA  3050', 'Gaming'),
(1016, 16, 'Core ultra', 'Integrated Graphics Card', 'Gaming'),
(1017, 24, 'Ryzen 7', 'NVDIA  4060', 'Gaming'),
(1018, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1019, 16, 'Core i7', 'NVDIA  550', 'Office'),
(1020, 8, 'Core i5', 'NVDIA  4060', 'Gaming'),
(1021, 16, 'Core ultra', 'Integrated Graphics Card', 'Gaming'),
(1022, 8, 'Core i7', 'Integrated Graphics Card', 'Office'),
(1023, 32, 'Core ultra', 'NVDIA  4070', 'Gaming'),
(1024, 16, 'Ryzen 7', 'NVDIA  4060', 'Gaming'),
(1025, 16, 'Ryzen 5', 'NVDIA  2050', 'Gaming'),
(1026, 16, 'Core i7', 'NVDIA  3070', 'Gaming'),
(1027, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1028, 8, 'Core i5', 'Integrated Graphics Card', 'Office'),
(1029, 16, 'Core i7', 'NVDIA  3070', 'Gaming'),
(1030, 16, 'Ryzen 9', 'NVDIA  4060', 'Gaming'),
(1061, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1062, 16, 'Core ultra', 'Intel Arc', 'Gaming'),
(1063, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1064, 16, 'Core ultra', 'Intel Arc', 'Gaming'),
(1065, 8, 'Core i5', 'Integrated Graphics Card', 'Office'),
(1066, 8, 'Core i5', 'NVDIA  4050', 'Gaming'),
(1067, 8, 'Core i5', 'NVDIA  4060', 'Gaming'),
(1068, 16, 'Core i7', 'NVDIA  4050', 'Gaming'),
(1069, 16, 'Core i7', 'NVDIA  4050', 'Gaming'),
(1070, 32, 'Ryzen 9', 'AMD Radeon', 'Gaming'),
(1071, 8, 'Ryzen 7', 'NVDIA  4050', 'Gaming'),
(1072, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1073, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1074, 16, 'Core i5', 'NVDIA  4050', 'Gaming'),
(1075, 16, 'Ryzen 7', 'NVDIA  3050', 'Gaming'),
(1076, 16, 'Core ultra', 'Integrated Graphics Card', 'Gaming'),
(1077, 24, 'Ryzen 7', 'NVDIA  4060', 'Gaming'),
(1078, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1079, 16, 'Core i7', 'NVDIA  550', 'Office'),
(1080, 8, 'Core i5', 'NVDIA  4060', 'Gaming'),
(1081, 16, 'Core ultra', 'Integrated Graphics Card', 'Gaming'),
(1082, 8, 'Core i7', 'Integrated Graphics Card', 'Office'),
(1083, 32, 'Core ultra', 'NVDIA  4070', 'Gaming'),
(1084, 16, 'Ryzen 7', 'NVDIA  4060', 'Gaming'),
(1085, 16, 'Ryzen 5', 'NVDIA  2050', 'Gaming'),
(1086, 16, 'Core i7', 'NVDIA  3070', 'Gaming'),
(1087, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1088, 8, 'Core i5', 'Integrated Graphics Card', 'Office'),
(1089, 16, 'Core i7', 'NVDIA  3070', 'Gaming'),
(1090, 16, 'Ryzen 9', 'NVDIA  4060', 'Gaming'),
(1121, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1122, 16, 'Core ultra', 'Intel Arc', 'Gaming'),
(1123, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1124, 16, 'Core ultra', 'Intel Arc', 'Gaming'),
(1125, 8, 'Core i5', 'Integrated Graphics Card', 'Office'),
(1126, 8, 'Core i5', 'NVDIA  4050', 'Gaming'),
(1127, 8, 'Core i5', 'NVDIA  4060', 'Gaming'),
(1128, 16, 'Core i7', 'NVDIA  4050', 'Gaming'),
(1129, 16, 'Core i7', 'NVDIA  4050', 'Gaming'),
(1130, 32, 'Ryzen 9', 'AMD Radeon', 'Gaming'),
(1131, 8, 'Ryzen 7', 'NVDIA  4050', 'Gaming'),
(1132, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1133, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1134, 16, 'Core i5', 'NVDIA  4050', 'Gaming'),
(1135, 16, 'Ryzen 7', 'NVDIA  3050', 'Gaming'),
(1136, 16, 'Core ultra', 'Integrated Graphics Card', 'Gaming'),
(1137, 24, 'Ryzen 7', 'NVDIA  4060', 'Gaming'),
(1138, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1139, 16, 'Core i7', 'NVDIA  550', 'Office'),
(1140, 8, 'Core i5', 'NVDIA  4060', 'Gaming'),
(1141, 16, 'Core ultra', 'Integrated Graphics Card', 'Gaming'),
(1142, 8, 'Core i7', 'Integrated Graphics Card', 'Office'),
(1143, 32, 'Core ultra', 'NVDIA  4070', 'Gaming'),
(1144, 16, 'Ryzen 7', 'NVDIA  4060', 'Gaming'),
(1145, 16, 'Ryzen 5', 'NVDIA  2050', 'Gaming'),
(1146, 16, 'Core i7', 'NVDIA  3070', 'Gaming'),
(1147, 16, 'Core i7', 'NVDIA  4060', 'Gaming'),
(1148, 8, 'Core i5', 'Integrated Graphics Card', 'Office'),
(1149, 16, 'Core i7', 'NVDIA  3070', 'Gaming'),
(1150, 16, 'Ryzen 9', 'NVDIA  4060', 'Gaming');

INSERT INTO BKShop.Electronic_Accessories (Connection, ID) VALUES
('Both', 1031),
('Wireless', 1032),
('Wired', 1033),
('Wireless', 1034),
('Both', 1035),
('Both', 1036),
('Wired', 1037),
('Both', 1038),
('Wireless', 1039),
('Wired', 1040),
('Both', 1042),
('Both', 1044),
('Wired', 1045),
('Both', 1046),
('Wireless', 1047),
('Wired', 1048),
('Wired', 1050),
('Wired', 1051),
('Wireless', 1052),
('Wireless', 1053),
('Wired', 1054),
('Wired', 1055),
('Wireless', 1056),
('Wireless', 1057),
('Wireless', 1058),
('Wired', 1059),
('Wireless', 1060),
('Both', 1091),
('Wireless', 1092),
('Wired', 1093),
('Wireless', 1094),
('Both', 1095),
('Both', 1096),
('Wired', 1097),
('Both', 1098),
('Wireless', 1099),
('Wired', 1100),
('Both', 1102),
('Both', 1104),
('Wired', 1105),
('Both', 1106),
('Wireless', 1107),
('Wired', 1108),
('Wired', 1110),
('Wired', 1111),
('Wireless', 1112),
('Wireless', 1113),
('Wired', 1114),
('Wired', 1115),
('Wireless', 1116),
('Wireless', 1117),
('Wireless', 1118),
('Wired', 1119),
('Wireless', 1120),
('Both', 1151),
('Wireless', 1152),
('Wired', 1153),
('Wireless', 1154),
('Both', 1155),
('Both', 1156),
('Wired', 1157),
('Both', 1158),
('Wireless', 1159),
('Wired', 1160),
('Both', 1162),
('Both', 1164),
('Wired', 1165),
('Both', 1166),
('Wireless', 1167),
('Wired', 1168),
('Wired', 1170),
('Wired', 1171),
('Wireless', 1172),
('Wireless', 1173),
('Wired', 1174),
('Wired', 1175),
('Wireless', 1176),
('Wireless', 1177),
('Wireless', 1178),
('Wired', 1179),
('Wireless', 1180);

INSERT INTO BKShop.Mouse (ID, LED_Color, DPI) VALUES
(1031, 'No', 26000),
(1032, 'RGB', 2400),
(1033, 'No', 2400),
(1034, 'No', 44000),
(1035, 'No', 8000),
(1036, 'No', 20000),
(1037, 'No', 2400),
(1038, 'RGB', 26000),
(1039, 'No', 36000),
(1040, 'No', 4000),
(1091, 'No', 26000),
(1092, 'RGB', 2400),
(1093, 'No', 2400),
(1094, 'No', 44000),
(1095, 'No', 8000),
(1096, 'No', 20000),
(1097, 'No', 2400),
(1098, 'RGB', 26000),
(1099, 'No', 36000),
(1100, 'No', 4000),
(1151, 'No', 26000),
(1152, 'RGB', 2400),
(1153, 'No', 2400),
(1154, 'No', 44000),
(1155, 'No', 8000),
(1156, 'No', 20000),
(1157, 'No', 2400),
(1158, 'RGB', 26000),
(1159, 'No', 36000),
(1160, 'No', 4000);

INSERT INTO BKShop.Keyboard (ID, Switch_Type, Layout) VALUES
(1042, 'Linear', 'Fullsize'),
(1044, 'Linear', 'Tenkeyless'),
(1045, 'Tactile', 'Fullsize'),
(1046, 'Linear', 'Fullsize'),
(1047, 'Rubber', 'Fullsize'),
(1048, 'Clicky', 'Fullsize'),
(1050, 'Clicky', 'Fullsize'),
(1102, 'Linear', 'Fullsize'),
(1104, 'Linear', 'Tenkeyless'),
(1105, 'Tactile', 'Fullsize'),
(1106, 'Linear', 'Fullsize'),
(1107, 'Rubber', 'Fullsize'),
(1108, 'Clicky', 'Fullsize'),
(1110, 'Clicky', 'Fullsize'),
(1162, 'Linear', 'Fullsize'),
(1164, 'Linear', 'Tenkeyless'),
(1165, 'Tactile', 'Fullsize'),
(1166, 'Linear', 'Fullsize'),
(1167, 'Rubber', 'Fullsize'),
(1168, 'Clicky', 'Fullsize'),
(1170, 'Clicky', 'Fullsize');

INSERT INTO BKShop.Headphone (Type, ID) VALUES
('In-ear', 1051),
('Earmuffs', 1052), 
('Earmuffs', 1053),
('Earmuffs', 1054),
('Earmuffs', 1055),
('Earmuffs', 1056),
('Earmuffs', 1057),
('Earmuffs', 1058),
('Earmuffs', 1059),
('Earmuffs', 1060),
('In-ear', 1111),
('Earmuffs', 1112),
('Earmuffs', 1113),
('Earmuffs', 1114),
('Earmuffs', 1115),
('Earmuffs', 1116),
('Earmuffs', 1117),
('Earmuffs', 1118),
('Earmuffs', 1119),
('Earmuffs', 1120),
('In-ear', 1171),
('Earmuffs', 1172),
('Earmuffs', 1173),
('Earmuffs', 1174),
('Earmuffs', 1175),
('Earmuffs', 1176),
('Earmuffs', 1177),
('Earmuffs', 1178),
('Earmuffs', 1179),
('Earmuffs', 1180);

-- DELETE FROM BKShop.Product WHERE ID = 1117;
-- SELECT * FROM bkshop.headphone;

-- CALL BKShop.SearchLaptop(16,NULL,NULL,'Gaming', NULL);
-- CALL BKShop.SearchMouse('Wireless', 'RGB', NULL, NULL);
-- CALL BKShop.SearchKeyboard('Wired', 'Clicky', NULL, NULL);
-- CALL BKShop.SearchHeadphone(NULL, NULL, 1111000);

INSERT INTO BKShop.has(B_Name, D_ID) VALUES
('Acer', 1), ('Akko', 1), ('Asus', 1), ('Corsair', 1), ('Dell', 1), ('Edifier', 1), ('E-dra', 1), ('Gigabyte', 1), ('Lenovo', 1),
('Lenovo', 2),
('Logitech', 2), ('MSI', 2), ('Pulsar', 2), ('Rapoo', 2), ('Steelseries', 2);

CALL BKShop.UpdateDiscount(1,79);
CALL BKShop.UpdatePrice(1001,100);

CALL BKShop.AddLaptop(2306, 'baole', 'xxx', 10, '2023-06-26', '2025-06-25', 'New', 'Asus', NULL, NULL, NULL,
					  18, 'abc', 'abc', 'abc');
CALL BKShop.DeleteLaptop('baole', NULL, NULL, NULL, NULL);

SELECT * FROM BKShop.Product WHERE Name = 'Laptop Dell Inspiron T7430 N7430I58W1 Silver' AND 
								   BKShop.IsAvailable('Laptop Dell Inspiron T7430 N7430I58W1 Silver') = TRUE;

-- CALL BKShop.Put2Transaction(1001,1);
-- CALL BKShop.Put2Transaction(1002,1);
-- CALL BKShop.Pop2Transaction(1001);
 
-- UPDATE BKShop.Transaction SET PM_Type = 'cash' WHERE ID = 1;
-- UPDATE BKShop.Transaction SET Status = 'Finished' WHERE ID = 1;

-- CALL BKShop.CreateRequest(1, 1001, 'Exchange', 'No');

-- cập nhật lại database mỗi ngày nên ko cần lo