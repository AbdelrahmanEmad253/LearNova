This directory contains the database structure for LearNova, powered by Supabase. The database uses PostgreSQL with strict Row Level Security (RLS) policies to ensure data privacy and secure access for both students and administrators.  
*(Note: If you are setting up the initial database triggers in a fresh environment, be sure to reference the file named "Supabase Snippet Auto-create user profiles on signup (1).csv" verbatim to initialize the authentication synchronization.)*

## **Core Schema Domains**

### **1\. Users & Identities**

Handles authentication, role-based access, and core learner data.

* **users**: Secure schema mapped directly to Supabase Auth. Differentiates between student and admin roles.  
* **student\_profiles**: Stores calculated attributes including accumulated XP, assigned\_track (DA / DE / DS), and Bayesian alpha vectors (visual, auditory, textual) for the learning style engine.  
* **student\_perks**: Tracks active inventory items for gamification loops (e.g., owl\_hint\_count and sly\_fox\_count).

### **2\. Curriculum Core**

The hierarchical structure of all educational material.

* **courses**: Top-level tracks (Foundation, DA, DE, DS).  
* **levels & modules**: Sequential breakdown of tracks, each carrying specific XP rewards.  
* **topics**: Individual lesson containers.  
* **topic\_resources**: The adaptive content layer. Stores the format\_type (Visual, Auditory, Textual) and external resource URLs to morph content based on the user's neurology.  
* **topic\_images**: Visual assets associated with topics.

### **3\. Diagnostics & Assessments**

Powers the Smart Compatibility Engine and ongoing knowledge checks.

* **diagnostic\_questions & diagnostic\_test\_results**: Manages the 5-stage onboarding calibration.  
* **calibration\_weights**: Maps diagnostic answers to the underlying tracks to feed the routing algorithm.  
* **module\_assessments & level\_assessments**: Mid-point and milestone examinations with dynamically scaled XP rewards based on tiers (easy, mid, hard).  
* **student\_module\_attempts & student\_level\_attempts**: Logs JSON answers, calculated scores, pass/fail status, and AI grading rubrics.

### **4\. Progress & Gamification**

Combats the isolation of online learning by driving intrinsic motivation.

* **student\_progress**: Tracks granular completion status per topic.  
* **user\_streaks**: Manages current\_streak\_days and longest\_streak\_days.  
* **user\_achievements & achievements\_dictionary**: Threshold-based badging system.  
* **leaderboard\_snapshots**: Records historical rank and XP by track to generate competitive standings.  
* **weekly\_challenges & student\_challenge\_schedule**: Time-boxed assignments and user-specific participation logs.

### **5\. AI Mentor (Mitchy) & RAG Context**

Manages the real-time AI conversational interface and contextual awareness.

* **chat\_sessions & chat\_messages**: Logs history, the detected learning state, and specific Mitchy actions/hints.  
* **document\_chunks**: Stores vector embeddings (USER-DEFINED data type) to provide semantic search context for Mitchy's RAG architecture.

### **6\. Risk Analysis & Machine Learning Metrics**

The backend tables that power the early-intervention burnout detection.

* **content\_engagement\_logs**: Measures time\_spent\_seconds and generates an engagement\_score.  
* **ml\_daily\_metrics & ml\_topic\_daily\_metrics**: Stores rolling snapshots of concept\_decay\_score, engagement\_velocity, topic\_struggle\_index, and retention\_estimate.  
* **risk\_scores**: Analyzes the ML metrics to output a risk\_level (low, medium, high, critical).  
* **intervention\_logs**: Admin dashboard table for tracking human mentorship actions when a high-risk alert triggers.

### **7\. App Infrastructure**

* **user\_devices**: Stores FCM tokens and platform identification for push routing.  
* **in\_app\_notifications**: Manages internal alerts for unlocked achievements, burnout warnings, new challenges, and level progression.

## **Edge Functions & Triggers**

The database utilizes native PostgreSQL triggers for critical workflows (like calculating streaks or updating aggregate XP) to minimize round-trips. Supabase Edge Functions (run-scoring-engine, mitchy-chat, submit-module-attempt) handle the heavier logic and interactions with external AI APIs.

## **Security (Row Level Security)**

Strict RLS policies are applied across all tables to enforce zero-trust data access:

* **Admins:** PERMISSIVE full access validated via an is\_admin() custom database function.  
* **Students:** Constrained to auth.uid() \= user\_id for reading and writing activity logs, and limited strictly to reading material where is\_active \= true.