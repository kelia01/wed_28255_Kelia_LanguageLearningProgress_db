CREATE OR REPLACE FUNCTION calculate_progress_percentage (
    p_learner_id IN NUMBER,
    p_language_id IN NUMBER
) RETURN NUMBER IS
    v_total_modules NUMBER;
    v_completed_modules NUMBER;
    v_percentage NUMBER;
BEGIN
    -- Get total modules for language
    SELECT COUNT(*)
    INTO v_total_modules
    FROM LEARNING_MODULES
    WHERE language_id = p_language_id;
    
    IF v_total_modules = 0 THEN
        RETURN 0;
    END IF;
    
    -- Get completed modules
    SELECT COUNT(DISTINCT pr.module_id)
    INTO v_completed_modules
    FROM PROGRESS_RECORDS pr
    INNER JOIN LEARNING_MODULES lm ON pr.module_id = lm.module_id
    WHERE pr.learner_id = p_learner_id
    AND lm.language_id = p_language_id;
    
    -- Calculate percentage
    v_percentage := (v_completed_modules / v_total_modules) * 100;
    
    RETURN ROUND(v_percentage, 2);
    
EXCEPTION
    WHEN ZERO_DIVIDE THEN
        RETURN 0;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
        RETURN 0;
END calculate_progress_percentage;
/
