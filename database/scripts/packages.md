## PACKAGE SPECIFICATION (Public Interface)
```
CREATE OR REPLACE PACKAGE learning_management_pkg AS

    c_min_age CONSTANT NUMBER := 13;
    c_max_score CONSTANT NUMBER := 100;
    c_passing_score CONSTANT NUMBER := 60;
    
    -- Public Types
    TYPE t_learner_summary IS RECORD (
        learner_id NUMBER,
        full_name VARCHAR2(100),
        total_modules NUMBER,
        avg_score NUMBER,
        grade VARCHAR2(2)
    );
    
    -- Public Procedures
    PROCEDURE enroll_learner (
        p_first_name    IN VARCHAR2,
        p_last_name     IN VARCHAR2,
        p_age           IN NUMBER,
        p_email         IN VARCHAR2,
        p_learner_id    OUT NUMBER
    );
    
    PROCEDURE submit_progress (
        p_learner_id    IN NUMBER,
        p_module_id     IN NUMBER,
        p_score         IN NUMBER,
        p_success       OUT BOOLEAN
    );
    
    PROCEDURE generate_certificate (
        p_learner_id    IN NUMBER,
        p_language_id   IN NUMBER,
        p_eligible      OUT BOOLEAN,
        p_message       OUT VARCHAR2
    );
    
    -- Public Functions
    FUNCTION get_learner_summary (
        p_learner_id IN NUMBER
    ) RETURN t_learner_summary;
    
    FUNCTION is_passing_grade (
        p_score IN NUMBER
    ) RETURN BOOLEAN;
    
    FUNCTION calculate_completion_rate (
        p_learner_id IN NUMBER,
        p_language_id IN NUMBER
    ) RETURN NUMBER;
    
END learning_management_pkg;
/
```
## PACKAGE BODY (Implementation)
```
CREATE OR REPLACE PACKAGE BODY learning_management_pkg AS

    -- Private Variables
    g_admin_email VARCHAR2(100) := 'admin@languagelearning.com';
    
    -- Private Function (not visible outside package)
    FUNCTION validate_learner_data (
        p_first_name IN VARCHAR2,
        p_last_name IN VARCHAR2,
        p_age IN NUMBER,
        p_email IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        IF p_first_name IS NULL OR p_last_name IS NULL THEN
            RETURN FALSE;
        END IF;
        
        IF p_age < c_min_age THEN
            RETURN FALSE;
        END IF;
        
        IF p_email NOT LIKE '%@%.%' THEN
            RETURN FALSE;
        END IF;
        
        RETURN TRUE;
    END validate_learner_data;
    
    -- ==========================================
    -- Public Procedure: Enroll Learner
    -- ==========================================
    PROCEDURE enroll_learner (
        p_first_name    IN VARCHAR2,
        p_last_name     IN VARCHAR2,
        p_age           IN NUMBER,
        p_email         IN VARCHAR2,
        p_learner_id    OUT NUMBER
    ) IS
        v_duplicate_count NUMBER;
    BEGIN
        -- Validate using private function
        IF NOT validate_learner_data(p_first_name, p_last_name, p_age, p_email) THEN
            RAISE_APPLICATION_ERROR(-20001, 'Invalid learner data');
        END IF;
        
        -- Check for duplicate email
        SELECT COUNT(*) INTO v_duplicate_count
        FROM LEARNERS
        WHERE email = p_email;
        
        IF v_duplicate_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Email already exists');
        END IF;
        
        -- Insert learner
        INSERT INTO LEARNERS (first_name, last_name, age, email)
        VALUES (p_first_name, p_last_name, p_age, p_email)
        RETURNING learner_id INTO p_learner_id;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('✓ Learner enrolled successfully');
        DBMS_OUTPUT.PUT_LINE('  ID: ' || p_learner_id);
        DBMS_OUTPUT.PUT_LINE('  Name: ' || p_first_name || ' ' || p_last_name);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('✗ Enrollment failed: ' || SQLERRM);
            RAISE;
    END enroll_learner;
    
    -- ==========================================
    -- Public Procedure: Submit Progress
    -- ==========================================
    PROCEDURE submit_progress (
        p_learner_id    IN NUMBER,
        p_module_id     IN NUMBER,
        p_score         IN NUMBER,
        p_success       OUT BOOLEAN
    ) IS
        v_learner_exists NUMBER;
        v_module_exists NUMBER;
    BEGIN
        p_success := FALSE;
        
        -- Validate score
        IF p_score < 0 OR p_score > c_max_score THEN
            RAISE_APPLICATION_ERROR(-20003, 'Score must be between 0 and ' || c_max_score);
        END IF;
        
        -- Validate learner
        SELECT COUNT(*) INTO v_learner_exists
        FROM LEARNERS WHERE learner_id = p_learner_id;
        
        IF v_learner_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Learner not found');
        END IF;
        
        -- Validate module
        SELECT COUNT(*) INTO v_module_exists
        FROM LEARNING_MODULES WHERE module_id = p_module_id;
        
        IF v_module_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Module not found');
        END IF;
        
        -- Insert progress
        INSERT INTO PROGRESS_RECORDS (learner_id, module_id, score)
        VALUES (p_learner_id, p_module_id, p_score);
        
        COMMIT;
        
        p_success := TRUE;
        
        DBMS_OUTPUT.PUT_LINE('✓ Progress submitted successfully');
        DBMS_OUTPUT.PUT_LINE('  Score: ' || p_score);
        DBMS_OUTPUT.PUT_LINE('  Status: ' || CASE WHEN is_passing_grade(p_score) THEN 'PASSED' ELSE 'FAILED' END);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_success := FALSE;
            DBMS_OUTPUT.PUT_LINE('✗ Progress submission failed: ' || SQLERRM);
    END submit_progress;
    
    -- ==========================================
    -- Public Procedure: Generate Certificate
    -- ==========================================
    PROCEDURE generate_certificate (
        p_learner_id    IN NUMBER,
        p_language_id   IN NUMBER,
        p_eligible      OUT BOOLEAN,
        p_message       OUT VARCHAR2
    ) IS
        v_completion_rate NUMBER;
        v_avg_score NUMBER;
        v_learner_name VARCHAR2(100);
        v_language_name VARCHAR2(50);
    BEGIN
        p_eligible := FALSE;
        
        -- Get learner info
        SELECT first_name || ' ' || last_name
        INTO v_learner_name
        FROM LEARNERS
        WHERE learner_id = p_learner_id;
        
        -- Get language name
        SELECT language_name
        INTO v_language_name
        FROM LANGUAGES
        WHERE language_id = p_language_id;
        
        -- Calculate completion rate
        v_completion_rate := calculate_completion_rate(p_learner_id, p_language_id);
        
        -- Calculate average score for this language
        SELECT NVL(AVG(pr.score), 0)
        INTO v_avg_score
        FROM PROGRESS_RECORDS pr
        INNER JOIN LEARNING_MODULES lm ON pr.module_id = lm.module_id
        WHERE pr.learner_id = p_learner_id
        AND lm.language_id = p_language_id;
        
        -- Check eligibility (100% completion + passing grade)
        IF v_completion_rate = 100 AND v_avg_score >= c_passing_score THEN
            p_eligible := TRUE;
            p_message := 'CERTIFICATE OF COMPLETION' || CHR(10) ||
                        '================================' || CHR(10) ||
                        'This certifies that' || CHR(10) ||
                        v_learner_name || CHR(10) ||
                        'has successfully completed' || CHR(10) ||
                        v_language_name || ' Language Course' || CHR(10) ||
                        'with an average score of ' || ROUND(v_avg_score, 2) || '%' || CHR(10) ||
                        'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY');
            
            DBMS_OUTPUT.PUT_LINE(CHR(10) || p_message || CHR(10));
        ELSE
            p_message := 'Not eligible for certificate:' || CHR(10) ||
                        '  Completion: ' || v_completion_rate || '% (Need: 100%)' || CHR(10) ||
                        '  Avg Score: ' || ROUND(v_avg_score, 2) || '% (Need: >= ' || c_passing_score || '%)';
            
            DBMS_OUTPUT.PUT_LINE('✗ ' || p_message);
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_eligible := FALSE;
            p_message := 'Learner or language not found';
            DBMS_OUTPUT.PUT_LINE('✗ ' || p_message);
        WHEN OTHERS THEN
            p_eligible := FALSE;
            p_message := 'Error: ' || SQLERRM;
            DBMS_OUTPUT.PUT_LINE('✗ ' || p_message);
    END generate_certificate;
    
    -- ==========================================
    -- Public Function: Get Learner Summary
    -- ==========================================
    FUNCTION get_learner_summary (
        p_learner_id IN NUMBER
    ) RETURN t_learner_summary IS
        v_summary t_learner_summary;
    BEGIN
        SELECT 
            l.learner_id,
            l.first_name || ' ' || l.last_name,
            COUNT(pr.progress_id),
            NVL(AVG(pr.score), 0),
            get_grade(NVL(AVG(pr.score), 0))
        INTO v_summary
        FROM LEARNERS l
        LEFT JOIN PROGRESS_RECORDS pr ON l.learner_id = pr.learner_id
        WHERE l.learner_id = p_learner_id
        GROUP BY l.learner_id, l.first_name, l.last_name;
        
        RETURN v_summary;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('✗ Error getting summary: ' || SQLERRM);
            RETURN NULL;
    END get_learner_summary;
    
    -- ==========================================
    -- Public Function: Is Passing Grade
    -- ==========================================
    FUNCTION is_passing_grade (
        p_score IN NUMBER
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN p_score >= c_passing_score;
    END is_passing_grade;
    
    -- ==========================================
    -- Public Function: Calculate Completion Rate
    -- ==========================================
    FUNCTION calculate_completion_rate (
        p_learner_id IN NUMBER,
        p_language_id IN NUMBER
    ) RETURN NUMBER IS
        v_total_modules NUMBER;
        v_completed_modules NUMBER;
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
        
        RETURN ROUND((v_completed_modules / v_total_modules) * 100, 2);
        
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END calculate_completion_rate;

END learning_management_pkg;
/
```
