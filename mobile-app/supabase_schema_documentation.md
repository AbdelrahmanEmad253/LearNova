# Supabase Database Schema Documentation

> **Project Overview**
> This database powers a gamified e-learning platform that supports multiple learning tracks (Foundation, DA, DE, DS). It handles student profiles, course content hierarchy, assessments, gamification (XP, streaks, achievements, leaderboards), AI-driven analytics, chat, notifications, and admin risk management.

---

## Table of Contents

1. [Schema Overview](#schema-overview)
2. [Tables](#tables)
   - [Core User & Auth](#1-core-user--auth)
     - [users](#11-users)
     - [student_profiles](#12-student_profiles)
   - [Course Content Hierarchy](#2-course-content-hierarchy)
     - [courses](#21-courses)
     - [levels](#22-levels)
     - [modules](#23-modules)
     - [topics](#24-topics)
     - [topic_resources](#25-topic_resources)
     - [topic_images](#26-topic_images)
   - [Assessments](#3-assessments)
     - [module_assessments](#31-module_assessments)
     - [module_assessment_questions](#32-module_assessment_questions)
     - [module_assessment_question_images](#33-module_assessment_question_images)
     - [level_assessments](#34-level_assessments)
     - [level_assessment_questions](#35-level_assessment_questions)
   - [Diagnostic System](#4-diagnostic-system)
     - [diagnostic_questions](#41-diagnostic_questions)
     - [diagnostic_question_images](#42-diagnostic_question_images)
     - [calibration_weights](#43-calibration_weights)
     - [diagnostic_test_results](#44-diagnostic_test_results)
   - [Student Activity & Progress](#5-student-activity--progress)
     - [student_progress](#51-student_progress)
     - [student_module_attempts](#52-student_module_attempts)
     - [student_level_attempts](#53-student_level_attempts)
     - [content_engagement_logs](#54-content_engagement_logs)
   - [Gamification](#6-gamification)
     - [user_streaks](#61-user_streaks)
     - [achievements_dictionary](#62-achievements_dictionary)
     - [user_achievements](#63-user_achievements)
     - [leaderboard_snapshots](#64-leaderboard_snapshots)
     - [weekly_challenges](#65-weekly_challenges)
     - [challenge_questions](#66-challenge_questions)
     - [challenge_question_images](#67-challenge_question_images)
     - [student_challenge_attempts](#68-student_challenge_attempts)
   - [AI / ML Analytics](#7-ai--ml-analytics)
     - [ml_daily_metrics](#71-ml_daily_metrics)
     - [ml_topic_daily_metrics](#72-ml_topic_daily_metrics)
     - [student_sentiment_history](#73-student_sentiment_history)
     - [risk_scores](#74-risk_scores)
     - [intervention_logs](#75-intervention_logs)
   - [Chat & RAG System](#8-chat--rag-system)
     - [chat_sessions](#81-chat_sessions)
     - [chat_messages](#82-chat_messages)
     - [document_chunks](#83-document_chunks)
   - [Notifications & Devices](#9-notifications--devices)
     - [in_app_notifications](#91-in_app_notifications)
     - [user_devices](#92-user_devices)
3. [Entity Relationship Summary](#entity-relationship-summary)
4. [Row Level Security (RLS) Summary](#row-level-security-rls-summary)
5. [Database Functions](#database-functions)
6. [Storage Buckets](#storage-buckets)

---

## Schema Overview

The database is organized into **9 functional groups**:

| Group | Tables | Purpose |
|---|---|---|
| Core User & Auth | 2 | Authentication, student profile management |
| Course Content Hierarchy | 6 | Courses → Levels → Modules → Topics and their media |
| Assessments | 5 | Module-level and level-level quizzes with images |
| Diagnostic System | 4 | Onboarding diagnostic tests to calibrate learning style |
| Student Activity & Progress | 4 | Tracking topic completion, quiz attempts, engagement |
| Gamification | 8 | XP, streaks, achievements, leaderboards, weekly challenges |
| AI / ML Analytics | 5 | ML-computed risk scores, decay metrics, sentiment |
| Chat & RAG System | 3 | AI tutor chat with vector-embedded document retrieval |
| Notifications & Devices | 2 | Push notifications, FCM device token management |

---

## Tables

---

### 1. Core User & Auth

#### 1.1 `users`

**Purpose:** The central identity table. Stores every authenticated user (both students and admins). Managed by Supabase Auth — the `handle_new_user` trigger auto-populates this from `auth.users` on signup.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key — matches Supabase `auth.uid()` |
| `email` | `text` | Unique, user's email address |
| `full_name` | `text` | Display name |
| `avatar_url` | `text` | URL to profile picture |
| `role` | `text` | Either `'student'` or `'admin'` (enforced by CHECK constraint) |
| `created_at` | `timestamptz` | Account creation time |
| `last_seen_at` | `timestamptz` | Last platform activity |

**Constraints:**
- `users_pkey` — Primary key on `id`
- `users_email_key` — Unique on `email`
- `users_role_check` — `role IN ('student', 'admin')`

**RLS:**
| Policy | Who | What |
|---|---|---|
| `users: admin read all` | Admin | Can read all user rows |
| `users: student read own` | Student | Can only read their own row |
| `users: student update own` | Student | Can only update their own row |

---

#### 1.2 `student_profiles`

**Purpose:** Extended profile data for students only. One-to-one with `users`. Holds learning preferences, XP total, current level index, Bayesian learning style scores, and exploration mode window.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` (unique — one profile per user) |
| `assigned_track` | `text` | One of `Foundation`, `DA`, `DE`, `DS` |
| `learning_style` | `text` | One of `Visual`, `Auditory`, `Textual` |
| `learning_mode` | `text` | `structured` or `exploration` |
| `exploration_style` | `text` | Sub-style of exploration mode |
| `exploration_started_at` | `timestamptz` | When exploration mode began |
| `exploration_ends_at` | `timestamptz` | When exploration mode expires |
| `xp_total` | `integer` | Cumulative XP earned |
| `current_level_index` | `integer` | Student's current level progression index |
| `onboarding_complete` | `boolean` | Whether onboarding is done |
| `bayesian_alpha_visual` | `double precision` | Bayesian posterior for Visual style |
| `bayesian_alpha_auditory` | `double precision` | Bayesian posterior for Auditory style |
| `bayesian_alpha_textual` | `double precision` | Bayesian posterior for Textual style |
| `created_at` | `timestamptz` | Profile creation time |

**Constraints:**
- `student_profiles_pkey` — Primary key on `id`
- `student_profiles_user_id_key` — Unique on `user_id`
- FK → `users.id`
- CHECK on `assigned_track`, `learning_style`, `learning_mode`

**RLS:**
| Policy | Who | What |
|---|---|---|
| `student_profiles: admin read all` | Admin | Full read |
| `student_profiles: admin update all` | Admin | Full update |
| `student_profiles: student read own` | Student | Own row only |
| `student_profiles: student update own` | Student | Own row only |

---

### 2. Course Content Hierarchy

The content hierarchy follows a strict chain: **Course → Level → Module → Topic**

#### 2.1 `courses`

**Purpose:** Top-level container. Each course belongs to one learning track. There is a concept of "foundation" courses separate from specialization tracks.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `title` | `text` | Course name |
| `description` | `text` | Course description |
| `track` | `text` | One of `Foundation`, `DA`, `DE`, `DS` |
| `order_index` | `integer` | Display/sort order |
| `is_foundation` | `boolean` | True if this is a foundation course |
| `is_active` | `boolean` | Whether visible to students |

**RLS:**
| Policy | Who | What |
|---|---|---|
| Admin CRUD policies | Admin | Full create, read, update, delete |
| `courses: student read active` | Student | Only sees `is_active = true` courses |

---

#### 2.2 `levels`

**Purpose:** Each course contains ordered levels. Completing a level's assessment unlocks progression.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `course_id` | `uuid` | FK → `courses.id` |
| `title` | `text` | Level name |
| `order_index` | `integer` | Ordering within course |
| `xp_reward` | `integer` | XP granted on level completion |
| `is_active` | `boolean` | Visibility to students |

**RLS:** Same admin CRUD + student reads active only.

---

#### 2.3 `modules`

**Purpose:** Each level has multiple modules. Modules are the primary learning units containing topics and an assessment.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `level_id` | `uuid` | FK → `levels.id` |
| `title` | `text` | Module name |
| `order_index` | `integer` | Ordering within level |
| `xp_reward` | `integer` | XP for completing the module |
| `is_active` | `boolean` | Visibility to students |

**RLS:** Same admin CRUD + student reads active only.

---

#### 2.4 `topics`

**Purpose:** The atomic learning unit. Each module has ordered topics. Students consume topic content (text, video, visual) and their engagement is tracked.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `module_id` | `uuid` | FK → `modules.id` |
| `title` | `text` | Topic name |
| `order_index` | `integer` | Ordering within module |
| `xp_reward` | `integer` | XP for completing the topic |
| `is_active` | `boolean` | Visibility to students |

**RLS:** Same admin CRUD + student reads active only.

---

#### 2.5 `topic_resources`

**Purpose:** Each topic can have multiple learning resources (e.g. a video, an article, an infographic). Resources are typed by format to support adaptive learning style serving.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `topic_id` | `uuid` | FK → `topics.id` |
| `format_type` | `text` | One of `Visual`, `Auditory`, `Textual` |
| `resource_url` | `text` | URL to the resource |
| `order_index` | `integer` | Display ordering |

**RLS:** Admin CRUD + students can read resources for active topics only.

---

#### 2.6 `topic_images`

**Purpose:** Supplementary images attached to topics for visual content display.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `topic_id` | `uuid` | FK → `topics.id` |
| `storage_path` | `text` | Path in Supabase Storage (`content-assets` bucket) |
| `alt_text` | `text` | Accessibility alt text |
| `order_index` | `integer` | Display ordering |

**RLS:** Admin CRUD + students can read images for active topics.

---

### 3. Assessments

#### 3.1 `module_assessments`

**Purpose:** Each module has exactly one assessment (enforced by unique constraint on `module_id`). Supports tiered XP rewards based on difficulty.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `module_id` | `uuid` | FK → `modules.id` (unique) |
| `title` | `text` | Assessment title |
| `passing_score` | `integer` | Minimum score % to pass |
| `xp_reward` | `integer` | Base XP reward |
| `xp_reward_easy` | `integer` | XP for easy difficulty |
| `xp_reward_mid` | `integer` | XP for mid difficulty |
| `xp_reward_hard` | `integer` | XP for hard difficulty |
| `is_active` | `boolean` | Whether accessible to students |

**RLS:** Admin CRUD + students can read active assessments.

---

#### 3.2 `module_assessment_questions`

**Purpose:** The individual MCQ questions belonging to a module assessment.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `assessment_id` | `uuid` | FK → `module_assessments.id` |
| `question_text` | `text` | The question prompt |
| `options` | `jsonb` | Array of answer choices |
| `correct_answer` | `text` | The correct option value |
| `order_index` | `integer` | Question ordering |

**RLS:** Admin CRUD + students can read questions for active assessments.

---

#### 3.3 `module_assessment_question_images`

**Purpose:** Optional images attached to individual module assessment questions.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `question_id` | `uuid` | FK → `module_assessment_questions.id` |
| `storage_path` | `text` | Storage path |
| `alt_text` | `text` | Alt text |
| `order_index` | `integer` | Display ordering |

**RLS:** Admin CRUD + students can read if parent assessment is active.

---

#### 3.4 `level_assessments`

**Purpose:** Each level has one end-of-level assessment (unique on `level_id`). Passing this unlocks the next level. Also supports tiered XP and AI grading.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `level_id` | `uuid` | FK → `levels.id` (unique) |
| `title` | `text` | Assessment title |
| `xp_reward` | `integer` | Base XP |
| `xp_reward_easy` | `integer` | XP for easy difficulty |
| `xp_reward_mid` | `integer` | XP for mid difficulty |
| `xp_reward_hard` | `integer` | XP for hard difficulty |
| `is_active` | `boolean` | Whether active |

**RLS:** Admin CRUD + students can read active assessments.

---

#### 3.5 `level_assessment_questions`

**Purpose:** Questions for level assessments. Supports open-ended questions with AI grading rubrics and Mitchy (AI tutor) hints and explanations.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `assessment_id` | `uuid` | FK → `level_assessments.id` |
| `question_text` | `text` | The question prompt |
| `order_index` | `integer` | Ordering |
| `ai_grading_rubric` | `text` | Rubric used by AI to auto-grade |
| `mitchy_hint` | `text` | Hint surfaced by the AI tutor |
| `mitchy_explanation` | `text` | Post-answer explanation from AI tutor |

**RLS:** Admin CRUD + students can read questions for active assessments.

---

### 4. Diagnostic System

Used during student onboarding to assess prior knowledge and calibrate learning style.

#### 4.1 `diagnostic_questions`

**Purpose:** Questions used in diagnostic tests (tests 1–5, enforced by CHECK). Determines student starting level and aptitude scores.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `question_key` | `text` | Unique business key identifier |
| `test_number` | `integer` | Which diagnostic test (1–5) |
| `question_text` | `text` | Question prompt |
| `question_type` | `text` | Question format |
| `options` | `jsonb` | Answer choices |
| `order_index` | `integer` | Display ordering |
| `created_at` | `timestamptz` | Creation timestamp |

**RLS:** Admin CRUD + all authenticated users can read (needed during onboarding).

---

#### 4.2 `diagnostic_question_images`

**Purpose:** Optional images for diagnostic questions. Has an additional `bucket` field to specify the storage bucket.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `question_id` | `uuid` | FK → `diagnostic_questions.id` |
| `storage_path` | `text` | Path in storage |
| `bucket` | `text` | Storage bucket name |
| `alt_text` | `text` | Alt text |
| `order_index` | `integer` | Display ordering |

**RLS:** Admin CRUD + all authenticated users can read.

---

#### 4.3 `calibration_weights`

**Purpose:** Defines how each diagnostic answer maps to aptitude scores across three axes: DA (Data Analytics), DE (Data Engineering), DS (Data Science). Used to calculate which track best fits a student.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `question_id` | `uuid` | FK → `diagnostic_questions.id` |
| `answer_value` | `text` | The specific answer option |
| `weight_da` | `double precision` | Aptitude weight toward DA track |
| `weight_de` | `double precision` | Aptitude weight toward DE track |
| `weight_ds` | `double precision` | Aptitude weight toward DS track |
| `aptitude_category` | `text` | Aptitude classification label |

**Constraints:** Unique on `(question_id, answer_value)` — one weight per answer per question.

**RLS:** Admin CRUD only.

---

#### 4.4 `diagnostic_test_results`

**Purpose:** Stores the raw and computed results of each diagnostic test a student completes. Supports both in-app and externally-taken tests.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `test_number` | `integer` | Which test (1–5) |
| `raw_answers` | `jsonb` | Student's raw answer data |
| `computed_scores` | `jsonb` | Processed aptitude score results |
| `completed_at` | `timestamptz` | When completed |
| `external_score` | `double precision` | Score if externally taken |
| `result_source` | `text` | `in_app` or `external` |

**Constraints:** Unique on `(user_id, test_number)` — one result per test per student.

**RLS:** Admin read + update; students can insert and read own results.

---

### 5. Student Activity & Progress

#### 5.1 `student_progress`

**Purpose:** Tracks the completion status of each topic per student. One record per `(user_id, topic_id)` pair. Also records which content format was served to enable format effectiveness analysis.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `topic_id` | `uuid` | FK → `topics.id` |
| `status` | `text` | `not_started`, `in_progress`, or `completed` |
| `format_served` | `text` | `Visual`, `Auditory`, or `Textual` |
| `started_at` | `timestamptz` | When student first accessed the topic |
| `completed_at` | `timestamptz` | When student completed the topic |

**Constraints:** Unique on `(user_id, topic_id)`.

**RLS:** Admin full read; students can insert, read, and update their own records.

---

#### 5.2 `student_module_attempts`

**Purpose:** Records each attempt a student makes on a module assessment. Stores full answers and pass/fail outcome. Difficulty level is tracked per attempt.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `assessment_id` | `uuid` | FK → `module_assessments.id` |
| `answers` | `jsonb` | Student's submitted answers |
| `score` | `double precision` | Percentage score |
| `passed` | `boolean` | Whether passed |
| `difficulty` | `text` | `easy`, `mid`, or `hard` |
| `submitted_at` | `timestamptz` | Submission timestamp |

**RLS:** Admin full read; students can read own records.

---

#### 5.3 `student_level_attempts`

**Purpose:** Records each attempt on a level assessment. Supports AI grading via `mitchy_feedback`. Multiple attempts allowed.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `assessment_id` | `uuid` | FK → `level_assessments.id` |
| `answers` | `jsonb` | Submitted answers |
| `score` | `double precision` | Score achieved |
| `passed` | `boolean` | Pass/fail |
| `difficulty` | `text` | `easy`, `mid`, or `hard` |
| `mitchy_feedback` | `text` | AI tutor's personalized feedback |
| `submitted_at` | `timestamptz` | Submission time |

**RLS:** Admin full read + update; students can insert and read own records.

---

#### 5.4 `content_engagement_logs`

**Purpose:** Fine-grained event log of student content interactions. Tracks time spent per topic and an engagement score. The `bayesian_eligible` flag marks sessions usable for updating Bayesian learning style posteriors.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `topic_id` | `uuid` | FK → `topics.id` |
| `format_type` | `text` | `Visual`, `Auditory`, or `Textual` |
| `time_spent_seconds` | `integer` | Duration of engagement |
| `engagement_score` | `double precision` | Computed engagement quality score |
| `bayesian_eligible` | `boolean` | Whether this session updates Bayesian model |
| `logged_at` | `timestamptz` | When logged |

**RLS:** Admin full read; students can insert their own logs.

---

### 6. Gamification

#### 6.1 `user_streaks`

**Purpose:** Tracks daily learning streaks per user. One record per user. Updated when a student completes learning activity on consecutive days.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` (unique) |
| `current_streak_days` | `integer` | Current active streak |
| `longest_streak_days` | `integer` | All-time best streak |
| `last_activity_date` | `date` | Last day with qualifying activity |
| `updated_at` | `timestamptz` | Last update time |

**RLS:** Admin full read; students can insert, read, and update own record.

---

#### 6.2 `achievements_dictionary`

**Purpose:** Master list of all possible achievements/badges on the platform. Defines criteria for unlocking.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `achievement_key` | `text` | Unique machine-readable key |
| `label` | `text` | Display name |
| `description` | `text` | What the achievement is for |
| `criteria_type` | `text` | Type of trigger (e.g. streak, xp, completion) |
| `criteria_threshold` | `integer` | Numeric threshold to unlock |
| `badge_image_path` | `text` | Path to badge image asset |
| `created_at` | `timestamptz` | When added |

**RLS:** Admin CRUD; all authenticated users can read.

---

#### 6.3 `user_achievements`

**Purpose:** Junction table recording which achievements each user has unlocked and when.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `achievement_id` | `uuid` | FK → `achievements_dictionary.id` |
| `unlocked_at` | `timestamptz` | When the achievement was earned |

**Constraints:** Unique on `(user_id, achievement_id)` — can't earn the same achievement twice.

**RLS:** Admin full read; students can insert and read own achievements.

---

#### 6.4 `leaderboard_snapshots`

**Purpose:** Daily snapshots of each student's XP rank per track. Enables leaderboard views without real-time computation on large datasets.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `track` | `text` | One of `Foundation`, `DA`, `DE`, `DS` |
| `xp_at_snapshot` | `integer` | XP total at snapshot time |
| `rank_at_snapshot` | `integer` | Rank position at snapshot time |
| `snapshot_date` | `date` | Date of snapshot |

**Constraints:** Unique on `(user_id, track, snapshot_date)`.

**RLS:** Admin full read; all students can read leaderboard data.

---

#### 6.5 `weekly_challenges`

**Purpose:** Time-bounded challenge sets linked to a specific module. Available for a defined date window. Supports tiered XP rewards.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `module_id` | `uuid` | FK → `modules.id` |
| `title` | `text` | Challenge title |
| `description` | `text` | Challenge description |
| `available_from` | `date` | Start date (inclusive) |
| `available_until` | `date` | End date (inclusive) |
| `xp_reward` | `integer` | Base XP reward |
| `xp_reward_easy` | `integer` | XP for easy |
| `xp_reward_mid` | `integer` | XP for mid |
| `xp_reward_hard` | `integer` | XP for hard |
| `is_active` | `boolean` | Whether active |

**RLS:** Admin CRUD; students can read challenges that are `is_active = true` AND within the current date window.

---

#### 6.6 `challenge_questions`

**Purpose:** MCQ questions belonging to a weekly challenge.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `challenge_id` | `uuid` | FK → `weekly_challenges.id` |
| `question_text` | `text` | Question prompt |
| `options` | `jsonb` | Answer options |
| `correct_answer` | `text` | Correct answer value |
| `order_index` | `integer` | Display ordering |

**RLS:** Admin CRUD; students can read questions only for currently active, in-window challenges.

---

#### 6.7 `challenge_question_images`

**Purpose:** Optional images for challenge questions.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `question_id` | `uuid` | FK → `challenge_questions.id` |
| `storage_path` | `text` | Storage path |
| `alt_text` | `text` | Alt text |
| `order_index` | `integer` | Display ordering |

**RLS:** Admin CRUD; students can read only for active, in-window challenge questions.

---

#### 6.8 `student_challenge_attempts`

**Purpose:** One attempt record per `(user_id, challenge_id)` — students cannot re-attempt the same challenge. Records score, difficulty, and completion.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `challenge_id` | `uuid` | FK → `weekly_challenges.id` |
| `answers` | `jsonb` | Submitted answers |
| `score` | `double precision` | Score |
| `difficulty` | `text` | `easy`, `mid`, or `hard` |
| `completed` | `boolean` | Whether fully completed |
| `submitted_at` | `timestamptz` | Submission time |

**Constraints:** Unique on `(user_id, challenge_id)` — one attempt per challenge per student.

**RLS:** Admin full read; students can read own attempts.

---

### 7. AI / ML Analytics

#### 7.1 `ml_daily_metrics`

**Purpose:** Daily aggregate ML metrics per user. Used for admin dashboards and risk detection. Unique per `(user_id, metric_date)`.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `metric_date` | `date` | The date these metrics apply to |
| `concept_decay_score` | `double precision` | How much the student has "forgotten" |
| `engagement_velocity` | `double precision` | Rate of engagement acceleration/deceleration |
| `topic_struggle_index` | `double precision` | Composite difficulty struggle score |
| `computed_at` | `timestamptz` | When the metrics were computed |

**RLS:** Admin read only.

---

#### 7.2 `ml_topic_daily_metrics`

**Purpose:** Granular ML metrics per `(user_id, topic_id, snapshot_date)`. Adds retention estimates and exponential moving averages for more refined per-topic analytics.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `topic_id` | `uuid` | FK → `topics.id` |
| `snapshot_date` | `date` | Date of snapshot |
| `concept_decay_score` | `double precision` | Topic-level concept decay |
| `engagement_velocity` | `double precision` | Topic engagement velocity |
| `topic_struggle_index` | `double precision` | Topic struggle score |
| `engagement_ema` | `double precision` | Exponential moving average of engagement |
| `retention_estimate` | `double precision` | Estimated retention rate (0.0–1.0) |
| `struggle_probability` | `double precision` | Probability of struggling (0.0–1.0) |
| `calculated_at` | `timestamptz` | Computation timestamp |

**Constraints:** Unique on `(snapshot_date, user_id, topic_id)`. Both `retention_estimate` and `struggle_probability` are bounded between 0 and 1.

**RLS:** Admin full manage; students can read own metrics.

---

#### 7.3 `student_sentiment_history`

**Purpose:** Time-series log of student emotional/engagement sentiment detected during sessions. Used for burnout detection and intervention triggers.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `sentiment_score` | `double precision` | Numeric sentiment value |
| `learning_state` | `text` | Detected learning state label |
| `session_context` | `text` | Contextual notes about the session |
| `recorded_at` | `timestamptz` | When recorded |

**RLS:** Admin read only.

---

#### 7.4 `risk_scores`

**Purpose:** Computed at-risk scores per student. When `alert_triggered = true`, an intervention record may be created. Stores a full feature snapshot for audit/explainability.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `risk_score` | `double precision` | Numeric risk score |
| `risk_level` | `text` | `low`, `medium`, `high`, or `critical` |
| `feature_snapshot` | `jsonb` | ML feature values used in computation |
| `alert_triggered` | `boolean` | Whether alert was raised |
| `alert_resolved` | `boolean` | Whether alert has been resolved |
| `computed_at` | `timestamptz` | Computation time |

**RLS:** Admin read + update only.

---

#### 7.5 `intervention_logs`

**Purpose:** Tracks admin interventions triggered by risk alerts. Records who intervened, what action was taken, and when it was resolved. Each log is tied to a specific risk score record.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `risk_score_id` | `uuid` | FK → `risk_scores.id` |
| `admin_id` | `uuid` | FK → `users.id` (must be admin) |
| `action_taken` | `text` | Description of action |
| `notes` | `text` | Admin notes |
| `claimed_at` | `timestamptz` | When admin claimed the alert |
| `resolved_at` | `timestamptz` | When resolved |

**RLS:** Admins can only insert, read, and update their own intervention records (scoped to `admin_id = auth.uid()`).

---

### 8. Chat & RAG System

#### 8.1 `chat_sessions`

**Purpose:** Container for a single conversation session between a student and Mitchy (the AI tutor). Sessions have a start/end time.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `started_at` | `timestamptz` | Session start time |
| `ended_at` | `timestamptz` | Session end time (null if active) |

**RLS:** Admin full read; students can insert, read, and update own sessions.

---

#### 8.2 `chat_messages`

**Purpose:** Individual messages within a chat session. Stores both user and assistant (Mitchy) messages. The `mitchy_action` JSONB field captures structured AI actions (e.g. navigating to a topic, triggering an assessment). `detected_learning_state` holds the AI's inference about student state from this message.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `session_id` | `uuid` | FK → `chat_sessions.id` |
| `role` | `text` | `user` or `assistant` |
| `content` | `text` | Message text |
| `mitchy_action` | `jsonb` | Structured action taken by AI tutor |
| `detected_learning_state` | `text` | AI-inferred student state at this message |
| `sent_at` | `timestamptz` | Message timestamp |

**RLS:** Admin full read; students can insert and read messages belonging to their own sessions.

---

#### 8.3 `document_chunks`

**Purpose:** RAG (Retrieval-Augmented Generation) vector store. Course content is chunked, embedded, and stored here. Mitchy queries this table using vector similarity search to ground responses in curriculum content.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `topic_id` | `uuid` | FK → `topics.id` (source topic) |
| `content` | `text` | Raw text chunk |
| `metadata` | `jsonb` | Chunk metadata (page, section, etc.) |
| `embedding` | `USER-DEFINED` | Vector embedding (pgvector type) |
| `inserted_at` | `timestamptz` | When chunk was indexed |

**RLS:** Admin full read; all students can read document chunks (needed for RAG queries).

---

### 9. Notifications & Devices

#### 9.1 `in_app_notifications`

**Purpose:** System-generated in-app notifications for students. Covers events like achievement unlocks, burnout detection, new challenges, and risk alerts.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `title` | `text` | Notification title |
| `body` | `text` | Notification body text |
| `notification_type` | `text` | One of: `achievement_unlocked`, `burnout_detected`, `challenge_available`, `level_passed`, `risk_alert`, `general` |
| `is_read` | `boolean` | Whether student has read it |
| `metadata` | `jsonb` | Type-specific extra data |
| `created_at` | `timestamptz` | Creation time |

**RLS:** Only admins can insert; students can read and mark their own notifications as read.

---

#### 9.2 `user_devices`

**Purpose:** Stores FCM (Firebase Cloud Messaging) push notification tokens per device per user. Supports Android and iOS. Used to send push notifications.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `users.id` |
| `fcm_token` | `text` | Firebase push token |
| `device_name` | `text` | Human-readable device label |
| `platform` | `text` | `android` or `ios` |
| `created_at` | `timestamptz` | Registration time |
| `updated_at` | `timestamptz` | Last token refresh time |

**Constraints:** Unique on `(user_id, fcm_token)`.

**RLS:** Admin read; students can insert, read, update, and delete their own devices.

---

## Entity Relationship Summary

```
users
 ├── student_profiles          (1:1)
 ├── user_streaks               (1:1)
 ├── user_achievements          (1:N) ──→ achievements_dictionary
 ├── leaderboard_snapshots      (1:N)
 ├── diagnostic_test_results    (1:N)
 ├── student_progress           (1:N) ──→ topics
 ├── student_module_attempts    (1:N) ──→ module_assessments
 ├── student_level_attempts     (1:N) ──→ level_assessments
 ├── student_challenge_attempts (1:N) ──→ weekly_challenges
 ├── content_engagement_logs    (1:N) ──→ topics
 ├── student_sentiment_history  (1:N)
 ├── risk_scores                (1:N)
 ├── intervention_logs          (as admin, 1:N)
 ├── ml_daily_metrics           (1:N)
 ├── ml_topic_daily_metrics     (1:N) ──→ topics
 ├── chat_sessions              (1:N)
 ├── in_app_notifications       (1:N)
 └── user_devices               (1:N)

courses
 └── levels
      └── modules
           ├── topics
           │    ├── topic_resources
           │    ├── topic_images
           │    ├── document_chunks
           │    ├── student_progress
           │    ├── content_engagement_logs
           │    └── ml_topic_daily_metrics
           ├── module_assessments
           │    ├── module_assessment_questions
           │    │    └── module_assessment_question_images
           │    └── student_module_attempts
           └── weekly_challenges
                ├── challenge_questions
                │    └── challenge_question_images
                └── student_challenge_attempts

levels (cont.)
 └── level_assessments
      ├── level_assessment_questions
      └── student_level_attempts

diagnostic_questions
 ├── diagnostic_question_images
 ├── calibration_weights
 └── (referenced by diagnostic_test_results via raw_answers)

chat_sessions
 └── chat_messages

risk_scores
 └── intervention_logs
```

---

## Row Level Security (RLS) Summary

All tables have RLS enabled. The platform uses two roles: **admin** and **student**, determined by `users.role`. The `is_admin()` and `current_user_is_admin()` helper functions check this against `auth.uid()`.

### General Patterns

**Admin access** — Admins have unrestricted read access to all tables. They can CRUD content tables (courses, levels, modules, topics, assessments, etc.). For sensitive operational tables like `intervention_logs`, admins are scoped to their own records.

**Student access** — Students can generally only access their own data rows. For shared content (courses, topics, assessments), they can only read rows where `is_active = true`. For time-sensitive content (weekly challenges), date range filters are also applied.

### Access Matrix by Category

| Category | Student Can Read | Student Can Write |
|---|---|---|
| Own profile/user data | Own row only | Own row only |
| Course content | Active rows only | ✗ |
| Assessments | Active rows only | ✗ |
| Diagnostic questions | All (for onboarding) | ✗ |
| Diagnostic results | Own only | Own only (insert) |
| Progress/attempts | Own only | Own only |
| Engagement logs | ✗ | Own only (insert) |
| Gamification (streaks, achievements) | Own only | Own only |
| Leaderboard snapshots | All students | ✗ |
| Weekly challenges | Active + in date window | ✗ |
| ML metrics | Own topic metrics only | ✗ |
| Risk scores | ✗ | ✗ |
| Sentiment history | ✗ | ✗ |
| Intervention logs | ✗ | ✗ |
| Chat (sessions + messages) | Own only | Own only |
| Document chunks (RAG) | All | ✗ |
| Notifications | Own only | ✗ (admin inserts) |
| Devices | Own only | Own only |

---

## Database Functions

| Function | Returns | Purpose |
|---|---|---|
| `is_admin()` | `boolean` | RLS helper — checks if `auth.uid()` has role `admin` |
| `current_user_is_admin()` | `boolean` | Alternate admin check (used in `ml_topic_daily_metrics` RLS) |
| `handle_new_user()` | `trigger` | Auto-creates a `users` row when a new Supabase Auth user signs up |
| `increment_xp()` | `void` | Increments a student's `xp_total` in `student_profiles` |
| `get_student_xp_rank()` | `jsonb` | Returns a student's XP and leaderboard rank |
| `get_student_diploma_progress()` | `jsonb` | Returns student progress toward track diploma |
| `get_student_learning_heatmap()` | `jsonb` | Returns activity heatmap data for a student |
| `get_admin_risk_radar()` | `jsonb` | Admin dashboard: at-risk student radar chart data |
| `get_admin_struggle_map()` | `jsonb` | Admin dashboard: topic struggle heatmap across students |
| `get_admin_foundation_funnel()` | `jsonb` | Admin dashboard: foundation track funnel conversion |
| `get_admin_momentum_line()` | `jsonb` | Admin dashboard: class engagement momentum over time |
| `get_admin_class_health_timeline()` | `jsonb` | Admin dashboard: class health metrics timeline |
| `get_admin_topic_drilldown()` | `jsonb` | Admin dashboard: detailed per-topic analytics |
| `get_admin_format_effectiveness()` | `jsonb` | Admin dashboard: learning format (Visual/Audio/Text) effectiveness |
| `_internal_get_*` variants | `jsonb` | Internal implementations of the above (called by the public wrappers) |

---

## Storage Buckets

| Bucket | Created | Purpose |
|---|---|---|
| `calibration-media` | 2026-05-10 | Images for diagnostic/calibration questions |
| `content-assets` | 2026-05-10 | Topic images, module assets, course media |
| `student-submissions` | 2026-05-10 | Student-uploaded content (e.g. for open-ended assessments) |
