
## Learner Rankings (ROW_NUMBER, RANK, DENSE_RANK)
### Purpose: Compare different ranking methods
```
SELECT 
    l.learner_id,
    l.first_name || ' ' || l.last_name AS learner_name,
    ROUND(AVG(pr.score), 2) AS avg_score,
    ROW_NUMBER() OVER (ORDER BY AVG(pr.score) DESC) AS row_num,
    RANK() OVER (ORDER BY AVG(pr.score) DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY AVG(pr.score) DESC) AS dense_rank
FROM LEARNERS l
INNER JOIN PROGRESS_RECORDS pr ON l.learner_id = pr.learner_id
GROUP BY l.learner_id, l.first_name, l.last_name
ORDER BY avg_score DESC
FETCH FIRST 15 ROWS ONLY;
```
<img width="1688" height="291" alt="image" src="https://github.com/user-attachments/assets/64fff1ac-a32e-4763-82f2-9de6fb0f01ed" />

## Score Trends (LAG and LEAD)
### Purpose: Compare current score with previous/next attempts

```
SELECT 
    pr.progress_id,
    l.first_name || ' ' || l.last_name AS learner_name,
    lm.module_title,
    pr.score AS current_score,
    LAG(pr.score, 1) OVER (PARTITION BY pr.learner_id ORDER BY pr.completion_date) AS previous_score,
    LEAD(pr.score, 1) OVER (PARTITION BY pr.learner_id ORDER BY pr.completion_date) AS next_score,
    pr.score - LAG(pr.score, 1) OVER (PARTITION BY pr.learner_id ORDER BY pr.completion_date) AS score_improvement,
    pr.completion_date
FROM PROGRESS_RECORDS pr
INNER JOIN LEARNERS l ON pr.learner_id = l.learner_id
INNER JOIN LEARNING_MODULES lm ON pr.module_id = lm.module_id
WHERE pr.learner_id IN (SELECT learner_id FROM LEARNERS WHERE ROWNUM <= 3)
ORDER BY pr.learner_id, pr.completion_date
FETCH FIRST 20 ROWS ONLY;
```
<img width="1796" height="195" alt="image" src="https://github.com/user-attachments/assets/98289e3f-e259-49b9-9cc2-8e25b8fc1887" />

## Performance by Language (PARTITION BY)
### Purpose: Rank learners within each language
```
WITH language_performance AS (
    SELECT 
        lang.language_name,
        l.first_name || ' ' || l.last_name AS learner_name,
        COUNT(pr.progress_id) AS modules_completed,
        ROUND(AVG(pr.score), 2) AS avg_score,
        RANK() OVER (PARTITION BY lang.language_id ORDER BY AVG(pr.score) DESC) AS rank_in_language
    FROM LANGUAGES lang
    INNER JOIN LEARNING_MODULES lm ON lang.language_id = lm.language_id
    INNER JOIN PROGRESS_RECORDS pr ON lm.module_id = pr.module_id
    INNER JOIN LEARNERS l ON pr.learner_id = l.learner_id
    GROUP BY lang.language_id, lang.language_name, l.learner_id, l.first_name, l.last_name
)
SELECT 
    language_name,
    learner_name,
    modules_completed,
    avg_score,
    rank_in_language
FROM language_performance
WHERE rank_in_language <= 3
ORDER BY language_name, rank_in_language;
```
<img width="1646" height="273" alt="image" src="https://github.com/user-attachments/assets/fc45301b-8865-4407-8c29-1052f29e5bb2" />

## Aggregate Window Functions
### Purpose: Show aggregates with OVER clause
```
SELECT 
    lang.language_name,
    lang.difficulty_level,
    COUNT(DISTINCT pr.learner_id) AS unique_learners,
    COUNT(pr.progress_id) AS total_attempts,
    ROUND(AVG(pr.score), 2) AS avg_score,
    ROUND(AVG(AVG(pr.score)) OVER (), 2) AS overall_avg_score,
    ROUND(AVG(pr.score) - AVG(AVG(pr.score)) OVER (), 2) AS difference_from_avg,
    MAX(COUNT(pr.progress_id)) OVER () AS max_attempts_any_language,
    ROUND(RATIO_TO_REPORT(COUNT(pr.progress_id)) OVER () * 100, 2) AS pct_of_total_attempts
FROM LANGUAGES lang
LEFT JOIN LEARNING_MODULES lm ON lang.language_id = lm.language_id
LEFT JOIN PROGRESS_RECORDS pr ON lm.module_id = pr.module_id
GROUP BY lang.language_id, lang.language_name, lang.difficulty_level
HAVING COUNT(pr.progress_id) > 0
ORDER BY total_attempts DESC;
```
<img width="1598" height="228" alt="image" src="https://github.com/user-attachments/assets/d6cf8a7d-8794-445a-848d-bf0b03ca4b3b" />


