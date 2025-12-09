CREATE OR REPLACE PROCEDURE register_learner (
    p_first_name    IN VARCHAR2,
    p_last_name     IN VARCHAR2,
    p_age           IN NUMBER,
    p_email         IN VARCHAR2,
    p_learner_id    OUT NUMBER,
    p_status        OUT VARCHAR2
) IS
    v_email_count   NUMBER;
    e_invalid_age   EXCEPTION;
    e_duplicate_email EXCEPTION;
    e_invalid_email EXCEPTION;
BEGIN
    IF p_age < 13 THEN
        RAISE e_invalid_age;
    END IF;
    IF p_email NOT LIKE '%@%.%' THEN
        RAISE e_invalid_email;
    END IF;
    
    -- Check for duplicate email
    SELECT COUNT(*) INTO v_email_count
    FROM LEARNERS
    WHERE email = p_email;
    
    IF v_email_count > 0 THEN
        RAISE e_duplicate_email;
    END IF;
    
    -- Insert new learner (trigger will generate ID)
    INSERT INTO LEARNERS (first_name, last_name, age, email)
    VALUES (p_first_name, p_last_name, p_age, p_email)
    RETURNING learner_id INTO p_learner_id;
    
    COMMIT;
    
    p_status := 'SUCCESS: Learner registered with ID ' || p_learner_id;
    
    DBMS_OUTPUT.PUT_LINE('✓ New learner registered: ' || p_first_name || ' ' || p_last_name);
    DBMS_OUTPUT.PUT_LINE('  Learner ID: ' || p_learner_id);
    
EXCEPTION
    WHEN e_invalid_age THEN
        ROLLBACK;
        p_learner_id := NULL;
        p_status := 'ERROR: Age must be 13 or older';
        DBMS_OUTPUT.PUT_LINE('✗ ' || p_status);
    WHEN e_duplicate_email THEN
        ROLLBACK;
        p_learner_id := NULL;
        p_status := 'ERROR: Email already exists';
        DBMS_OUTPUT.PUT_LINE('✗ ' || p_status);
    WHEN e_invalid_email THEN
        ROLLBACK;
        p_learner_id := NULL;
        p_status := 'ERROR: Invalid email format';
        DBMS_OUTPUT.PUT_LINE('✗ ' || p_status);
    WHEN OTHERS THEN
        ROLLBACK;
        p_learner_id := NULL;
        p_status := 'ERROR: ' || SQLERRM;
        DBMS_OUTPUT.PUT_LINE('✗ Unexpected error: ' || SQLERRM);
END register_learner;
/
