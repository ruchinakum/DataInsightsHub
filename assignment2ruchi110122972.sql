-- Create a new database named ADTAssignmentRN
CREATE DATABASE ADTAssignmentRN;

-- Switch to the newly created database ADTAssignmentRN
USE ADTAssignmentRN;

--------------------------------------------TABLE CREATION---------------------------------------------------------

-- Create a table 'program' to store information about academic programs
CREATE TABLE program (
    programID INT PRIMARY KEY,  -- Unique identifier for each program
    name NVARCHAR(255) NOT NULL -- Name of the program
);

-- Create a table 'depCourse' to store information about departmental courses
CREATE TABLE depCourse (
    courseID INT PRIMARY KEY,  --Unique identifier for each course
    deptName NVARCHAR(255) NOT NULL,  -- Name of the department
    programID INT, -- Foreign key linking to the 'program' table
    FOREIGN KEY (programID) REFERENCES program(programID)  -- Establishing a foreign key relationship
);


--Create a table 'users' to store information about users and their associated programs
CREATE TABLE users (
    userID INT PRIMARY KEY,  -- Unique identifier for each user
    programID INT,  -- Foreign key linking to the 'program' table
    FOREIGN KEY (programID) REFERENCES program(programID) -- Establishing a foreign key relationship
);



-- Create a table 'courseSiteVisit' to store information about visits to courses
CREATE TABLE courseSiteVisit (
    visitID INT PRIMARY KEY, -- Unique identifier for each visit
    courseID INT, -- Foreign key linking to the 'depCourse' table
    userID INT, -- Foreign key linking to the 'users' table
    date DATE, -- Date of the visit
    FOREIGN KEY (courseID) REFERENCES depCourse(courseID),   -- Establishing a foreign key relationship
    FOREIGN KEY (userID) REFERENCES users(userID) -- Establishing a foreign key relationship
);


--------------------------------------------DATA INSERTION---------------------------------------------------------

--Insert sample data into the 'program' table
INSERT INTO program (programID, name) VALUES
(1, 'PhD'),
(2, 'Master');

-- Show all courses in the 'program' table after sample data insertion
select * from program;


-- Insert sample data into the 'depCourse' table
INSERT INTO depCourse (courseID, deptName, programID) VALUES
(1, 'Networking', 1),
(2, 'Networking', 2),
(3, 'Systems Programming', 1),
(4, 'Systems Programming', 2);

-- Show all courses in the 'depCourse' table after sample data insertion
select * from depCourse;


--Insert sample data into the 'users' table
INSERT INTO users (userID, programID) VALUES
(1, 1),
(2, 1),
(3, 1),
(4, 2),
(5, 2),
(6, 2);

-- Show all courses in the 'users' table after sample data insertion
select * from users;

--Insert sample data into the 'courseSiteVisit' table
DECLARE @r INT = 1;

WHILE @r <= 100
BEGIN
--Inserting course visit data for different courses and users with random dates
    INSERT INTO courseSiteVisit (visitID, courseID, userID, date) VALUES
    (@r, 1, (SELECT TOP 1 userID FROM users ORDER BY NEWID()), DATEADD(day, ABS(CHECKSUM(NEWID())) % 30, '2023-05-10')),
    (@r + 1, 2, (SELECT TOP 1 userID FROM users ORDER BY NEWID()), DATEADD(day, ABS(CHECKSUM(NEWID())) % 30, '2023-05-10')),
    (@r + 2, 3, (SELECT TOP 1 userID FROM users ORDER BY NEWID()), DATEADD(day, ABS(CHECKSUM(NEWID())) % 30, '2023-05-10')),
    (@r + 3, 4, (SELECT TOP 1 userID FROM users ORDER BY NEWID()), DATEADD(day, ABS(CHECKSUM(NEWID())) % 30, '2023-05-10')),
    (@r + 4, 1, (SELECT TOP 1 userID FROM users ORDER BY NEWID()), DATEADD(day, ABS(CHECKSUM(NEWID())) % 30, '2023-05-10')),
    (@r + 5, 2, (SELECT TOP 1 userID FROM users ORDER BY NEWID()), DATEADD(day, ABS(CHECKSUM(NEWID())) % 30, '2023-05-10')),
    (@r + 6, 3, (SELECT TOP 1 userID FROM users ORDER BY NEWID()), DATEADD(day, ABS(CHECKSUM(NEWID())) % 30, '2023-05-10'));

    SET @r = @r + 7; -- Increment counter
END;

--Show all course visit data
select * from courseSiteVisit;

--------------------------------------------DATA ANALYSIS AND VISUALIZATION---------------------------------------------------------

--- 1. Count the total visits for each course
SELECT
    courseID,
    COUNT(visitID) AS TotalVisits
FROM
    courseSiteVisit
GROUP BY
    courseID;


--- 2. Count the total visits for each course, categorized by program
SELECT
    dc.courseID,
    p.programID,
    COUNT(cv.visitID) AS TotalVisits
FROM
    courseSiteVisit cv
JOIN
    users u ON cv.userID = u.userID
JOIN
    depCourse dc ON cv.courseID = dc.courseID
JOIN
    program p ON u.programID = p.programID
GROUP BY
    dc.courseID, p.programID;


---3. Count the total number of students enrolled in each program
SELECT
    p.programID,
    COUNT(u.userID) AS TotalUsersEnrolled
FROM
    program p
LEFT JOIN
    users u ON p.programID = u.programID
GROUP BY
    p.programID;



---4. Count the total number of unique visitors per department by program
SELECT
    dc.deptName,
    p.programID,
    COUNT(DISTINCT cv.userID) AS UniqueVisitors
FROM
    courseSiteVisit cv
JOIN
    users u ON cv.userID = u.userID
JOIN
    depCourse dc ON cv.courseID = dc.courseID
JOIN
    program p ON u.programID = p.programID
GROUP BY
    dc.deptName, p.programID;


---5. Find the most recent visit date for each user and course
SELECT
    cv.courseID,
    cv.userID,
    MAX(cv.date) AS MostRecentVisitDate
FROM
    courseSiteVisit cv
GROUP BY
    cv.courseID, cv.userID;


---6. Count the number of times each user visited each course
SELECT
    cv.courseID,
    cv.userID,
    COUNT(cv.visitID) AS VisitCount
FROM
    courseSiteVisit cv
GROUP BY
    cv.courseID, cv.userID;



---7. Identify the user who visited each course the most
WITH CourseVisitCounts AS (
    SELECT
        cv.courseID,
        cv.userID,
        COUNT(cv.visitID) AS VisitCount,
        ROW_NUMBER() OVER (PARTITION BY cv.courseID ORDER BY COUNT(cv.visitID) DESC) AS Rank
    FROM
        courseSiteVisit cv
    GROUP BY
        cv.courseID, cv.userID
)

SELECT
    courseID,
    userID,
    VisitCount
FROM
    CourseVisitCounts
WHERE
    Rank = 1;



---8. Identify the user who visited each course the most times in a single day
WITH DailyVisitCounts AS (
    SELECT
        cv.courseID,
        cv.userID,
        cv.date,
        COUNT(cv.visitID) AS VisitCount,
        ROW_NUMBER() OVER (PARTITION BY cv.courseID, cv.date ORDER BY COUNT(cv.visitID) DESC) AS Rank
    FROM
        courseSiteVisit cv
    GROUP BY
        cv.courseID, cv.userID, cv.date
)
SELECT
    courseID,
    userID,
    date,
    VisitCount
FROM
    DailyVisitCounts
WHERE
    Rank = 1;



---9. Calculate the longest visit streak per user per course
WITH UserStreaks AS (
    SELECT
        cv.courseID,
        cv.userID,
        cv.date,
        ROW_NUMBER() OVER (PARTITION BY cv.courseID, cv.userID ORDER BY cv.date) -
        ROW_NUMBER() OVER (PARTITION BY cv.courseID, cv.userID ORDER BY cv.date) AS StreakGroup
    FROM
        courseSiteVisit cv
)

SELECT
    courseID,
    userID,
    MIN(date) AS StreakStartDate,
    MAX(date) AS StreakEndDate,
    DATEDIFF(day, MIN(date), MAX(date)) + 1 AS StreakDuration
FROM
    UserStreaks
GROUP BY
    courseID, userID, StreakGroup
ORDER BY
    courseID, userID, StreakStartDate;



---10.  Identify the longest gap between visits per user and course
WITH UserVisitGaps AS (
    SELECT
        cv.courseID,
        cv.userID,
        cv.date,
        LAG(cv.date) OVER (PARTITION BY cv.courseID, cv.userID ORDER BY cv.date) AS PreviousVisitDate,
        DATEDIFF(day, LAG(cv.date) OVER (PARTITION BY cv.courseID, cv.userID ORDER BY cv.date), cv.date) AS GapDays
    FROM
        courseSiteVisit cv
)

SELECT
    courseID,
    userID,
    MAX(GapDays) AS LongestGap,
    DATEDIFF(day, MIN(date), MAX(date)) + 1 AS TotalDaysInCourse
FROM
    UserVisitGaps
GROUP BY
    courseID, userID;



---11. Identify the user who visited the most courses within a short duration
DECLARE @ShortDurationDays INT = 330; 
WITH UserCourseCounts AS (
    SELECT
        cv.userID,
        COUNT(DISTINCT cv.courseID) AS CoursesVisited
    FROM
        courseSiteVisit cv
    WHERE
        cv.date >= DATEADD(day, -@ShortDurationDays, GETDATE())
    GROUP BY
        cv.userID
)

SELECT TOP 1
    userID,
    CoursesVisited
FROM
    UserCourseCounts
ORDER BY
    CoursesVisited DESC;







