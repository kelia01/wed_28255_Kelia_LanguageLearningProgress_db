CREATE OR REPLACE FUNCTION validate_email (
    p_email IN VARCHAR2
) RETURN BOOLEAN IS
    v_at_count NUMBER;
    v_dot_count NUMBER;
BEGIN
    -- Check for @ symbol
    v_at_count := LENGTH(p_email) - LENGTH(REPLACE(p_email, '@', ''));
    
    -- Check for . after @
    v_dot_count := LENGTH(SUBSTR(p_email, INSTR(p_email, '@'))) - 
                   LENGTH(REPLACE(SUBSTR(p_email, INSTR(p_email, '@')), '.', ''));
    
    -- Valid if exactly one @ and at least one . after @
    IF v_at_count = 1 AND v_dot_count >= 1 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END validate_email;
/
