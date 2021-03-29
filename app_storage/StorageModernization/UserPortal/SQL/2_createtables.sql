CREATE TABLE Sales (  
    OrderId int,  
    TenantId int,  
    Product varchar(10),  
    Qty int  
);

INSERT Sales VALUES
    (1, 1, 'Valve', 5),
    (2, 1, 'Wheel', 2),
    (3, 1, 'Valve', 4),  
    (4, 2, 'Bracket', 2),
    (5, 2, 'Wheel', 5),
    (6, 2, 'Seat', 5);

--- Grant access to AppUser
GRANT SELECT, INSERT, UPDATE, DELETE ON Sales TO AppUser;  
  
-- Never allow updates on this column by AppUser
DENY UPDATE ON Sales(TenantId) TO AppUser;