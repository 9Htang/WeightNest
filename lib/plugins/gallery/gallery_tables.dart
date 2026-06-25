import 'package:drift/drift.dart';
import '../../database/tables.dart';

/// Bird photos table — one bird can have many photos.
class BirdPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get birdId =>
      integer().references(Birds, #id, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()(); // relative path: gallery/{birdId}/photo_ts.jpg
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get mediaType => text().withDefault(const Constant('photo'))(); // 'photo' or 'motion_photo'
  TextColumn get videoFilePath => text().nullable()(); // relative path to extracted .mp4 for motion photos
  TextColumn get thumbnailPath => text().nullable()(); // relative path to animated WebP thumbnail (generated from video)
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Bird avatars table — one avatar per bird (unique constraint on birdId).
class BirdAvatars extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get birdId =>
      integer().unique().references(Birds, #id, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()(); // relative path: gallery/{birdId}/avatar.jpg
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
