/* Query all sales records - only shows for appropriate tenant */
SELECT * FROM Sales;  
GO

/* Query all sales records - only shows for appropriate tenant */
EXECUTE AS USER = 'AppUser';  
EXEC sp_set_session_context @key=N'TenantId', @value=1;  
SELECT * FROM Sales;  
GO  
 
/* Try to query record from another tenant */
EXECUTE AS USER = 'AppUser';  
EXEC sp_set_session_context @key=N'TenantId', @value=1;  
SELECT * FROM Sales WHERE OrderId = 4;  
GO  
  
/*
Note: @read_only prevents the value from changing again until the connection is closed (returned to the connection pool)
Use if your front-end wasn't shared or if each tenant used it's own connection to the DB
*/
EXECUTE AS USER = 'AppUser'; 
EXEC sp_set_session_context @key=N'TenantId', @value=2, @read_only=1;
SELECT * FROM Sales;
GO  
  
/* Try to insert a record with a TenantId that does not match the SESSION_CONTEXT - fails */
EXECUTE AS USER = 'AppUser'; 
EXEC sp_set_session_context @key=N'TenantId', @value=2, @read_only=1;
INSERT INTO Sales VALUES (7, 1, 'Seat', 12); -- error: blocked from inserting row for the wrong user ID  
GO
  
REVERT;  
GO  