## PROCEDURE 1: Generate Learner Report (Explicit Cursor)
### Purpose: Print detailed report for each learner
```
CREATE OR REPLACE PROCEDURE generate_learner_report IS
    -- Explicit cursor definition
    CURSOR c_learners IS
        SELECT 
            l.learner_id,
            l.first_name,
            l.last_name,
            l.age,
            l.email,
            COUNT(pr.progress_id) AS modules_completed,
            NVL(AVG(pr.score), 0) AS avg_score
        FROM LEARNERS l
        LEFT JOIN PROGRESS_RECORDS pr ON l.learner_id = pr.learner_id
        GROUP BY l.learner_id, l.first_name, l.last_name, l.age, l.email
        ORDER BY avg_score DESC;
    
    v_learner_rec c_learners%ROWTYPE;
    v_grade VARCHAR2(2);
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('LEARNER PERFORMANCE REPORT');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Open cursor
    OPEN c_learners;
    
    -- Fetch loop
    LOOP
        FETCH c_learners INTO v_learner_rec;
        EXIT WHEN c_learners%NOTFOUND;
        
        v_count := v_count + 1;
        v_grade := get_grade(v_learner_rec.avg_score);
        
        DBMS_OUTPUT.PUT_LINE('Learner #' || v_count);
        DBMS_OUTPUT.PUT_LINE('  Name: ' || v_learner_rec.first_name || ' ' || v_learner_rec.last_name);
        DBMS_OUTPUT.PUT_LINE('  Age: ' || v_learner_rec.age);
        DBMS_OUTPUT.PUT_LINE('  Email: ' || v_learner_rec.email);
        DBMS_OUTPUT.PUT_LINE('  Modules Completed: ' || v_learner_rec.modules_completed);
        DBMS_OUTPUT.PUT_LINE('  Average Score: ' || ROUND(v_learner_rec.avg_score, 2) || ' (Grade: ' || v_grade || ')');
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    
    -- Close cursor
    CLOSE c_learners;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Total Learners: ' || v_count);
    DBMS_OUTPUT.PUT_LINE('========================================');
    
EXCEPTION
    WHEN OTHERS THEN
        IF c_learners%ISOPEN THEN
            CLOSE c_learners;
        END IF;
        DBMS_OUTPUT.PUT_LINE('✗ Error generating report: ' || SQLERRM);
END generate_learner_report;
/
```
## PROCEDURE 3: Bulk Update Achievement Flags (BULK COLLECT)
### Purpose: Demonstrate bulk operations

```
CREATE OR REPLACE PROCEDURE identify_top_performers (
    p_threshold_score IN NUMBER DEFAULT 90
) IS
    TYPE t_learner_ids IS TABLE OF NUMBER;
    TYPE t_learner_names IS TABLE OF VARCHAR2(100);
    TYPE t_avg_scores IS TABLE OF NUMBER;
    
    v_learner_ids t_learner_ids;
    v_learner_names t_learner_names;
    v_avg_scores t_avg_scores;
    
    -- Cursor for top performers
    CURSOR c_top_performers IS
        SELECT 
            l.learner_id,
            l.first_name || ' ' || l.last_name AS full_name,
            AVG(pr.score) AS avg_score
        FROM LEARNERS l
        INNER JOIN PROGRESS_RECORDS pr ON l.learner_id = pr.learner_id
        GROUP BY l.learner_id, l.first_name, l.last_name
        HAVING AVG(pr.score) >= p_threshold_score
        ORDER BY avg_score DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('TOP PERFORMERS (Score >= ' || p_threshold_score || ')');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Bulk collect into arrays
    OPEN c_top_performers;
    FETCH c_top_performers BULK COLLECT INTO v_learner_ids, v_learner_names, v_avg_scores;
    CLOSE c_top_performers;
    
    -- Process bulk results
    IF v_learner_ids.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No top performers found.');
    ELSE
        FOR i IN 1..v_learner_ids.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('Rank #' || i);
            DBMS_OUTPUT.PUT_LINE('  Learner: ' || v_learner_names(i));
            DBMS_OUTPUT.PUT_LINE('  Average Score: ' || ROUND(v_avg_scores(i), 2));
            DBMS_OUTPUT.PUT_LINE('');
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('Total Top Performers: ' || v_learner_ids.COUNT);
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error identifying top performers: ' || SQLERRM);
END identify_top_performers;
/
```
## PROCEDURE 2: Process Language Statistics (Parameterized Cursor)
### Purpose: Generate stats for each language

```
CREATE OR REPLACE PROCEDURE process_language_stats IS
    -- Parameterized cursor
    CURSOR c_language_stats (p_min_attempts NUMBER) IS
        SELECT 
            l.language_id,
            l.language_name,
            l.difficulty_level,
            COUNT(DISTINCT pr.learner_id) AS unique_learners,
            COUNT(pr.progress_id) AS total_attempts,
            ROUND(AVG(pr.score), 2) AS avg_score,
            MIN(pr.score) AS min_score,
            MAX(pr.score) AS max_score
        FROM LANGUAGES l
        LEFT JOIN LEARNING_MODULES lm ON l.language_id = lm.language_id
        LEFT JOIN PROGRESS_RECORDS pr ON lm.module_id = pr.module_id
        GROUP BY l.language_id, l.language_name, l.difficulty_level
        HAVING COUNT(pr.progress_id) >= p_min_attempts
        ORDER BY total_attempts DESC;
    
    v_stat_rec c_language_stats%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('LANGUAGE STATISTICS REPORT');
    DBMS_OUTPUT.PUT_LINE('(Minimum 5 attempts)');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Open cursor with parameter
    FOR v_stat_rec IN c_language_stats(5) LOOP
        DBMS_OUTPUT.PUT_LINE('Language: ' || v_stat_rec.language_name);
        DBMS_OUTPUT.PUT_LINE('  Difficulty: ' || v_stat_rec.difficulty_level);
        DBMS_OUTPUT.PUT_LINE('  Unique Learners: ' || v_stat_rec.unique_learners);
        DBMS_OUTPUT.PUT_LINE('  Total Attempts: ' || v_stat_rec.total_attempts);
        DBMS_OUTPUT.PUT_LINE('  Average Score: ' || v_stat_rec.avg_score);
        DBMS_OUTPUT.PUT_LINE('  Score Range: ' || v_stat_rec.min_score || ' - ' || v_stat_rec.max_score);
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error processing stats: ' || SQLERRM);
END process_language_stats;
/
```
