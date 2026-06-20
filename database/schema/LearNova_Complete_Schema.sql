-- ==========================================
-- LearNova Supabase Complete Schema & RLS
-- ==========================================

-- 1. TABLES
CREATE TABLE public.users (
    id uuid,
    created_at timestamp with time zone,
    last_seen_at timestamp with time zone,
    email text,
    full_name text,
    avatar_url text,
    role text
);

CREATE TABLE public.achievements_dictionary (
    id uuid,
    criteria_threshold integer,
    created_at timestamp with time zone,
    achievement_key text,
    label text,
    description text,
    criteria_type text,
    badge_image_path text
);

CREATE TABLE public.modules (
    id uuid,
    level_id uuid,
    order_index integer,
    xp_reward integer,
    is_active boolean,
    title text
);

CREATE TABLE public.courses (
    id uuid,
    order_index integer,
    is_foundation boolean,
    is_active boolean,
    track text,
    title text,
    description text
);

CREATE TABLE public.student_profiles (
    id uuid,
    user_id uuid,
    exploration_started_at timestamp with time zone,
    exploration_ends_at timestamp with time zone,
    xp_total integer,
    current_level_index integer,
    onboarding_complete boolean,
    bayesian_alpha_visual double precision,
    bayesian_alpha_auditory double precision,
    bayesian_alpha_textual double precision,
    created_at timestamp with time zone,
    assigned_track text,
    learning_style text,
    learning_mode text,
    exploration_style text
);

CREATE TABLE public.topics (
    id uuid,
    module_id uuid,
    order_index integer,
    xp_reward integer,
    is_active boolean,
    title text
);

CREATE TABLE public.user_streaks (
    id uuid,
    user_id uuid,
    current_streak_days integer,
    longest_streak_days integer,
    last_activity_date date,
    updated_at timestamp with time zone
);

CREATE TABLE public.topic_resources (
    id uuid,
    topic_id uuid,
    order_index integer,
    format_type text,
    resource_url text
);

CREATE TABLE public.student_module_attempts (
    id uuid,
    user_id uuid,
    assessment_id uuid,
    answers jsonb,
    score double precision,
    passed boolean,
    submitted_at timestamp with time zone,
    difficulty text
);

CREATE TABLE public.module_assessments (
    id uuid,
    module_id uuid,
    passing_score integer,
    xp_reward integer,
    is_active boolean,
    title text
);

CREATE TABLE public.user_achievements (
    id uuid,
    user_id uuid,
    achievement_id uuid,
    unlocked_at timestamp with time zone
);

CREATE TABLE public.topic_images (
    id uuid,
    topic_id uuid,
    order_index integer,
    storage_path text,
    alt_text text
);

CREATE TABLE public.leaderboard_snapshots (
    id uuid,
    user_id uuid,
    xp_at_snapshot integer,
    rank_at_snapshot integer,
    snapshot_date date,
    track text
);

CREATE TABLE public.student_level_attempts (
    id uuid,
    user_id uuid,
    assessment_id uuid,
    answers jsonb,
    score double precision,
    passed boolean,
    submitted_at timestamp with time zone,
    mitchy_feedback text,
    difficulty text
);

CREATE TABLE public.diagnostic_question_images (
    id uuid,
    question_id uuid,
    order_index integer,
    storage_path text,
    alt_text text,
    bucket text
);

CREATE TABLE public.diagnostic_questions (
    id uuid,
    test_number integer,
    options jsonb,
    order_index integer,
    created_at timestamp with time zone,
    question_key text,
    question_text text,
    question_type text
);

CREATE TABLE public.module_assessment_questions (
    id uuid,
    assessment_id uuid,
    options jsonb,
    order_index integer,
    question_text text,
    correct_answer text
);

CREATE TABLE public.levels (
    id uuid,
    course_id uuid,
    order_index integer,
    xp_reward integer,
    is_active boolean,
    title text
);

CREATE TABLE public.challenge_questions (
    id uuid,
    challenge_id uuid,
    options jsonb,
    order_index integer,
    question_text text,
    correct_answer text,
    difficulty text
);

CREATE TABLE public.calibration_weights (
    id uuid,
    question_id uuid,
    weight_da double precision,
    weight_de double precision,
    weight_ds double precision,
    answer_value text,
    aptitude_category text
);

CREATE TABLE public.module_assessment_question_images (
    id uuid,
    question_id uuid,
    order_index integer,
    storage_path text,
    alt_text text
);

CREATE TABLE public.student_challenge_attempts (
    id uuid,
    user_id uuid,
    challenge_id uuid,
    answers jsonb,
    score double precision,
    completed boolean,
    submitted_at timestamp with time zone,
    difficulty text
);

CREATE TABLE public.student_sentiment_history (
    id uuid,
    user_id uuid,
    sentiment_score double precision,
    recorded_at timestamp with time zone,
    learning_state text,
    session_context text
);

CREATE TABLE public.student_progress (
    id uuid,
    user_id uuid,
    topic_id uuid,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    status text,
    format_served text
);

CREATE TABLE public.content_engagement_logs (
    id uuid,
    user_id uuid,
    topic_id uuid,
    time_spent_seconds integer,
    engagement_score double precision,
    bayesian_eligible boolean,
    logged_at timestamp with time zone,
    format_type text
);

CREATE TABLE public.risk_scores (
    id uuid,
    user_id uuid,
    risk_score double precision,
    feature_snapshot jsonb,
    alert_triggered boolean,
    alert_resolved boolean,
    computed_at timestamp with time zone,
    risk_level text
);

CREATE TABLE public.intervention_logs (
    id uuid,
    risk_score_id uuid,
    admin_id uuid,
    claimed_at timestamp with time zone,
    resolved_at timestamp with time zone,
    action_taken text,
    notes text
);

CREATE TABLE public.ml_daily_metrics (
    id uuid,
    user_id uuid,
    engagement_velocity double precision,
    topic_struggle_index double precision,
    metric_date date,
    computed_at timestamp with time zone,
    concept_decay_score double precision
);

CREATE TABLE public.chat_sessions (
    id uuid,
    user_id uuid,
    started_at timestamp with time zone,
    ended_at timestamp with time zone
);

CREATE TABLE public.chat_messages (
    id uuid,
    session_id uuid,
    mitchy_action jsonb,
    sent_at timestamp with time zone,
    role text,
    content text,
    detected_learning_state text
);

CREATE TABLE public.document_chunks (
    id uuid,
    topic_id uuid,
    metadata jsonb,
    embedding USER-DEFINED,
    inserted_at timestamp with time zone,
    content text
);

CREATE TABLE public.user_devices (
    id uuid,
    user_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    fcm_token text,
    device_name text,
    platform text
);

CREATE TABLE public.in_app_notifications (
    id uuid,
    user_id uuid,
    is_read boolean,
    metadata jsonb,
    created_at timestamp with time zone,
    title text,
    body text,
    notification_type text
);

CREATE TABLE public.level_assessment_questions (
    id uuid,
    assessment_id uuid,
    order_index integer,
    question_text text,
    ai_grading_rubric text,
    mitchy_hint text,
    mitchy_explanation text
);

CREATE TABLE public.level_assessments (
    id uuid,
    level_id uuid,
    xp_reward integer,
    is_active boolean,
    xp_reward_easy integer,
    xp_reward_mid integer,
    xp_reward_hard integer,
    title text
);

CREATE TABLE public.weekly_challenges (
    id uuid,
    module_id uuid,
    available_from date,
    available_until date,
    is_active boolean,
    xp_reward_easy integer,
    xp_reward_mid integer,
    xp_reward_hard integer,
    title text,
    description text
);

CREATE TABLE public.diagnostic_test_results (
    id uuid,
    user_id uuid,
    test_number integer,
    raw_answers jsonb,
    computed_scores jsonb,
    completed_at timestamp with time zone,
    external_score double precision,
    result_source text
);

CREATE TABLE public.challenge_question_images (
    id uuid,
    question_id uuid,
    order_index integer,
    storage_path text,
    alt_text text
);

CREATE TABLE public.ml_topic_daily_metrics (
    id uuid,
    snapshot_date date,
    user_id uuid,
    topic_id uuid,
    concept_decay_score double precision,
    engagement_velocity double precision,
    topic_struggle_index double precision,
    engagement_ema double precision,
    retention_estimate double precision,
    struggle_probability double precision,
    calculated_at timestamp with time zone
);

CREATE TABLE public.user_activity_log (
    id uuid,
    user_id uuid,
    duration_seconds integer,
    activity_date date,
    created_at timestamp with time zone,
    module_id text,
    level_id text
);

CREATE TABLE public.student_resource_logs (
    id uuid,
    user_id uuid,
    topic_id uuid,
    completed boolean,
    created_at timestamp with time zone,
    resource_type text
);

CREATE TABLE public.student_challenge_schedule (
    id uuid,
    user_id uuid,
    challenge_id uuid,
    assigned_at timestamp with time zone,
    available_from timestamp with time zone,
    expires_at timestamp with time zone,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    current_attempts integer,
    best_score double precision,
    passed boolean,
    status text
);

CREATE TABLE public.student_perks (
    id uuid,
    user_id uuid,
    owl_hint_count integer,
    sly_fox_count integer,
    updated_at timestamp with time zone
);

-- 2. CONSTRAINTS (PK, UNIQUE, CHECK)
ALTER TABLE public.users ADD CONSTRAINT users_pkey PRIMARY KEY (id);
ALTER TABLE public.levels ADD CONSTRAINT levels_pkey PRIMARY KEY (id);
ALTER TABLE public.users ADD CONSTRAINT users_email_key UNIQUE (email);
ALTER TABLE public.achievements_dictionary ADD CONSTRAINT achievements_dictionary_pkey PRIMARY KEY (id);
ALTER TABLE public.achievements_dictionary ADD CONSTRAINT achievements_dictionary_achievement_key_key UNIQUE (achievement_key);
ALTER TABLE public.diagnostic_questions ADD CONSTRAINT diagnostic_questions_pkey PRIMARY KEY (id);
ALTER TABLE public.diagnostic_questions ADD CONSTRAINT diagnostic_questions_question_key_key UNIQUE (question_key);
ALTER TABLE public.modules ADD CONSTRAINT modules_pkey PRIMARY KEY (id);
ALTER TABLE public.topics ADD CONSTRAINT topics_pkey PRIMARY KEY (id);
ALTER TABLE public.weekly_challenges ADD CONSTRAINT weekly_challenges_pkey PRIMARY KEY (id);
ALTER TABLE public.challenge_questions ADD CONSTRAINT challenge_questions_pkey PRIMARY KEY (id);
ALTER TABLE public.courses ADD CONSTRAINT courses_pkey PRIMARY KEY (id);
ALTER TABLE public.student_profiles ADD CONSTRAINT student_profiles_pkey PRIMARY KEY (id);
ALTER TABLE public.student_profiles ADD CONSTRAINT student_profiles_user_id_key UNIQUE (user_id);
ALTER TABLE public.user_streaks ADD CONSTRAINT user_streaks_pkey PRIMARY KEY (id);
ALTER TABLE public.user_streaks ADD CONSTRAINT user_streaks_user_id_key UNIQUE (user_id);
ALTER TABLE public.user_achievements ADD CONSTRAINT user_achievements_pkey PRIMARY KEY (id);
ALTER TABLE public.user_achievements ADD CONSTRAINT user_achievements_user_id_achievement_id_key UNIQUE (achievement_id);
ALTER TABLE public.leaderboard_snapshots ADD CONSTRAINT leaderboard_snapshots_pkey PRIMARY KEY (id);
ALTER TABLE public.leaderboard_snapshots ADD CONSTRAINT leaderboard_snapshots_user_id_track_snapshot_date_key UNIQUE (snapshot_date);
ALTER TABLE public.topic_resources ADD CONSTRAINT topic_resources_pkey PRIMARY KEY (id);
ALTER TABLE public.topic_images ADD CONSTRAINT topic_images_pkey PRIMARY KEY (id);
ALTER TABLE public.diagnostic_question_images ADD CONSTRAINT diagnostic_question_images_pkey PRIMARY KEY (id);
ALTER TABLE public.calibration_weights ADD CONSTRAINT calibration_weights_pkey PRIMARY KEY (id);
ALTER TABLE public.calibration_weights ADD CONSTRAINT calibration_weights_question_id_answer_value_key UNIQUE (answer_value);
ALTER TABLE public.diagnostic_test_results ADD CONSTRAINT diagnostic_test_results_pkey PRIMARY KEY (id);
ALTER TABLE public.diagnostic_test_results ADD CONSTRAINT diagnostic_test_results_user_id_test_number_key UNIQUE (test_number);
ALTER TABLE public.module_assessments ADD CONSTRAINT module_assessments_pkey PRIMARY KEY (id);
ALTER TABLE public.module_assessments ADD CONSTRAINT module_assessments_module_id_key UNIQUE (module_id);
ALTER TABLE public.module_assessment_questions ADD CONSTRAINT module_assessment_questions_pkey PRIMARY KEY (id);
ALTER TABLE public.module_assessment_question_images ADD CONSTRAINT module_assessment_question_images_pkey PRIMARY KEY (id);
ALTER TABLE public.student_module_attempts ADD CONSTRAINT student_module_attempts_pkey PRIMARY KEY (id);
ALTER TABLE public.level_assessments ADD CONSTRAINT level_assessments_pkey PRIMARY KEY (id);
ALTER TABLE public.level_assessments ADD CONSTRAINT level_assessments_level_id_key UNIQUE (level_id);
ALTER TABLE public.level_assessment_questions ADD CONSTRAINT level_assessment_questions_pkey PRIMARY KEY (id);
ALTER TABLE public.student_level_attempts ADD CONSTRAINT student_level_attempts_pkey PRIMARY KEY (id);
ALTER TABLE public.student_challenge_attempts ADD CONSTRAINT student_challenge_attempts_pkey PRIMARY KEY (id);
ALTER TABLE public.student_challenge_attempts ADD CONSTRAINT student_challenge_attempts_user_id_challenge_id_key UNIQUE (challenge_id);
ALTER TABLE public.student_progress ADD CONSTRAINT student_progress_pkey PRIMARY KEY (id);
ALTER TABLE public.student_progress ADD CONSTRAINT student_progress_user_id_topic_id_key UNIQUE (topic_id);
ALTER TABLE public.content_engagement_logs ADD CONSTRAINT content_engagement_logs_pkey PRIMARY KEY (id);
ALTER TABLE public.student_sentiment_history ADD CONSTRAINT student_sentiment_history_pkey PRIMARY KEY (id);
ALTER TABLE public.risk_scores ADD CONSTRAINT risk_scores_pkey PRIMARY KEY (id);
ALTER TABLE public.intervention_logs ADD CONSTRAINT intervention_logs_pkey PRIMARY KEY (id);
ALTER TABLE public.ml_daily_metrics ADD CONSTRAINT ml_daily_metrics_pkey PRIMARY KEY (id);
ALTER TABLE public.ml_daily_metrics ADD CONSTRAINT ml_daily_metrics_user_id_metric_date_key UNIQUE (metric_date);
ALTER TABLE public.chat_sessions ADD CONSTRAINT chat_sessions_pkey PRIMARY KEY (id);
ALTER TABLE public.chat_messages ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (id);
ALTER TABLE public.document_chunks ADD CONSTRAINT document_chunks_pkey PRIMARY KEY (id);
ALTER TABLE public.user_devices ADD CONSTRAINT user_devices_pkey PRIMARY KEY (id);
ALTER TABLE public.user_devices ADD CONSTRAINT user_devices_user_id_fcm_token_key UNIQUE (fcm_token);
ALTER TABLE public.in_app_notifications ADD CONSTRAINT in_app_notifications_pkey PRIMARY KEY (id);
ALTER TABLE public.challenge_question_images ADD CONSTRAINT challenge_question_images_pkey PRIMARY KEY (id);
ALTER TABLE public.ml_topic_daily_metrics ADD CONSTRAINT ml_topic_daily_metrics_pkey PRIMARY KEY (id);
ALTER TABLE public.ml_topic_daily_metrics ADD CONSTRAINT ml_topic_daily_metrics_unique_day_user_topic UNIQUE (topic_id);
ALTER TABLE public.user_activity_log ADD CONSTRAINT user_activity_log_pkey PRIMARY KEY (id);
ALTER TABLE public.student_perks ADD CONSTRAINT student_perks_pkey PRIMARY KEY (id);
ALTER TABLE public.student_perks ADD CONSTRAINT student_perks_user_id_key UNIQUE (user_id);
ALTER TABLE public.student_challenge_schedule ADD CONSTRAINT student_challenge_schedule_pkey PRIMARY KEY (id);
ALTER TABLE public.student_challenge_schedule ADD CONSTRAINT scs_user_challenge_unique UNIQUE (challenge_id);
ALTER TABLE public.student_resource_logs ADD CONSTRAINT student_resource_logs_pkey PRIMARY KEY (id);
ALTER TABLE public.users ADD CONSTRAINT users_users_role_check_CHECK CHECK ((role = ANY (ARRAY['student'::text, 'admin'::text])));
ALTER TABLE public.diagnostic_questions ADD CONSTRAINT diagnostic_questions_test_number_check CHECK (((test_number >= 1) AND (test_number <= 5)));
ALTER TABLE public.courses ADD CONSTRAINT courses_track_check CHECK ((track = ANY (ARRAY['Foundation'::text, 'DA'::text, 'DE'::text, 'DS'::text])));
ALTER TABLE public.student_profiles ADD CONSTRAINT student_profiles_assigned_track_check CHECK ((assigned_track = ANY (ARRAY['Foundation'::text, 'DA'::text, 'DE'::text, 'DS'::text])));
ALTER TABLE public.student_profiles ADD CONSTRAINT student_profiles_learning_style_check CHECK ((learning_style = ANY (ARRAY['Visual'::text, 'Auditory'::text, 'Textual'::text])));
ALTER TABLE public.student_profiles ADD CONSTRAINT student_profiles_learning_mode_check CHECK ((learning_mode = ANY (ARRAY['structured'::text, 'exploration'::text])));
ALTER TABLE public.leaderboard_snapshots ADD CONSTRAINT leaderboard_snapshots_track_check CHECK ((track = ANY (ARRAY['Foundation'::text, 'DA'::text, 'DE'::text, 'DS'::text])));
ALTER TABLE public.topic_resources ADD CONSTRAINT topic_resources_format_type_check CHECK ((format_type = ANY (ARRAY['Visual'::text, 'Auditory'::text, 'Textual'::text])));
ALTER TABLE public.diagnostic_test_results ADD CONSTRAINT diagnostic_test_results_test_number_check CHECK (((test_number >= 1) AND (test_number <= 5)));
ALTER TABLE public.student_progress ADD CONSTRAINT student_progress_status_check CHECK ((status = ANY (ARRAY['not_started'::text, 'in_progress'::text, 'completed'::text])));
ALTER TABLE public.student_progress ADD CONSTRAINT student_progress_format_served_check CHECK ((format_served = ANY (ARRAY['Visual'::text, 'Auditory'::text, 'Textual'::text])));
ALTER TABLE public.content_engagement_logs ADD CONSTRAINT content_engagement_logs_format_type_check CHECK ((format_type = ANY (ARRAY['Visual'::text, 'Auditory'::text, 'Textual'::text])));
ALTER TABLE public.risk_scores ADD CONSTRAINT risk_scores_risk_level_check CHECK ((risk_level = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'critical'::text])));
ALTER TABLE public.chat_messages ADD CONSTRAINT chat_messages_role_check CHECK ((role = ANY (ARRAY['user'::text, 'assistant'::text])));
ALTER TABLE public.user_devices ADD CONSTRAINT user_devices_platform_check CHECK ((platform = ANY (ARRAY['android'::text, 'ios'::text])));
ALTER TABLE public.in_app_notifications ADD CONSTRAINT in_app_notifications_notification_type_check CHECK ((notification_type = ANY (ARRAY['achievement_unlocked'::text, 'burnout_detected'::text, 'challenge_available'::text, 'level_passed'::text, 'risk_alert'::text, 'general'::text])));
ALTER TABLE public.student_module_attempts ADD CONSTRAINT student_module_attempts_difficulty_check CHECK ((difficulty = ANY (ARRAY['easy'::text, 'mid'::text, 'hard'::text])));
ALTER TABLE public.student_level_attempts ADD CONSTRAINT student_level_attempts_difficulty_check CHECK ((difficulty = ANY (ARRAY['easy'::text, 'mid'::text, 'hard'::text])));
ALTER TABLE public.student_challenge_attempts ADD CONSTRAINT student_challenge_attempts_difficulty_check CHECK ((difficulty = ANY (ARRAY['easy'::text, 'mid'::text, 'hard'::text])));
ALTER TABLE public.diagnostic_test_results ADD CONSTRAINT diagnostic_test_results_result_source_check CHECK ((result_source = ANY (ARRAY['in_app'::text, 'external'::text])));
ALTER TABLE public.ml_topic_daily_metrics ADD CONSTRAINT ml_topic_daily_metrics_retention_range CHECK (((retention_estimate IS NULL) OR ((retention_estimate >= (0)::double precision) AND (retention_estimate <= (1)::double precision))));
ALTER TABLE public.ml_topic_daily_metrics ADD CONSTRAINT ml_topic_daily_metrics_struggle_probability_range CHECK (((struggle_probability IS NULL) OR ((struggle_probability >= (0)::double precision) AND (struggle_probability <= (1)::double precision))));
ALTER TABLE public.student_perks ADD CONSTRAINT student_perks_sly_fox_count_check CHECK ((sly_fox_count >= 0));
ALTER TABLE public.student_challenge_schedule ADD CONSTRAINT student_challenge_schedule_status_check CHECK ((status = ANY (ARRAY['locked'::text, 'available'::text, 'started'::text, 'passed'::text, 'failed'::text, 'expired'::text])));
ALTER TABLE public.student_resource_logs ADD CONSTRAINT student_resource_logs_resource_type_check CHECK ((resource_type = ANY (ARRAY['Visual'::text, 'Auditory'::text, 'Textual'::text])));
ALTER TABLE public.challenge_questions ADD CONSTRAINT challenge_questions_difficulty_check CHECK ((difficulty = ANY (ARRAY['easy'::text, 'mid'::text, 'hard'::text])));
ALTER TABLE public.student_perks ADD CONSTRAINT student_perks_owl_hint_count_check CHECK ((owl_hint_count >= 0));

-- 3. FOREIGN KEYS
ALTER TABLE public.leaderboard_snapshots ADD CONSTRAINT leaderboard_snapshots_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.levels ADD CONSTRAINT levels_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);
ALTER TABLE public.modules ADD CONSTRAINT modules_level_id_fkey FOREIGN KEY (level_id) REFERENCES public.levels(id);
ALTER TABLE public.topics ADD CONSTRAINT topics_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(id);
ALTER TABLE public.student_level_attempts ADD CONSTRAINT student_level_attempts_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.level_assessments(id);
ALTER TABLE public.weekly_challenges ADD CONSTRAINT weekly_challenges_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(id);
ALTER TABLE public.challenge_questions ADD CONSTRAINT challenge_questions_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES public.weekly_challenges(id);
ALTER TABLE public.student_profiles ADD CONSTRAINT student_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.user_streaks ADD CONSTRAINT user_streaks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.user_achievements ADD CONSTRAINT user_achievements_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.user_achievements ADD CONSTRAINT user_achievements_achievement_id_fkey FOREIGN KEY (achievement_id) REFERENCES public.achievements_dictionary(id);
ALTER TABLE public.topic_resources ADD CONSTRAINT topic_resources_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES public.topics(id);
ALTER TABLE public.topic_images ADD CONSTRAINT topic_images_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES public.topics(id);
ALTER TABLE public.diagnostic_question_images ADD CONSTRAINT diagnostic_question_images_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.diagnostic_questions(id);
ALTER TABLE public.calibration_weights ADD CONSTRAINT calibration_weights_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.diagnostic_questions(id);
ALTER TABLE public.diagnostic_test_results ADD CONSTRAINT diagnostic_test_results_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.module_assessments ADD CONSTRAINT module_assessments_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(id);
ALTER TABLE public.module_assessment_questions ADD CONSTRAINT module_assessment_questions_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.module_assessments(id);
ALTER TABLE public.module_assessment_question_images ADD CONSTRAINT module_assessment_question_images_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.module_assessment_questions(id);
ALTER TABLE public.student_module_attempts ADD CONSTRAINT student_module_attempts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.student_module_attempts ADD CONSTRAINT student_module_attempts_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.module_assessments(id);
ALTER TABLE public.level_assessments ADD CONSTRAINT level_assessments_level_id_fkey FOREIGN KEY (level_id) REFERENCES public.levels(id);
ALTER TABLE public.level_assessment_questions ADD CONSTRAINT level_assessment_questions_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.level_assessments(id);
ALTER TABLE public.student_level_attempts ADD CONSTRAINT student_level_attempts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.student_challenge_attempts ADD CONSTRAINT student_challenge_attempts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.student_challenge_attempts ADD CONSTRAINT student_challenge_attempts_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES public.weekly_challenges(id);
ALTER TABLE public.student_progress ADD CONSTRAINT student_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.student_progress ADD CONSTRAINT student_progress_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES public.topics(id);
ALTER TABLE public.content_engagement_logs ADD CONSTRAINT content_engagement_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.content_engagement_logs ADD CONSTRAINT content_engagement_logs_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES public.topics(id);
ALTER TABLE public.student_sentiment_history ADD CONSTRAINT student_sentiment_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.risk_scores ADD CONSTRAINT risk_scores_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.intervention_logs ADD CONSTRAINT intervention_logs_risk_score_id_fkey FOREIGN KEY (risk_score_id) REFERENCES public.risk_scores(id);
ALTER TABLE public.intervention_logs ADD CONSTRAINT intervention_logs_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id);
ALTER TABLE public.ml_daily_metrics ADD CONSTRAINT ml_daily_metrics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.chat_sessions ADD CONSTRAINT chat_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.chat_messages ADD CONSTRAINT chat_messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.chat_sessions(id);
ALTER TABLE public.document_chunks ADD CONSTRAINT document_chunks_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES public.topics(id);
ALTER TABLE public.user_devices ADD CONSTRAINT user_devices_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.in_app_notifications ADD CONSTRAINT in_app_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.challenge_question_images ADD CONSTRAINT challenge_question_images_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.challenge_questions(id);
ALTER TABLE public.ml_topic_daily_metrics ADD CONSTRAINT ml_topic_daily_metrics_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.ml_topic_daily_metrics ADD CONSTRAINT ml_topic_daily_metrics_topic_fk FOREIGN KEY (topic_id) REFERENCES public.topics(id);
ALTER TABLE public.student_perks ADD CONSTRAINT student_perks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.student_challenge_schedule ADD CONSTRAINT student_challenge_schedule_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.student_challenge_schedule ADD CONSTRAINT student_challenge_schedule_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES public.weekly_challenges(id);
ALTER TABLE public.student_resource_logs ADD CONSTRAINT student_resource_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
ALTER TABLE public.student_resource_logs ADD CONSTRAINT student_resource_logs_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES public.topics(id);

-- 4. INDICES
CREATE INDEX IF NOT EXISTS users_pkey ON public.users (id);
CREATE INDEX IF NOT EXISTS achievements_dictionary_pkey ON public.achievements_dictionary (id);
CREATE INDEX IF NOT EXISTS diagnostic_questions_pkey ON public.diagnostic_questions (id);
CREATE INDEX IF NOT EXISTS courses_pkey ON public.courses (id);
CREATE INDEX IF NOT EXISTS student_profiles_pkey ON public.student_profiles (id);
CREATE INDEX IF NOT EXISTS user_streaks_pkey ON public.user_streaks (id);
CREATE INDEX IF NOT EXISTS user_achievements_pkey ON public.user_achievements (id);
CREATE INDEX IF NOT EXISTS user_achievements_user_id_achievement_id_key ON public.user_achievements (achievement_id);
CREATE INDEX IF NOT EXISTS leaderboard_snapshots_pkey ON public.leaderboard_snapshots (id);
CREATE INDEX IF NOT EXISTS leaderboard_snapshots_user_id_track_snapshot_date_key ON public.leaderboard_snapshots (track);
CREATE INDEX IF NOT EXISTS levels_pkey ON public.levels (id);
CREATE INDEX IF NOT EXISTS modules_pkey ON public.modules (id);
CREATE INDEX IF NOT EXISTS topics_pkey ON public.topics (id);
CREATE INDEX IF NOT EXISTS topic_resources_pkey ON public.topic_resources (id);
CREATE INDEX IF NOT EXISTS topic_images_pkey ON public.topic_images (id);
CREATE INDEX IF NOT EXISTS diagnostic_question_images_pkey ON public.diagnostic_question_images (id);
CREATE INDEX IF NOT EXISTS calibration_weights_pkey ON public.calibration_weights (id);
CREATE INDEX IF NOT EXISTS calibration_weights_question_id_answer_value_key ON public.calibration_weights (answer_value);
CREATE INDEX IF NOT EXISTS diagnostic_test_results_pkey ON public.diagnostic_test_results (id);
CREATE INDEX IF NOT EXISTS diagnostic_test_results_user_id_test_number_key ON public.diagnostic_test_results (test_number);
CREATE INDEX IF NOT EXISTS module_assessments_pkey ON public.module_assessments (id);
CREATE INDEX IF NOT EXISTS module_assessment_questions_pkey ON public.module_assessment_questions (id);
CREATE INDEX IF NOT EXISTS module_assessment_question_images_pkey ON public.module_assessment_question_images (id);
CREATE INDEX IF NOT EXISTS student_module_attempts_pkey ON public.student_module_attempts (id);
CREATE INDEX IF NOT EXISTS level_assessments_pkey ON public.level_assessments (id);
CREATE INDEX IF NOT EXISTS level_assessment_questions_pkey ON public.level_assessment_questions (id);
CREATE INDEX IF NOT EXISTS student_level_attempts_pkey ON public.student_level_attempts (id);
CREATE INDEX IF NOT EXISTS weekly_challenges_pkey ON public.weekly_challenges (id);
CREATE INDEX IF NOT EXISTS challenge_questions_pkey ON public.challenge_questions (id);
CREATE INDEX IF NOT EXISTS student_challenge_attempts_pkey ON public.student_challenge_attempts (id);
CREATE INDEX IF NOT EXISTS student_challenge_attempts_user_id_challenge_id_key ON public.student_challenge_attempts (challenge_id);
CREATE INDEX IF NOT EXISTS student_progress_pkey ON public.student_progress (id);
CREATE INDEX IF NOT EXISTS student_progress_user_id_topic_id_key ON public.student_progress (topic_id);
CREATE INDEX IF NOT EXISTS content_engagement_logs_pkey ON public.content_engagement_logs (id);
CREATE INDEX IF NOT EXISTS student_sentiment_history_pkey ON public.student_sentiment_history (id);
CREATE INDEX IF NOT EXISTS risk_scores_pkey ON public.risk_scores (id);
CREATE INDEX IF NOT EXISTS intervention_logs_pkey ON public.intervention_logs (id);
CREATE INDEX IF NOT EXISTS ml_daily_metrics_pkey ON public.ml_daily_metrics (id);
CREATE INDEX IF NOT EXISTS ml_daily_metrics_user_id_metric_date_key ON public.ml_daily_metrics (metric_date);
CREATE INDEX IF NOT EXISTS chat_sessions_pkey ON public.chat_sessions (id);
CREATE INDEX IF NOT EXISTS chat_messages_pkey ON public.chat_messages (id);
CREATE INDEX IF NOT EXISTS document_chunks_pkey ON public.document_chunks (id);
CREATE INDEX IF NOT EXISTS user_devices_pkey ON public.user_devices (id);
CREATE INDEX IF NOT EXISTS user_devices_user_id_fcm_token_key ON public.user_devices (fcm_token);
CREATE INDEX IF NOT EXISTS in_app_notifications_pkey ON public.in_app_notifications (id);
CREATE INDEX IF NOT EXISTS challenge_question_images_pkey ON public.challenge_question_images (id);
CREATE INDEX IF NOT EXISTS ml_topic_daily_metrics_pkey ON public.ml_topic_daily_metrics (id);
CREATE INDEX IF NOT EXISTS ml_topic_daily_metrics_unique_day_user_topic ON public.ml_topic_daily_metrics (user_id);
CREATE INDEX IF NOT EXISTS idx_ml_topic_daily_metrics_user_date ON public.ml_topic_daily_metrics (snapshot_date);
CREATE INDEX IF NOT EXISTS user_activity_log_pkey ON public.user_activity_log (id);
CREATE INDEX IF NOT EXISTS idx_activity_log_user_date ON public.user_activity_log (activity_date);
CREATE INDEX IF NOT EXISTS student_resource_logs_pkey ON public.student_resource_logs (id);
CREATE INDEX IF NOT EXISTS idx_student_topic_resource_unique ON public.student_resource_logs (topic_id);
CREATE INDEX IF NOT EXISTS idx_weekly_challenges_module_title_unique ON public.weekly_challenges (title);
CREATE INDEX IF NOT EXISTS idx_challenge_questions_challenge_difficulty ON public.challenge_questions (difficulty);
CREATE INDEX IF NOT EXISTS student_perks_pkey ON public.student_perks (id);
CREATE INDEX IF NOT EXISTS student_challenge_schedule_pkey ON public.student_challenge_schedule (id);
CREATE INDEX IF NOT EXISTS scs_user_challenge_unique ON public.student_challenge_schedule (challenge_id);
CREATE INDEX IF NOT EXISTS idx_scs_user_status ON public.student_challenge_schedule (status);

-- 5. ROW LEVEL SECURITY (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements_dictionary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topic_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_module_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topic_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboard_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_level_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diagnostic_question_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diagnostic_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_assessment_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calibration_weights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_assessment_question_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_challenge_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_sentiment_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_engagement_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.risk_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intervention_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ml_daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.in_app_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.level_assessment_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.level_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diagnostic_test_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_question_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ml_topic_daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_resource_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_challenge_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_perks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON public.users FOR ALL TO public USING (true);
CREATE POLICY "users: admin read all" ON public.users FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "users: student read own" ON public.users FOR ALL TO authenticated USING ((auth.uid() = id));
CREATE POLICY "users: student update own" ON public.users FOR ALL TO authenticated USING ((auth.uid() = id));
CREATE POLICY "achievements_dictionary: admin delete" ON public.achievements_dictionary FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "achievements_dictionary: admin insert" ON public.achievements_dictionary FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "achievements_dictionary: admin update" ON public.achievements_dictionary FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "achievements_dictionary: authenticated read" ON public.achievements_dictionary FOR ALL TO authenticated USING (true);
CREATE POLICY "modules: admin delete" ON public.modules FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "modules: admin insert" ON public.modules FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "modules: admin read all" ON public.modules FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "modules: admin update" ON public.modules FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "modules: student read active" ON public.modules FOR ALL TO authenticated USING (((is_active = true) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "courses: admin delete" ON public.courses FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "courses: admin insert" ON public.courses FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "courses: admin read all" ON public.courses FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "courses: admin update" ON public.courses FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "courses: student read active" ON public.courses FOR ALL TO authenticated USING (((is_active = true) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "Enable read access for all users" ON public.student_profiles FOR ALL TO public USING (true);
CREATE POLICY "student_profiles: admin read all" ON public.student_profiles FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "student_profiles: admin update all" ON public.student_profiles FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "student_profiles: student read own" ON public.student_profiles FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "student_profiles: student update own" ON public.student_profiles FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "topics: admin delete" ON public.topics FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "topics: admin insert" ON public.topics FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "topics: admin read all" ON public.topics FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "topics: admin update" ON public.topics FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "topics: student read active" ON public.topics FOR ALL TO authenticated USING (((is_active = true) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "user_streaks: admin read all" ON public.user_streaks FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "user_streaks: student insert own" ON public.user_streaks FOR ALL TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "user_streaks: student read own" ON public.user_streaks FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "user_streaks: student update own" ON public.user_streaks FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "topic_resources: admin delete" ON public.topic_resources FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "topic_resources: admin insert" ON public.topic_resources FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "topic_resources: admin read all" ON public.topic_resources FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "topic_resources: admin update" ON public.topic_resources FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "topic_resources: student read" ON public.topic_resources FOR ALL TO authenticated USING (((EXISTS ( SELECT 1
   FROM topics t
  WHERE ((t.id = topic_resources.topic_id) AND (t.is_active = true)))) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "Enable insert for authenticated users only" ON public.student_module_attempts FOR ALL TO authenticated WITH CHECK (true);
CREATE POLICY "student_module_attempts: admin read all" ON public.student_module_attempts FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "student_module_attempts: student read own" ON public.student_module_attempts FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "module_assessments: admin delete" ON public.module_assessments FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "module_assessments: admin insert" ON public.module_assessments FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "module_assessments: admin read all" ON public.module_assessments FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "module_assessments: admin update" ON public.module_assessments FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "module_assessments: student read active" ON public.module_assessments FOR ALL TO authenticated USING (((is_active = true) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "user_achievements: admin read all" ON public.user_achievements FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "user_achievements: student insert own" ON public.user_achievements FOR ALL TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "user_achievements: student read own" ON public.user_achievements FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "topic_images: admin delete" ON public.topic_images FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "topic_images: admin insert" ON public.topic_images FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "topic_images: admin read all" ON public.topic_images FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "topic_images: admin update" ON public.topic_images FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "topic_images: student read" ON public.topic_images FOR ALL TO authenticated USING (((EXISTS ( SELECT 1
   FROM topics t
  WHERE ((t.id = topic_images.topic_id) AND (t.is_active = true)))) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "leaderboard_snapshots: admin read all" ON public.leaderboard_snapshots FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "leaderboard_snapshots: student read" ON public.leaderboard_snapshots FOR ALL TO authenticated USING ((EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text)))));
CREATE POLICY "student_level_attempts: admin read all" ON public.student_level_attempts FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "student_level_attempts: admin update" ON public.student_level_attempts FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "student_level_attempts: student insert own" ON public.student_level_attempts FOR ALL TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "student_level_attempts: student read own" ON public.student_level_attempts FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "diagnostic_question_images: admin delete" ON public.diagnostic_question_images FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "diagnostic_question_images: admin insert" ON public.diagnostic_question_images FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "diagnostic_question_images: admin update" ON public.diagnostic_question_images FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "diagnostic_question_images: authenticated read" ON public.diagnostic_question_images FOR ALL TO authenticated USING (true);
CREATE POLICY "diagnostic_questions: admin delete" ON public.diagnostic_questions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "diagnostic_questions: admin insert" ON public.diagnostic_questions FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "diagnostic_questions: admin update" ON public.diagnostic_questions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "diagnostic_questions: authenticated read" ON public.diagnostic_questions FOR ALL TO authenticated USING (true);
CREATE POLICY "module_assessment_questions: admin delete" ON public.module_assessment_questions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "module_assessment_questions: admin insert" ON public.module_assessment_questions FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "module_assessment_questions: admin read all" ON public.module_assessment_questions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "module_assessment_questions: admin update" ON public.module_assessment_questions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "module_assessment_questions: student read" ON public.module_assessment_questions FOR ALL TO authenticated USING (((EXISTS ( SELECT 1
   FROM module_assessments ma
  WHERE ((ma.id = module_assessment_questions.assessment_id) AND (ma.is_active = true)))) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "levels: admin delete" ON public.levels FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "levels: admin insert" ON public.levels FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "levels: admin read all" ON public.levels FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "levels: admin update" ON public.levels FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "levels: student read active" ON public.levels FOR ALL TO authenticated USING (((is_active = true) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "challenge_questions: admin delete" ON public.challenge_questions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "challenge_questions: admin insert" ON public.challenge_questions FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "challenge_questions: admin read all" ON public.challenge_questions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "challenge_questions: admin update" ON public.challenge_questions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "challenge_questions: student read" ON public.challenge_questions FOR ALL TO authenticated USING (((EXISTS ( SELECT 1
   FROM weekly_challenges wc
  WHERE ((wc.id = challenge_questions.challenge_id) AND (wc.is_active = true) AND (wc.available_from <= CURRENT_DATE) AND (wc.available_until >= CURRENT_DATE)))) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "calibration_weights: admin delete" ON public.calibration_weights FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "calibration_weights: admin insert" ON public.calibration_weights FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "calibration_weights: admin read all" ON public.calibration_weights FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "calibration_weights: admin update" ON public.calibration_weights FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "module_assessment_question_images: admin delete" ON public.module_assessment_question_images FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "module_assessment_question_images: admin insert" ON public.module_assessment_question_images FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "module_assessment_question_images: admin read all" ON public.module_assessment_question_images FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "module_assessment_question_images: admin update" ON public.module_assessment_question_images FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "module_assessment_question_images: student read" ON public.module_assessment_question_images FOR ALL TO authenticated USING (((EXISTS ( SELECT 1
   FROM (module_assessment_questions maq
     JOIN module_assessments ma ON ((ma.id = maq.assessment_id)))
  WHERE ((maq.id = module_assessment_question_images.question_id) AND (ma.is_active = true)))) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "student_challenge_attempts: admin read all" ON public.student_challenge_attempts FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "student_challenge_attempts: student read own" ON public.student_challenge_attempts FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "student_sentiment_history: admin read all" ON public.student_sentiment_history FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "student_progress: admin read all" ON public.student_progress FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "student_progress: student insert own" ON public.student_progress FOR ALL TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "student_progress: student read own" ON public.student_progress FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "student_progress: student update own" ON public.student_progress FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "content_engagement_logs: admin read all" ON public.content_engagement_logs FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "content_engagement_logs: student insert own" ON public.content_engagement_logs FOR ALL TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "risk_scores: admin read all" ON public.risk_scores FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "risk_scores: admin update" ON public.risk_scores FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "intervention_logs: admin insert own" ON public.intervention_logs FOR ALL TO authenticated WITH CHECK (((auth.uid() = admin_id) AND is_admin()));
CREATE POLICY "intervention_logs: admin read own" ON public.intervention_logs FOR ALL TO authenticated USING (((auth.uid() = admin_id) AND is_admin()));
CREATE POLICY "intervention_logs: admin update own" ON public.intervention_logs FOR ALL TO authenticated USING (((auth.uid() = admin_id) AND is_admin()));
CREATE POLICY "ml_daily_metrics: admin read all" ON public.ml_daily_metrics FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "chat_sessions: admin read all" ON public.chat_sessions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "chat_sessions: student insert own" ON public.chat_sessions FOR ALL TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "chat_sessions: student read own" ON public.chat_sessions FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "chat_sessions: student update own" ON public.chat_sessions FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "chat_messages: admin read all" ON public.chat_messages FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "chat_messages: student insert own" ON public.chat_messages FOR ALL TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM chat_sessions cs
  WHERE ((cs.id = chat_messages.session_id) AND (cs.user_id = auth.uid())))));
CREATE POLICY "chat_messages: student read own" ON public.chat_messages FOR ALL TO authenticated USING ((EXISTS ( SELECT 1
   FROM chat_sessions cs
  WHERE ((cs.id = chat_messages.session_id) AND (cs.user_id = auth.uid())))));
CREATE POLICY "document_chunks: admin read all" ON public.document_chunks FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "document_chunks: student read" ON public.document_chunks FOR ALL TO authenticated USING ((EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text)))));
CREATE POLICY "user_devices: admin read all" ON public.user_devices FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "user_devices: student delete own" ON public.user_devices FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "user_devices: student insert own" ON public.user_devices FOR ALL TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "user_devices: student read own" ON public.user_devices FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "user_devices: student update own" ON public.user_devices FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "in_app_notifications: admin insert" ON public.in_app_notifications FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "in_app_notifications: admin read all" ON public.in_app_notifications FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "in_app_notifications: student read own" ON public.in_app_notifications FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "in_app_notifications: student update own" ON public.in_app_notifications FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "level_assessment_questions: admin delete" ON public.level_assessment_questions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "level_assessment_questions: admin insert" ON public.level_assessment_questions FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "level_assessment_questions: admin read all" ON public.level_assessment_questions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "level_assessment_questions: admin update" ON public.level_assessment_questions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "level_assessment_questions: student read" ON public.level_assessment_questions FOR ALL TO authenticated USING (((EXISTS ( SELECT 1
   FROM level_assessments la
  WHERE ((la.id = level_assessment_questions.assessment_id) AND (la.is_active = true)))) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "level_assessments: admin delete" ON public.level_assessments FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "level_assessments: admin insert" ON public.level_assessments FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "level_assessments: admin read all" ON public.level_assessments FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "level_assessments: admin update" ON public.level_assessments FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "level_assessments: student read active" ON public.level_assessments FOR ALL TO authenticated USING (((is_active = true) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "weekly_challenges: admin delete" ON public.weekly_challenges FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "weekly_challenges: admin insert" ON public.weekly_challenges FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "weekly_challenges: admin read all" ON public.weekly_challenges FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "weekly_challenges: admin update" ON public.weekly_challenges FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "weekly_challenges: student read active" ON public.weekly_challenges FOR ALL TO authenticated USING (((is_active = true) AND (available_from <= CURRENT_DATE) AND (available_until >= CURRENT_DATE) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "diagnostic_test_results: admin read all" ON public.diagnostic_test_results FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "diagnostic_test_results: admin update" ON public.diagnostic_test_results FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "diagnostic_test_results: student insert own" ON public.diagnostic_test_results FOR ALL TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "diagnostic_test_results: student read own" ON public.diagnostic_test_results FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "challenge_question_images: admin delete" ON public.challenge_question_images FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "challenge_question_images: admin insert" ON public.challenge_question_images FOR ALL TO authenticated WITH CHECK (is_admin());
CREATE POLICY "challenge_question_images: admin read all" ON public.challenge_question_images FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "challenge_question_images: admin update" ON public.challenge_question_images FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "challenge_question_images: student read" ON public.challenge_question_images FOR ALL TO authenticated USING (((EXISTS ( SELECT 1
   FROM (challenge_questions cq
     JOIN weekly_challenges wc ON ((wc.id = cq.challenge_id)))
  WHERE ((cq.id = challenge_question_images.question_id) AND (wc.is_active = true) AND (wc.available_from <= CURRENT_DATE) AND (wc.available_until >= CURRENT_DATE)))) AND (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'student'::text))))));
CREATE POLICY "Admins can manage topic metrics" ON public.ml_topic_daily_metrics FOR ALL TO authenticated USING (current_user_is_admin()) WITH CHECK (current_user_is_admin());
CREATE POLICY "Admins can read all topic metrics" ON public.ml_topic_daily_metrics FOR ALL TO authenticated USING (current_user_is_admin());
CREATE POLICY "Students can read own topic metrics" ON public.ml_topic_daily_metrics FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "Users can insert own activity" ON public.user_activity_log FOR ALL TO authenticated WITH CHECK ((user_id = auth.uid()));
CREATE POLICY "Users can read own activity" ON public.user_activity_log FOR ALL TO authenticated USING ((user_id = auth.uid()));
CREATE POLICY "student_resource_logs: admin read all" ON public.student_resource_logs FOR ALL TO authenticated USING (is_admin());
CREATE POLICY "student_resource_logs: student insert own" ON public.student_resource_logs FOR ALL TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "student_resource_logs: student read own" ON public.student_resource_logs FOR ALL TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "scs: admin read all" ON public.student_challenge_schedule FOR ALL TO public USING (is_admin());
CREATE POLICY "scs: student read own" ON public.student_challenge_schedule FOR ALL TO public USING ((auth.uid() = user_id));
CREATE POLICY "student_perks: admin read all" ON public.student_perks FOR ALL TO public USING (is_admin());
CREATE POLICY "student_perks: student read own" ON public.student_perks FOR ALL TO public USING ((auth.uid() = user_id));