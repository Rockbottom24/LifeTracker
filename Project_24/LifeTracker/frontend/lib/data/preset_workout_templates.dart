import '../models/workout/workout_template_model.dart';

const List<WorkoutTemplateModel> kPresetWorkoutTemplates = [
  // ── Week 1 & 4 ─────────────────────────────────────────────────────────────
  WorkoutTemplateModel(
    id: -101,
    name: 'W1/W4: Push Day',
    category: 'PUSH',
    description: 'Flat Press, Machine Fly, Shoulder Press, Side Raise, Pushdown, Seated Dips',
    isPreset: true,
    exercises: [
      WorkoutTemplateExerciseModel(sequenceOrder: 1, exerciseName: 'Flat Press', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 2, exerciseName: 'Machine Fly', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 3, exerciseName: 'Shoulder Press', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 4, exerciseName: 'Side Raise', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 5, exerciseName: 'Rope Pushdown', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 6, exerciseName: 'Seated Dips', sets: 3, reps: '12-15', restSeconds: 45),
    ],
  ),
  WorkoutTemplateModel(
    id: -102,
    name: 'W1/W4: Pull Day',
    category: 'PULL',
    description: 'Lat Pulldown, Single Hand DB Row, Reverse Flys, DB Curls, DB Concentration, Shrugs',
    isPreset: true,
    exercises: [
      WorkoutTemplateExerciseModel(sequenceOrder: 1, exerciseName: 'Lat Pulldown', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 2, exerciseName: 'Single Hand DB Row', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 3, exerciseName: 'Reverse Flys', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 4, exerciseName: 'Dumbbell Curls', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 5, exerciseName: 'DB Concentration Curl', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 6, exerciseName: 'Shrugs', sets: 3, reps: '10-12', restSeconds: 45),
    ],
  ),
  WorkoutTemplateModel(
    id: -103,
    name: 'W1/W4: Leg Day',
    category: 'LEGS',
    description: 'Squats, Leg Press, Leg Extension, Lunges, Leg Curls, Standing Calf Raise',
    isPreset: true,
    exercises: [
      WorkoutTemplateExerciseModel(sequenceOrder: 1, exerciseName: 'Squats', sets: 3, reps: '8-10', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 2, exerciseName: 'Leg Press', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 3, exerciseName: 'Leg Extension', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 4, exerciseName: 'Lunges', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 5, exerciseName: 'Leg Curls', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 6, exerciseName: 'Standing Calf Raise', sets: 3, reps: '20-25', restSeconds: 45),
    ],
  ),

  // ── Week 2 & 5 ─────────────────────────────────────────────────────────────
  WorkoutTemplateModel(
    id: -104,
    name: 'W2/W5: Push Day',
    category: 'PUSH',
    description: 'Incline Chest, DB Flies, Front Raise, Lateral Raise, Over Hand Ext, Tricep Kickback',
    isPreset: true,
    exercises: [
      WorkoutTemplateExerciseModel(sequenceOrder: 1, exerciseName: 'Incline Chest Press', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 2, exerciseName: 'DB Flies (Flat)', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 3, exerciseName: 'Front Raise', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 4, exerciseName: 'Lateral Raise', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 5, exerciseName: 'Over Hand Extension', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 6, exerciseName: 'Tricep Kick Back', sets: 3, reps: '12-15', restSeconds: 45),
    ],
  ),
  WorkoutTemplateModel(
    id: -105,
    name: 'W2/W5: Pull Day',
    category: 'PULL',
    description: 'Deadlift, High Row, Seated Row, Upright Row, Preacher Curl, Incline DB Curl',
    isPreset: true,
    exercises: [
      WorkoutTemplateExerciseModel(sequenceOrder: 1, exerciseName: 'Deadlift', sets: 3, reps: '8-10', restSeconds: 60),
      WorkoutTemplateExerciseModel(sequenceOrder: 2, exerciseName: 'High Row', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 3, exerciseName: 'Seated Row', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 4, exerciseName: 'Upright Row', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 5, exerciseName: 'Preacher Curl', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 6, exerciseName: 'Incline DB Curl', sets: 3, reps: '12-15', restSeconds: 45),
    ],
  ),
  WorkoutTemplateModel(
    id: -106,
    name: 'W2/W5: Legs Day',
    category: 'LEGS',
    description: 'Sumo Squats, Seated Leg Press, Bulgarian Split Squats, Leg Ext, Adductor Press, Calf Raise',
    isPreset: true,
    exercises: [
      WorkoutTemplateExerciseModel(sequenceOrder: 1, exerciseName: 'Sumo Squats', sets: 3, reps: '10-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 2, exerciseName: 'Seated Leg Press', sets: 3, reps: '10-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 3, exerciseName: 'Bulgarian Split Squats', sets: 3, reps: '10-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 4, exerciseName: 'Leg Extension', sets: 3, reps: '10-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 5, exerciseName: 'Adductor Press', sets: 3, reps: '10-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 6, exerciseName: 'Calf Raise (Seated)', sets: 3, reps: '15-25', restSeconds: 45),
    ],
  ),

  // ── Week 3 & 6 ─────────────────────────────────────────────────────────────
  WorkoutTemplateModel(
    id: -107,
    name: 'W3/W6: Push Day',
    category: 'PUSH',
    description: 'Decline Chest Press, Cable Crossover, BB Shoulder Press, Y-Raise, Reverse Push Down, Overhead Ex',
    isPreset: true,
    exercises: [
      WorkoutTemplateExerciseModel(sequenceOrder: 1, exerciseName: 'Decline Chest Press', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 2, exerciseName: 'Cable Crossover', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 3, exerciseName: 'BB Shoulder Press', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 4, exerciseName: 'Y - Raise', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 5, exerciseName: 'Reverse Push Down', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 6, exerciseName: 'Single Hand Overhead Ex', sets: 3, reps: '12-15', restSeconds: 45),
    ],
  ),
  WorkoutTemplateModel(
    id: -108,
    name: 'W3/W6: Pull Day',
    category: 'PULL',
    description: 'Deadlift, Close Grip Pulldown, Machine Row, Face Pull, BB Curls, Hammer Curls',
    isPreset: true,
    exercises: [
      WorkoutTemplateExerciseModel(sequenceOrder: 1, exerciseName: 'Deadlift', sets: 3, reps: '8-10', restSeconds: 60),
      WorkoutTemplateExerciseModel(sequenceOrder: 2, exerciseName: 'Close Grip Pulldown', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 3, exerciseName: 'Machine Row', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 4, exerciseName: 'Face Pull', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 5, exerciseName: 'BB Curls', sets: 3, reps: '12-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 6, exerciseName: 'Hammer Curls', sets: 3, reps: '12-15', restSeconds: 45),
    ],
  ),
  WorkoutTemplateModel(
    id: -109,
    name: 'W3/W6: Lower Body',
    category: 'LEGS',
    description: 'Machine Squats, 90 Deg Leg Press, Weighted Walking Lunges, Leg Ext, Abductor Press, Calf Raise',
    isPreset: true,
    exercises: [
      WorkoutTemplateExerciseModel(sequenceOrder: 1, exerciseName: 'Machine Squats', sets: 3, reps: '10-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 2, exerciseName: '90 deg. Leg Press', sets: 3, reps: '10-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 3, exerciseName: 'Weighted Walking Lunges', sets: 3, reps: '10-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 4, exerciseName: 'Leg Extension', sets: 3, reps: '10-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 5, exerciseName: 'Abductor Press', sets: 3, reps: '10-15', restSeconds: 45),
      WorkoutTemplateExerciseModel(sequenceOrder: 6, exerciseName: 'Calf Raise (weighted)', sets: 3, reps: '15-25', restSeconds: 45),
    ],
  ),

  // ── Specialty Routines ──────────────────────────────────────────────────────
  WorkoutTemplateModel(
    id: -110,
    name: 'CrossFit / HIIT Burner',
    category: 'HIIT',
    description: 'High intensity conditioning session',
    isPreset: true,
    exercises: [
      WorkoutTemplateExerciseModel(sequenceOrder: 1, exerciseName: 'Kettlebell Swings', sets: 4, reps: '20', restSeconds: 30),
      WorkoutTemplateExerciseModel(sequenceOrder: 2, exerciseName: 'Box Jumps', sets: 4, reps: '15', restSeconds: 30),
      WorkoutTemplateExerciseModel(sequenceOrder: 3, exerciseName: 'Burpees', sets: 4, reps: '15', restSeconds: 30),
      WorkoutTemplateExerciseModel(sequenceOrder: 4, exerciseName: 'Battle Ropes', sets: 4, reps: '30 sec', restSeconds: 30),
    ],
  ),
  WorkoutTemplateModel(
    id: -111,
    name: 'Full Body Armor',
    category: 'FULL_BODY',
    description: 'Compound resistance training for total body power',
    isPreset: true,
    exercises: [
      WorkoutTemplateExerciseModel(sequenceOrder: 1, exerciseName: 'Barbell Squats', sets: 3, reps: '10', restSeconds: 60),
      WorkoutTemplateExerciseModel(sequenceOrder: 2, exerciseName: 'Bench Press', sets: 3, reps: '10', restSeconds: 60),
      WorkoutTemplateExerciseModel(sequenceOrder: 3, exerciseName: 'Bent Over Row', sets: 3, reps: '10', restSeconds: 60),
      WorkoutTemplateExerciseModel(sequenceOrder: 4, exerciseName: 'Overhead Press', sets: 3, reps: '10', restSeconds: 60),
    ],
  ),

  // ── Rest Day ───────────────────────────────────────────────────────────────
  WorkoutTemplateModel(
    id: -112,
    name: 'Rest & Active Recovery Day',
    category: 'REST',
    description: 'Active recovery, light mobility stretching, walking, and muscle repair',
    isPreset: true,
    exercises: [
      WorkoutTemplateExerciseModel(sequenceOrder: 1, exerciseName: 'Light Mobility & Foam Rolling', sets: 1, reps: '15 min', restSeconds: 0),
      WorkoutTemplateExerciseModel(sequenceOrder: 2, exerciseName: 'Gentle Walk / Cardio', sets: 1, reps: '20 min', restSeconds: 0),
      WorkoutTemplateExerciseModel(sequenceOrder: 3, exerciseName: 'Full Body Static Stretching', sets: 1, reps: '10 min', restSeconds: 0),
    ],
  ),
];
