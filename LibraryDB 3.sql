CREATE DATABASE LibraryDB;
USE LibraryDB;

-- Create 'Book' Table
CREATE TABLE Book (
    BibNumber INT PRIMARY KEY,
    Title VARCHAR(255) NOT NULL,
    Author VARCHAR(255) NOT NULL,
    Publisher VARCHAR(255),
    PublicationYear INT
);

-- Create 'Item' Table
CREATE TABLE Item (
    ItemBarcode VARCHAR(20) PRIMARY KEY,
    BibNumber INT,
    ItemType VARCHAR(50),
    Collection VARCHAR(100),
    CallNumber VARCHAR(50),
    FOREIGN KEY (BibNumber) REFERENCES Book(BibNumber)
);

-- Create 'Transaction' Table
CREATE TABLE Transaction (
    TransactionID INT PRIMARY KEY,
    ItemBarcode VARCHAR(20),
    PatronID INT,
    CheckoutDateTime DATETIME NOT NULL,
    ReturnDateTime DATETIME,
    FOREIGN KEY (ItemBarcode) REFERENCES Item(ItemBarcode)
);

-- Create 'Patron' Table
CREATE TABLE Patron (
    PatronID INT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    ContactInfo VARCHAR(255)
);

-- Example Insert Statements for 'Book' Table
INSERT INTO Book (BibNumber, Title, Author, Publisher, PublicationYear)
VALUES
(1676684, 'Vagabond stars : a world history of Yiddish theater', 'Sandrow, Nahma', 'Syracuse University Press', 1996),
(2524580, 'How to work with an interior designer', 'Sheridan, Judy', 'Gibbs Smith, Publisher', 2008),
(7165, 'The antagonists', 'Gann, Ernest K. (Ernest Kellogg), 1910-1991', 'Simon and Schuster', 1970);

-- Example Insert Statements for 'Item' Table
INSERT INTO Item (ItemBarcode, BibNumber, ItemType, Collection)
VALUES
('Barcode1676684', 1676684, 'acbk', 'canf'),
('Barcode2524580', 2524580, 'acbk', 'canf'),
('Barcode7165', 7165, 'acbk', 'cs3fic');

-- Example Insert Statements for 'Transaction' Table
INSERT INTO Transaction (TransactionID, ItemBarcode, CheckoutDateTime)
VALUES
(1001, '10081815739', '2024-03-02 10:05:00'),
(1002, '10103870761', '2024-03-02 17:51:00'),
(1003, '10108920322', '2024-03-02 11:18:00');

-- Example Insert Statements for 'Patron' Table
INSERT INTO Patron (PatronID, Name, ContactInfo)
VALUES
(1, 'John Doe', 'john.doe@example.com'),
(2, 'Jane Smith', 'jane.smith@example.com');


-- Create Views
-- 1. View for All Details of Books and Their Items
CREATE VIEW BookItemDetails AS
SELECT Book.BibNumber, Book.Title, Book.Author, Book.PublicationYear, Book.Publisher, 
       Item.ItemBarcode, Item.ItemType, Item.Collection, Item.CallNumber
FROM Book JOIN Item ON Book.BibNumber = Item.BibNumber;

-- 2. View for Current Transactions
CREATE VIEW CurrentTransactions AS
SELECT Transaction.TransactionID, Transaction.CheckoutDateTime, Transaction.ReturnDateTime,
       Patron.Name AS PatronName, Patron.ContactInfo, Item.ItemBarcode, Item.BibNumber
FROM Transaction
JOIN Item ON Transaction.ItemBarcode = Item.ItemBarcode
JOIN Patron ON Transaction.PatronID = Patron.PatronID
WHERE Transaction.ReturnDateTime IS NULL;

-- 3. View for Book Checkout History
CREATE VIEW BookCheckoutHistory AS
SELECT Book.BibNumber, Book.Title, COUNT(Transaction.TransactionID) AS CheckoutCount
FROM Book
JOIN Item ON Book.BibNumber = Item.BibNumber
JOIN Transaction ON Item.ItemBarcode = Transaction.ItemBarcode
GROUP BY Book.BibNumber, Book.Title;

-- 4. View for Overdue Items
CREATE VIEW OverdueItems AS
SELECT Item.ItemBarcode, Item.BibNumber, Patron.Name AS PatronName, 
       Transaction.CheckoutDateTime, Transaction.ReturnDateTime
FROM Transaction
JOIN Item ON Transaction.ItemBarcode = Item.ItemBarcode
JOIN Patron ON Transaction.PatronID = Patron.PatronID
WHERE Transaction.ReturnDateTime < CURRENT_DATE AND Transaction.ReturnDateTime IS NOT NULL;

-- 5. View for Patron Activity
CREATE VIEW PatronActivity AS
SELECT Patron.PatronID, Patron.Name, COUNT(Transaction.TransactionID) AS TotalTransactions,
       MAX(Transaction.CheckoutDateTime) AS LastActivityDate
FROM Patron
LEFT JOIN Transaction ON Patron.PatronID = Transaction.PatronID
GROUP BY Patron.PatronID, Patron.Name;

-- 6. View for Available Items
CREATE VIEW AvailableItems AS
SELECT Item.ItemBarcode, Item.BibNumber, Item.ItemType, Item.Collection, Item.CallNumber
FROM Item
LEFT JOIN Transaction ON Item.ItemBarcode = Transaction.ItemBarcode
WHERE Transaction.ItemBarcode IS NULL OR Transaction.ReturnDateTime IS NOT NULL;

-- 7. View for Popular Books
CREATE VIEW PopularBooks AS
SELECT Book.BibNumber, Book.Title, COUNT(Transaction.TransactionID) AS CheckoutCount
FROM Book
JOIN Item ON Book.BibNumber = Item.BibNumber
JOIN Transaction ON Item.ItemBarcode = Transaction.ItemBarcode
GROUP BY Book.BibNumber, Book.Title
ORDER BY CheckoutCount DESC;

-- 8. View for Book Genre Analysis (Assuming 'Subjects' column in 'Book' table)
CREATE VIEW GenreAnalysis AS
SELECT Book.BibNumber, Book.Title, UNNEST(STRING_TO_ARRAY(Book.Subjects, ',')) AS Genre,
       COUNT(Transaction.TransactionID) AS CheckoutCount
FROM Book
JOIN Item ON Book.BibNumber = Item.BibNumber
JOIN Transaction ON Item.ItemBarcode = Transaction.ItemBarcode
GROUP BY Book.BibNumber, Book.Title, Genre;

-- 9. View for Detailed Transaction Records
CREATE VIEW DetailedTransactionRecords AS
SELECT Transaction.TransactionID, Transaction.CheckoutDateTime, Transaction.ReturnDateTime,
       Patron.PatronID, Patron.Name AS PatronName, Item.ItemBarcode, 
       Book.Title, Book.Author
FROM Transaction
JOIN Patron ON Transaction.PatronID = Patron.PatronID
JOIN Item ON Transaction.ItemBarcode = Item.ItemBarcode
JOIN Book ON Item.BibNumber = Book.BibNumber;

-- Exploratory data analysis to find useful insights from the data:
-- 10. View for most popular authors based on the number of checkouts: (Kasturi)
CREATE VIEW PopularAuthors AS
SELECT Author, COUNT(*) AS TotalCheckouts
FROM Book
JOIN Item ON Book.BibNumber = Item.BibNumber
JOIN Transaction ON Item.ItemBarcode = Transaction.ItemBarcode
GROUP BY Author
ORDER BY TotalCheckouts DESC;


-- 11. View for average checkout duration: (Kasturi)
CREATE VIEW AvgCheckoutDuration AS
SELECT AVG(DATEDIFF(ReturnDateTime, CheckoutDateTime)) AS AvgDuration
FROM Transaction
WHERE ReturnDateTime IS NOT NULL;

-- 12. View for the top 10 patrons with the most transactions: (Kasturi)
CREATE VIEW TopPatrons AS
SELECT Patron.PatronID, Name, COUNT(TransactionID) AS TotalTransactions
FROM Transaction
JOIN Patron ON Transaction.PatronID = Patron.PatronID
GROUP BY Patron.PatronID, Name
ORDER BY TotalTransactions DESC
LIMIT 10;

-- 13. View for average number of days between checkout and return for each type of item: (Kasturi)
CREATE VIEW AvgDaysToReturnPerItemType AS
SELECT ItemType, AVG(DATEDIFF(ReturnDateTime, CheckoutDateTime)) AS AvgDaysToReturn
FROM Transaction
JOIN Item ON Transaction.ItemBarcode = Item.ItemBarcode
GROUP BY ItemType;

-- 14. View for the top 10 most borrowed books: (Kasturi)
CREATE VIEW TopBorrowedBooks AS
SELECT Book.BibNumber, Book.Title, COUNT(Transaction.TransactionID) AS TotalBorrowings
FROM Book
JOIN Item ON Book.BibNumber = Item.BibNumber
JOIN Transaction ON Item.ItemBarcode = Transaction.ItemBarcode
GROUP BY Book.BibNumber, Book.Title
ORDER BY TotalBorrowings DESC
LIMIT 10;

-- 15. View to determine the most common publishers in the library: (Kasturi)
CREATE VIEW CommonPublishers AS
SELECT Publisher, COUNT(*) AS TotalBooks
FROM Book
GROUP BY Publisher
ORDER BY TotalBooks DESC;

-- 16. View to identify the top 10 patrons who have checked out the most books: (Kasturi)
CREATE VIEW TopPatronsByCheckoutCount AS
SELECT PatronID, COUNT(*) AS TotalCheckouts
FROM Transaction
GROUP BY PatronID
ORDER BY TotalCheckouts DESC
LIMIT 10;

-- 17. View to identify the most popular collection based on the total number of checkouts: (Kasturi)
CREATE VIEW PopularGenres AS
SELECT Collection, COUNT(*) AS TotalCheckouts
FROM Book
JOIN Item ON Book.BibNumber = Item.BibNumber
JOIN Transaction ON Item.ItemBarcode = Transaction.ItemBarcode
GROUP BY Collection
ORDER BY TotalCheckouts DESC;

-- 18. View to identify the top 10 most borrowed items: (Kasturi)
CREATE VIEW TopBorrowedItems AS
SELECT ItemBarcode, COUNT(TransactionID) AS TotalBorrowings
FROM Transaction
GROUP BY ItemBarcode
ORDER BY TotalBorrowings DESC
LIMIT 10;

-- 19. View to calculate average number of days for which a book is overdue: (Kasturi)
CREATE VIEW AvgDaysOverdue AS
SELECT AVG(DATEDIFF(CURRENT_DATE, ReturnDateTime)) AS AvgDaysOverdue
FROM Transaction
WHERE ReturnDateTime IS NOT NULL AND ReturnDateTime < CURRENT_DATE;

-- 20. View to count number of items in each collectiion: (Thy)
CREATE VIEW NumberofItemsinEachCollection AS
SELECT Collection, COUNT(*) AS ItemCount
FROM Item
GROUP BY Collection;

-- 21. View for patrons who borrowed books published by a specific publisher
CREATE VIEW PatronsforBooksbySpecificPublisher AS
SELECT DISTINCT Patron.*
FROM Patron
INNER JOIN Transaction ON Patron.PatronID = Transaction.PatronID
INNER JOIN Item ON Transaction.ItemBarcode = Item.ItemBarcode
INNER JOIN Book ON Item.BibNumber = Book.BibNumber
WHERE Book.Publisher = 'Publisher Name';

-- 22. View for list of books and number of copies available
CREATE VIEW BooksandNumberofCopiesAvailable AS
SELECT Book.Title, COUNT(Transaction.ItemBarcode) AS CopiesAvailable
FROM Book
LEFT JOIN Item ON Book.BibNumber = Item.BibNumber
LEFT JOIN Transaction ON Item.ItemBarcode = Transaction.ItemBarcode AND Transaction.ReturnDateTime IS NULL
GROUP BY Book.Title;
