# ER Diagram + normalization process + Data dictionary + assumptions + BI considerations

## ER Diagram
<img width="1467" height="820" alt="image" src="https://github.com/user-attachments/assets/ef18a7f1-8da0-4140-8f53-bbe17ceddd40" />
<img width="1454" height="324" alt="image" src="https://github.com/user-attachments/assets/52beee7b-b440-43ee-81d1-5a49d4f89a8c" />

## Normalization Process: From Unnormalized to 3NF
### For 0NF:
```
┌─────────────────────────────────────────────────────┐
│ STUDENT_PROGRESS_SHEET (Unnormalized)              │
├─────────────────────────────────────────────────────┤
│ record_id                                           │
│ learner_name                                        │
│ learner_emails (PROBLEM: "email1, email2")         │
│ modules_completed (PROBLEM: "Mod1, Mod2")          │
│ scores (PROBLEM: "85, 90, 78")                     │
└─────────────────────────────────────────────────────┘
```
### For 1NF:
```
┌─────────────────────────────────────────────────────┐
│ STUDENT_PROGRESS_1NF                                │
├─────────────────────────────────────────────────────┤
│ record_id                                           │
│ learner_name                                        │
│ learner_email (FIXED: One value)                   │
│ module_completed (FIXED: One value)                │
│ score (FIXED: One value)                           │
└─────────────────────────────────────────────────────┘
    ↓ (Still has redundancy)
```
### For 2NF:
```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  LEARNERS    │      │  LANGUAGES   │      │   MODULES    │
├──────────────┤      ├──────────────┤      ├──────────────┤
│ learner_id PK│      │ language_id  │      │ module_id PK │
│ learner_name │      │ language_name│      │ language_id  │
│ learner_email│      │ difficulty   │      │ module_name  │
└──────────────┘      └──────────────┘      └──────────────┘
                                 ↓ FK
         ↓ FK                                    ↓ FK
    ┌────────────────────────────────────────────┐
    │         PROGRESS_2NF                       │
    ├────────────────────────────────────────────┤
    │ progress_id PK                             │
    │ learner_id FK                              │
    │ module_id FK                               │
    │ score                                      │
    └────────────────────────────────────────────┘
```
### For 3NF
```
┌─────────────────────────────────────────┐
│          LEARNERS                       │
├─────────────────────────────────────────┤
│ learner_id (PK)      NUMBER             │
│ first_name           VARCHAR2(50)       │
│ last_name            VARCHAR2(50)       │
│ age                  NUMBER              │
│ email                VARCHAR2(100)      │
│                                          │
│ Constraints:                             │
│ - PK: learner_id                         │
│ - NOT NULL: all columns                  │
│ - UNIQUE: email                          │
│ - CHECK: age >= 13                       │
└─────────────────────────────────────────┘
            │
            │ 1
            │
            │
            │ N
            ▼
┌─────────────────────────────────────────┐
│       PROGRESS_RECORDS                  │
├─────────────────────────────────────────┤
│ progress_id (PK)     NUMBER             │
│ learner_id (FK)      NUMBER             │
│ module_id (FK)       NUMBER             │
│ score                NUMBER              │
│ completion_date      DATE                │
│                                          │
│ Constraints:                             │
│ - PK: progress_id                        │
│ - FK: learner_id → LEARNERS              │
│ - FK: module_id → LEARNING_MODULES       │
│ - CHECK: score >= 0 AND score <= 100    │
│ - DEFAULT: completion_date = SYSDATE    │
└─────────────────────────────────────────┘
            ▲
            │ N
            │
            │
            │ 1
            │
┌─────────────────────────────────────────┐
│       LEARNING_MODULES                  │
├─────────────────────────────────────────┤
│ module_id (PK)       NUMBER             │
│ language_id (FK)     NUMBER             │
│ module_title         VARCHAR2(100)      │
│ module_type          VARCHAR2(30)       │
│                                          │
│ Constraints:                             │
│ - PK: module_id                          │
│ - FK: language_id → LANGUAGES            │
│ - NOT NULL: all columns                  │
│ - CHECK: module_type IN                  │
│   ('Vocabulary','Grammar',               │
│    'Speaking','Listening')               │
└─────────────────────────────────────────┘
            ▲
            │ N
            │
            │
            │ 1
            │
┌─────────────────────────────────────────┐
│          LANGUAGES                      │
├─────────────────────────────────────────┤
│ language_id (PK)     NUMBER             │
│ language_name        VARCHAR2(50)       │
│ difficulty_level     VARCHAR2(20)       │
│                                          │
│ Constraints:                             │
│ - PK: language_id                        │
│ - NOT NULL: all columns                  │
│ - UNIQUE: language_name                  │
│ - CHECK: difficulty_level IN             │
│   ('Beginner','Intermediate',            │
│    'Advanced')                           │
└─────────────────────────────────────────┘
```
## Data Dictionary

### Table 1: LEARNERS

**Purpose:** Stores information about language learners in the system.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| learner_id | NUMBER | PRIMARY KEY, NOT NULL, AUTO_INCREMENT | Unique identifier for each learner |
| first_name | VARCHAR2(50) | NOT NULL | Learner's first name |
| last_name | VARCHAR2(50) | NOT NULL | Learner's last name |
| age | NUMBER | NOT NULL, CHECK (age >= 13) | Learner's age (minimum 13 years) |
| email | VARCHAR2(100) | UNIQUE, NOT NULL | Learner's email address (must be unique) |

**Primary Key:** learner_id  
**Foreign Keys:** None  
**Indexes:** Unique index on email

### Table 2: LANGUAGES

**Purpose:** Stores the catalog of available languages with their difficulty levels.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| language_id | NUMBER | PRIMARY KEY, NOT NULL, AUTO_INCREMENT | Unique identifier for each language |
| language_name | VARCHAR2(50) | UNIQUE, NOT NULL | Name of the language (e.g., French, Spanish) |
| difficulty_level | VARCHAR2(20) | NOT NULL, CHECK (difficulty_level IN ('Beginner', 'Intermediate', 'Advanced')) | Overall difficulty rating of the language |

**Primary Key:** language_id  
**Foreign Keys:** None  
**Indexes:** Unique index on language_name

### Table 3: LEARNING_MODULES

**Purpose:** Stores individual learning modules for each language.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| module_id | NUMBER | PRIMARY KEY, NOT NULL, AUTO_INCREMENT | Unique identifier for each module |
| language_id | NUMBER | FOREIGN KEY, NOT NULL | References LANGUAGES(language_id) |
| module_title | VARCHAR2(100) | NOT NULL | Title of the learning module |
| module_type | VARCHAR2(30) | NOT NULL, CHECK (module_type IN ('Vocabulary', 'Grammar', 'Speaking', 'Listening')) | Type of learning content |

**Primary Key:** module_id  
**Foreign Keys:** 
- language_id REFERENCES LANGUAGES(language_id) ON DELETE CASCADE

**Indexes:** Index on language_id for faster joins

### Table 4: PROGRESS_RECORDS

**Purpose:** Tracks learner performance on completed modules (FACT TABLE for BI).

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| progress_id | NUMBER | PRIMARY KEY, NOT NULL, AUTO_INCREMENT | Unique identifier for each progress record |
| learner_id | NUMBER | FOREIGN KEY, NOT NULL | References LEARNERS(learner_id) |
| module_id | NUMBER | FOREIGN KEY, NOT NULL | References LEARNING_MODULES(module_id) |
| score | NUMBER | NOT NULL, CHECK (score >= 0 AND score <= 100) | Performance score (0-100 percentage) |
| completion_date | DATE | NOT NULL, DEFAULT SYSDATE | Date when module was completed |

**Primary Key:** progress_id  
**Foreign Keys:** 
- learner_id REFERENCES LEARNERS(learner_id) ON DELETE CASCADE
- module_id REFERENCES LEARNING_MODULES(module_id) ON DELETE CASCADE

**Indexes:** 
- Index on learner_id for faster learner-specific queries
- Index on module_id for faster module-specific queries
- Index on completion_date for time-based analytics

**BI Role:** This is the central FACT table containing measurable events (scores, dates)

## Relationship Summary

| Parent Table | Child Table | Relationship Type | Description |
|--------------|-------------|-------------------|-------------|
| LEARNERS | PROGRESS_RECORDS | One-to-Many (1:N) | One learner can have multiple progress records |
| LEARNING_MODULES | PROGRESS_RECORDS | One-to-Many (1:N) | One module can be completed by multiple learners |
| LANGUAGES | LEARNING_MODULES | One-to-Many (1:N) | One language contains multiple modules |

## Key Assumptions

### Business Rules

1. **Minimum Age:** Learners must be at least 13 years old to comply with data protection regulations (COPPA, GDPR).

2. **Email Uniqueness:** Each learner must have a unique email address for identification and communication.

3. **Score Range:** All scores are recorded as percentages from 0 to 100.

4. **Language Difficulty:** Each language is assigned one difficulty level (Beginner, Intermediate, or Advanced) in the current design.

5. **Module Types:** Learning modules are categorized into four types: Vocabulary, Grammar, Speaking, and Listening.

### Data Integrity

6. **Cascading Deletes:** If a language is deleted, all associated modules are deleted. If a learner or module is deleted, all associated progress records are deleted.

7. **No Orphaned Records:** Foreign key constraints prevent progress records without valid learner or module references.

8. **Automatic Timestamps:** Completion dates are automatically set to the current date/time when records are created.

9. **Module Retakes:** Learners can complete the same module multiple times (creates multiple progress records with different scores and dates).

### System Behavior

10. **Performance Threshold:** PL/SQL triggers evaluate scores against a configurable threshold (default: 60%) to identify low performance.

11. **Automatic Evaluation:** Performance analysis is triggered automatically when progress records are inserted or updated via PL/SQL triggers.

12. **Automatic Progress Updates:** Progress summaries and learning trends are automatically updated by stored procedures when new scores are recorded (not calculated on-demand).

13. **Improvement Suggestions:** When a score falls below the threshold, the system automatically generates personalized improvement suggestions.

### Future Extensibility

14. **Multiple Difficulty Levels:** Current design supports one difficulty level per language. To support multiple levels (e.g., French Beginner, French Intermediate), a LANGUAGE_COURSES table could be added without breaking existing tables.

15. **Enhanced Audit Trail:** Future versions may add created_by, modified_by, created_date, and modified_date columns for comprehensive change tracking.
    
## BI Considerations

### Fact vs. Dimension Tables

The database follows a **star schema** pattern for Business Intelligence and analytics:

### Fact Table (Measures & Events)

**PROGRESS_RECORDS** - Central fact table
- **Measures:** `score` (quantitative data)
- **Time Dimension:** `completion_date` (temporal analysis)
- **Foreign Keys:** Links to dimension tables (learner_id, module_id)
- **Grain:** One row per module completion by a learner
- **Aggregations Supported:**
  - SUM(score) - Total points earned
  - AVG(score) - Average performance
  - COUNT(*) - Number of completions
  - MIN(score), MAX(score) - Performance range
  - COUNT(DISTINCT learner_id) - Unique learners

### Dimension Tables (Descriptive Attributes)

**LEARNERS** - "Who" dimension
- Provides learner context (name, age, email)
- Supports filtering by learner demographics
- Used for learner-specific reports

**LANGUAGES** - "What" dimension (Level 1)
- Provides language context (name, difficulty)
- Supports filtering by language or difficulty level
- Used for language comparison analytics

**LEARNING_MODULES** - "What" dimension (Level 2)
- Provides module context (title, type)
- Links to LANGUAGES creating a hierarchy
- Supports filtering by module type or specific modules

### Star Schema Representation

```
        LEARNERS (Dimension)
             |
             | learner_id
             |
             ▼
    PROGRESS_RECORDS (Fact) ◄─── Contains: score, completion_date
             |
             | module_id
             |
             ▼
    LEARNING_MODULES (Dimension)
             |
             | language_id
             |
             ▼
        LANGUAGES (Dimension)
```

---

## Slowly Changing Dimensions (SCD)

Strategy for handling changes to dimension data over time:

### Type 1 SCD: Overwrite (No History)

| Dimension | Attribute | Strategy | Rationale |
|-----------|-----------|----------|-----------|
| LEARNERS | email | Type 1 - Overwrite | Email updates should reflect current contact info; historical emails not needed |
| LEARNERS | age | Type 1 - Overwrite | Current age more relevant; historical age can be recalculated from birth date if needed |
| LANGUAGES | language_name | Type 1 - Overwrite | Language name corrections (typos); rare occurrence |

**Implementation:** Direct UPDATE statement overwrites old value
```sql
UPDATE LEARNERS SET email = 'new@email.com' WHERE learner_id = 1;
```

### Type 2 SCD: Add New Row (Track History)

| Dimension | Attribute | Strategy | Rationale |
|-----------|-----------|----------|-----------|
| LEARNING_MODULES | module_type | Type 2 - Add row | If module type changes, create new module_id to preserve historical progress records |
| LANGUAGES | difficulty_level | Type 2 - Add row | If difficulty rating changes, keep old rating for historical accuracy |

**Implementation:** Insert new row with new effective date
```sql
-- If French difficulty changes from Intermediate to Advanced
-- Keep old row: (1, 'French', 'Intermediate')
-- Add new row: (4, 'French', 'Advanced')
-- Future modules reference language_id = 4
```

**Note:** In current schema, this requires creating a new language_id entry. Future enhancement could add effective_date and expiry_date columns.

### Type 3 SCD: Add New Column (Limited History)

| Dimension | Attribute | Strategy | Rationale |
|-----------|-----------|----------|-----------|
| LEARNERS | name | Type 3 - Add column | Could add previous_name column for name changes while keeping current name |

**Implementation:** Add columns for previous value
```sql
ALTER TABLE LEARNERS ADD previous_email VARCHAR2(100);
```

**Current Design Note:** The system currently implements Type 1 (overwrite) for simplicity. Type 2 can be added in Phase IV by including effective_date and is_current columns.

---

## Aggregation Levels

The database supports multi-dimensional analysis at various levels:

### By Learner (Individual Performance)

**Metrics Available:**
- Average score across all modules: `AVG(score) GROUP BY learner_id`
- Total modules completed: `COUNT(*) GROUP BY learner_id`
- Completion rate: `(modules_completed / total_modules) * 100`
- Learning velocity: `COUNT(*) / DATEDIFF(days) GROUP BY learner_id`
- Best/worst performance: `MAX(score), MIN(score) GROUP BY learner_id`
- Performance trend: `score OVER (PARTITION BY learner_id ORDER BY completion_date)`

### By Language (Language Performance)

**Metrics Available:**
- Average score per language: `AVG(score) by language_name`
- Enrollment count: `COUNT(DISTINCT learner_id) per language`
- Completion rate: Modules completed vs available
- Success rate: Percentage of scores above threshold
- Language popularity: Number of learners enrolled

### By Module (Content Effectiveness)

**Metrics Available:**
- Average score per module: `AVG(score) by module_id`
- Completion count: `COUNT(*) per module`
- Failure rate: Percentage below threshold
- Difficulty assessment: Compare actual scores to expected difficulty
- Module popularity: Number of attempts

### By Module Type (Content Category)

**Metrics Available:**
- Performance by type: Vocabulary vs Grammar vs Speaking vs Listening
- Learner strengths: Which types each learner excels in
- Type popularity: Most/least attempted types

### By Time Period (Trend Analysis)

**Metrics Available:**
- Daily/weekly/monthly activity: `COUNT(*) by date period`
- Performance trends over time: `AVG(score) by month/quarter`
- Peak learning periods: Identify busiest times
- Growth metrics: New learners, new completions over time

### Cross-Dimensional Analysis

**Combined Metrics:**
- Learner + Language: Performance by learner in each language
- Language + Module Type: Which types work best for each language
- Time + Learner: Individual learning velocity trends
- Difficulty + Score: Correlation between difficulty and performance

## Audit Trail Design
**Existing Audit Field:**
- `completion_date` in PROGRESS_RECORDS - Tracks when modules were completed

**Capabilities:**
- Know when learner completed a module
-  Analyze completion patterns over time
-  Calculate learning velocity
-  Cannot track who created/modified records
-  Cannot track what changed in updates
-  Cannot see record modification history
