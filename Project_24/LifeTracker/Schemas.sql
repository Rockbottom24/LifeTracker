1 USER

CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100),
    age INT,
    gender VARCHAR(20),
    height_cm DECIMAL(5,2),
    weight_kg DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


2 GOALS

CREATE TABLE goals (
    goal_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(user_id),
    calories_target INT,
    protein_target DECIMAL(6,2),
    carbs_target DECIMAL(6,2),
    fat_target DECIMAL(6,2),
    fiber_target DECIMAL(6,2),
    water_target DECIMAL(6,2),
    sleep_target DECIMAL(4,2)
);


3 HABITS

CREATE TABLE habits (
    habit_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(user_id),
    habit_name VARCHAR(100),
    category VARCHAR(50),
    reminder_time TIME,
    frequency VARCHAR(30),
    is_active BOOLEAN DEFAULT TRUE
);



4 HABIT LOGS

CREATE TABLE habit_logs (
    habit_log_id BIGSERIAL PRIMARY KEY,
    habit_id BIGINT REFERENCES habits(habit_id),
    completed_date DATE,
    completed_time TIME,
    status BOOLEAN
);



5 EXERCISE LIBRARY

CREATE TABLE exercises (
    exercise_id BIGSERIAL PRIMARY KEY,
    exercise_name VARCHAR(100),
    muscle_group VARCHAR(50),
    equipment VARCHAR(50),
    instructions TEXT
);