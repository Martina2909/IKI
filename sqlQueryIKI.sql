--prebacivanje na bazu
use StackOverFlow2013;


--provjera stranih kljuèeva
SELECT 
	TABLE_NAME,
	CONSTRAINT_NAME
FROM
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE
	CONSTRAINT_TYPE = 'FOREIGN KEY';


--izrada stranih kljuèeva za tablicu Votes
ALTER TABLE Votes
WITH NOCHECK
ADD
	CONSTRAINT FK_Votes_Posts
	FOREIGN KEY (PostId) REFERENCES Posts(Id),
	CONSTRAINT FK_Votes_Users
	FOREIGN KEY (UserId) REFERENCES Users(Id),
	CONSTRAINT FK_Votes_VoteType
	FOREIGN KEY (VoteTypeId) REFERENCES VoteTypes(Id);


--izrada stranih kljuèeva za tablicu Badges
ALTER TABLE Badges
WITH NOCHECK
ADD
	CONSTRAINT FK_Badges_Users
	FOREIGN KEY (UserId) REFERENCES Users(Id);


--izrada stranih kljuèeva za tablicu Comments
ALTER TABLE Comments
WITH NOCHECK
ADD
	CONSTRAINT FK_Comments_Posts
	FOREIGN KEY (PostId) REFERENCES Posts(Id),
	CONSTRAINT FK_Comments_Users
	FOREIGN KEY (UserId) REFERENCES Users(Id);


--izrada stranih kljuèeva za tablicu Users
ALTER TABLE Users
WITH NOCHECK
ADD
	CONSTRAINT FK_Users_Users
	FOREIGN KEY (AccountId) REFERENCES Users(Id);


--izrada stranih kljuèeva za tablicu Posts
ALTER TABLE Posts
WITH NOCHECK
ADD
	CONSTRAINT FK_Posts_Users_Editor
	FOREIGN KEY (LastEditorUserId) REFERENCES Users(Id),
	CONSTRAINT FK_Posts_UsersOwner
	FOREIGN KEY (OwnerUserId) REFERENCES Users(Id),
	CONSTRAINT FK_Posts_Posts
	FOREIGN KEY (ParentId) REFERENCES Posts(Id),
	CONSTRAINT FK_Posts_PostTypes
	FOREIGN KEY (PostTypeId) REFERENCES PostTypes(Id);


--izrada stranih kljuèeva za tablicu PostLinks
ALTER TABLE PostLinks
WITH NOCHECK
ADD
	CONSTRAINT FK_PostLinks_Posts
	FOREIGN KEY (PostId) REFERENCES Posts(Id),
	CONSTRAINT FK_PostLinks_Posts_Related
	FOREIGN KEY (RelatedPostId) REFERENCES Posts(Id),
	CONSTRAINT FK_PostLinks_LinkTypes
	FOREIGN KEY (LinkTypeId) REFERENCES LinkTypes(Id);


--ponovna provjera stranih kljuèeva
SELECT 
	TABLE_NAME,
	CONSTRAINT_NAME
FROM
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE
	CONSTRAINT_TYPE = 'FOREIGN KEY';


--izrada funkcije GetUserReputation
CREATE FUNCTION GetUserReputation (@UserId INT)
RETURNS INT
AS
BEGIN
    DECLARE @Reputation INT;

    -- Reputacija na temelju svih tipova glasova
    SET @Reputation = (
        SELECT ISNULL(SUM(
            CASE
                WHEN VoteTypeId = 2 THEN 10        -- UpMod (upvote) + 10 bodova
                WHEN VoteTypeId = 3 THEN -2        -- DownMod (downvote) - 2 boda
                WHEN VoteTypeId = 5 THEN 5         -- Favorite + 5 bodova
                WHEN VoteTypeId = 8 THEN -50       -- BountyStart - 50 bodova
                WHEN VoteTypeId = 9 THEN 50        -- BountyClose + 50 bodova
                ELSE 0
            END), 0)
        FROM Votes
        WHERE UserId = @UserId
    );

    -- Dodavanje reputacije na temelju badges
    SET @Reputation = @Reputation + (
        SELECT COUNT(*) * 5       -- Svaki badge daje dodatnih 5 bodova
        FROM Badges
        WHERE UserId = @UserId
    );

    RETURN @Reputation;
END;


--unos u tablicu Users
INSERT INTO Users (AboutMe, Age, CreationDate, DisplayName, DownVotes, EmailHash, LastAccessDate, Location, Reputation, UpVotes, Views, WebsiteUrl, AccountId)
VALUES ('I am Martina', 23, '2024-01-22', 'Tinix', 1, NULL, '2024-11-02', NULL, 100, 5, 20, NULL, 1);


--unos u tablicu Badges
INSERT INTO Badges (Name, UserId, Date)
VALUES ('Student', 10292281, '2024-11-02');


--unos u tablicu Posts
INSERT INTO Posts (AcceptedAnswerId, AnswerCount, Body, ClosedDate, CommentCount, CommunityOwnedDate, CreationDate, FavoriteCount, LastActivityDate, LastEditDate, LastEditorDisplayName, LastEditorUserId, OwnerUserId, ParentId, PostTypeId, Score, Tags, Title, ViewCount)
VALUES (null, null, 'I like video games?', null, null, null, '2024-11-02', 10, '2024-11-02', null, null, null, 10292281, null, 1, 50, null, null, 200);


--unos u tablicu Votes
INSERT INTO Votes (PostId, UserId, BountyAmount, VoteTypeId, CreationDate)
VALUES (21195020, 10292281, null, 5, '2024-11-02');


--izlistanje iz tablice Badges
SELECT * FROM Badges WHERE UserId=10292281;


--izlistanje iz tablice Votes
SELECT * FROM Votes WHERE UserId=10292281;


--provoðenje funkcije
SELECT dbo.GetUserReputation(10292281) AS Reputation;


--izrada okidaèa UpdateReputationOnVote
CREATE TRIGGER UpdateReputationOnVote
ON Votes
AFTER INSERT, DELETE
AS
BEGIN
	DECLARE @UserId INT;

	IF EXISTS (SELECT * FROM inserted)
		SET @UserId = (SELECT UserId FROM inserted);
	ELSE
		SET @UserId = (SELECT UserId FROM deleted);

	UPDATE Users
	SET Reputation = dbo.GetUserReputation(@UserId)
	WHERE Id = @UserId;
END;


--unos u tablicu Votes
INSERT INTO Votes (PostId, UserId, VoteTypeId, CreationDate)
VALUES (4, 10292281, GETDATE());


--provjera reputacije nakon unosa
SELECT Reputation FROM Users WHERE Id = 10292281;


--brisanje unosa iz tablice Votes
DELETE FROM Votes WHERE PostId = 4 AND UserId = 10292281 AND VoteTypeId = 2;


--ponovna provjera reputacije nakon brisanja
SELECT Reputation FROM Users WHERE Id = 10292281;


--izrada procedure CountVotesByPostId
CREATE PROCEDURE CountVotesByPostId
	@PostId INT
AS 
BEGIN
	SELECT VoteTypeId, COUNT(*) AS VoteCount
	FROM Votes WHERE PostId = @PostId
	GROUP BY VoteTypeId;
END;


--provedba procedure
EXEC CountVotesByPostId @PostId = 1;


--provjera toènosti rezultata
SELECT * FROM Votes WHERE PostId = 1;