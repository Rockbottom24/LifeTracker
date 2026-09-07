// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkoutDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkoutTemplatesTableTable get workoutTemplatesTable =>
      attachedDatabase.workoutTemplatesTable;
  $WorkoutTemplateExercisesTableTable get workoutTemplateExercisesTable =>
      attachedDatabase.workoutTemplateExercisesTable;
  $WorkoutScheduleTableTable get workoutScheduleTable =>
      attachedDatabase.workoutScheduleTable;
  WorkoutDaoManager get managers => WorkoutDaoManager(this);
}

class WorkoutDaoManager {
  final _$WorkoutDaoMixin _db;
  WorkoutDaoManager(this._db);
  $$WorkoutTemplatesTableTableTableManager get workoutTemplatesTable =>
      $$WorkoutTemplatesTableTableTableManager(
        _db.attachedDatabase,
        _db.workoutTemplatesTable,
      );
  $$WorkoutTemplateExercisesTableTableTableManager
  get workoutTemplateExercisesTable =>
      $$WorkoutTemplateExercisesTableTableTableManager(
        _db.attachedDatabase,
        _db.workoutTemplateExercisesTable,
      );
  $$WorkoutScheduleTableTableTableManager get workoutScheduleTable =>
      $$WorkoutScheduleTableTableTableManager(
        _db.attachedDatabase,
        _db.workoutScheduleTable,
      );
}
