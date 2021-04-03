CREATE SECURITY POLICY Security.SalesFilter  
    ADD FILTER PREDICATE Security.fn_securitypredicate(TenantId)
        ON dbo.Sales,  
    ADD BLOCK PREDICATE Security.fn_securitypredicate(TenantId)
        ON dbo.Sales AFTER INSERT
    WITH (STATE = ON);