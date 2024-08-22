DO
$$
DECLARE
    _r RECORD;
    _i BIGINT;
    _m BIGINT;
BEGIN
    FOR _r IN (
        SELECT 
            relname,
            nspname,
            d.refobjid::regclass,
            a.attname,
            refobjid
        FROM 
            pg_depend d
        JOIN 
            pg_attribute a ON a.attrelid = d.refobjid AND a.attnum = d.refobjsubid
        JOIN 
            pg_class r ON r.oid = objid
        JOIN 
            pg_namespace n ON n.oid = relnamespace
        WHERE  
            d.refobjsubid > 0 
            AND relkind = 'S'
    ) LOOP
        EXECUTE format('SELECT last_value FROM %I.%I', _r.nspname, _r.relname) INTO _i;
        EXECUTE format('SELECT max(%I) FROM %s', _r.attname, _r.refobjid) INTO _m;

        IF coalesce(_m, 0) > _i THEN
            RAISE INFO '%', concat('Changed: ', _r.nspname, '.', _r.relname, ' from:', _i, ' to:', _m);
            EXECUTE format('ALTER SEQUENCE %I.%I RESTART WITH %s', _r.nspname, _r.relname, _m + 1);
        END IF;
    END LOOP;
END;
$$;
