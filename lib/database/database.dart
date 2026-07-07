import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';
import '../plugins/gallery/gallery_tables.dart';
import '../plugins/medication/medication_tables.dart';
import '../plugins/nutrition/nutrition_tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Species,
    Users,
    Rooms,
    Enclosures,
    Birds,
    Weights,
    Tasks,
    AlertRecords,
    SyncQueue,
    DrugLibrary,
    DrugFormulations,
    DiseaseCatalog,
    DoseRules,
    Medications,
    FeedingRecords,
    SideEffectRecords,
    StopConditions,
    BreedingPairs,
    BreedingRecords,
    Eggs,
    MatingEvents,
    ActivityLogs,
    BirdPhotos,
    BirdAvatars,
    // Nutrition plugin tables from lib/plugins/nutrition/nutrition_tables.dart
    Foods,
    Blends,
    BlendItems,
    BlendBindings,
    FeedingPlans,
    FeedingPlanMeals,
    FeedingPlanMealRecipes,
    // Stage plugin — 鸟的生理阶段缓存
    BirdStages
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试用构造器——内存数据库
  AppDatabase.test() : super(DatabaseConnection(NativeDatabase.memory()));

  // ponytail: file-based DB for backup/restore testing. Add when prod needs custom paths.
  AppDatabase.file(File file) : super(DatabaseConnection(NativeDatabase(file)));

  @override
  int get schemaVersion => 21;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes(m);
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 3) {
            // v2 → v3: add weigh interval columns
            await m.addColumn(species, species.nestlingWeighIntervalDays);
            await m.addColumn(species, species.juvenileWeighIntervalDays);
            await m.addColumn(birds, birds.weighIntervalDays);
          }
          if (from < 4) await _createIndexes(m);
          if (from < 5) {
            // v4 → v5: medication tracking tables
            await m.createTable(medications);
          }
          if (from < 6) {
            // v5 → v6: enclosures (containers within rooms)
            await m.createTable(enclosures);
            await m.addColumn(birds, birds.enclosureId);
          }
          if (from < 7) {
            // v6 → v7: baseline weight + weaning override
            await m.addColumn(birds, birds.manualBaselineG);
            await m.addColumn(birds, birds.weaningOverride);
          }
          if (from < 8) {
            // v7 → v8: breeding plugin tables
            await m.createTable(breedingPairs);
            await m.createTable(breedingRecords);
            await m.createTable(eggs);
            await m.createTable(matingEvents);
          }
          if (from < 9) {
            // v8 → v9: tasks.taskType + metadata; drop medicationLogs
            await m.addColumn(tasks, tasks.taskType);
            await m.addColumn(tasks, tasks.metadata);
            await m.deleteTable('medication_logs');
          }
          if (from < 10) {
            // v9 → v10: alert_records.severity
            await m.addColumn(alertRecords, alertRecords.severity);
          }
          if (from < 11) {
            // v10 → v11: unified activity log table
            await m.createTable(activityLogs);
            await m.createIndex(Index('activity_logs',
                'CREATE INDEX IF NOT EXISTS idx_activity_logs_bird_time ON activity_logs(bird_id, operated_at DESC)'));
          }
          if (from < 12) {
            // v11 → v12: perf indexes for filtered lookups
            await m.createIndex(Index('birds',
                'CREATE INDEX IF NOT EXISTS idx_birds_room ON birds(room_id)'));
            await m.createIndex(Index('birds',
                'CREATE INDEX IF NOT EXISTS idx_birds_enclosure ON birds(enclosure_id)'));
            await m.createIndex(Index('alert_records',
                'CREATE INDEX IF NOT EXISTS idx_alert_records_lookup ON alert_records(bird_id, alert_type, is_read, created_at)'));
            await m.createIndex(Index('medications',
                'CREATE INDEX IF NOT EXISTS idx_medications_bird ON medications(bird_id)'));
          }
          if (from < 13) {
            // v12 → v13: tasks.deadline — 逾期截止时间，生成时算好写入
            await m.addColumn(tasks, tasks.deadline);
            // 存量未完成任务用 dueDate 回填 deadline，防止永久卡在"待完成"
            await customStatement(
                "UPDATE tasks SET deadline = due_date WHERE deadline IS NULL AND status IN ('待完成', '逾期')");
          }
          // Track whether birdPhotos was just created in this migration call.
          // The current BirdPhotos class already includes mediaType/videoFilePath/
          // thumbnailPath — so when from < 14, createTable adds all of them and the
          // later addColumn steps must be skipped.
          final birdPhotosJustCreated = from < 14;
          if (birdPhotosJustCreated) {
            // v13 → v14: gallery plugin — bird photos & avatars
            await m.createTable(birdPhotos);
            await m.createTable(birdAvatars);
            await m.createIndex(Index('bird_photos',
                'CREATE INDEX IF NOT EXISTS idx_bird_photos_bird ON bird_photos(bird_id, sort_order ASC)'));
          }
          if (from < 15 && !birdPhotosJustCreated) {
            // v14 → v15: motion photo support — mediaType + video path
            await m.addColumn(birdPhotos, birdPhotos.mediaType);
            await m.addColumn(birdPhotos, birdPhotos.videoFilePath);
          }
          if (from < 16 && !birdPhotosJustCreated) {
            // v15 → v16: animated WebP thumbnail path for motion photos
            await m.addColumn(birdPhotos, birdPhotos.thumbnailPath);
          }
          if (from < 17) {
            // v16 → v17: drug dosage library system (breaking change)
            // Delete old medications table & its index
            await m.deleteTable('medications');
            // Add species weight range columns
            await m.addColumn(species, species.minWeightG);
            await m.addColumn(species, species.maxWeightG);
            // Create new medication system tables
            await m.createTable(drugLibrary);
            await m.createTable(drugFormulations);
            await m.createTable(diseaseCatalog);
            await m.createTable(doseRules);
            await m.createTable(medications);
            await m.createTable(feedingRecords);
            await m.createTable(sideEffectRecords);
            await m.createTable(stopConditions);
            // Performance indexes for new tables
            await m.createIndex(Index('dose_rules',
                'CREATE INDEX IF NOT EXISTS idx_dose_rules_lookup ON dose_rules(drug_id, disease_id, species_id)'));
            await m.createIndex(Index('drug_formulations',
                'CREATE INDEX IF NOT EXISTS idx_drug_formulations_drug ON drug_formulations(drug_id)'));
            await m.createIndex(Index('feeding_records',
                'CREATE INDEX IF NOT EXISTS idx_feeding_records_med ON feeding_records(medication_id, fed_at DESC)'));
            await m.createIndex(Index('medications',
                'CREATE INDEX IF NOT EXISTS idx_medications_bird ON medications(bird_id)'));
            await m.createIndex(Index('side_effect_records',
                'CREATE INDEX IF NOT EXISTS idx_side_effect_records_med ON side_effect_records(medication_id)'));
          }
          if (from < 18) {
            // v17 → v18: nutrition plugin — foods, recipes, bindings, meals, items
            await m.createTable(foods);
            await m.createIndex(Index('foods',
                'CREATE INDEX IF NOT EXISTS idx_foods_category ON foods(category)'));
          }
          if (from < 19) {
            // v18 → v19: nutrition refactor — Blend(%配方) + FeedingPlan(餐饮方案)
            // 1. Birds 新增 stageOverride（手动阶段覆盖）
            await m.addColumn(birds, birds.stageOverride);
            // 2. 新建 6 张表
            await m.createTable(blends);
            await m.createTable(blendItems);
            await m.createTable(blendBindings);
            await m.createTable(feedingPlans);
            await m.createTable(feedingPlanMeals);
            await m.createTable(feedingPlanMealRecipes);
            // 3. 索引
            await m.createIndex(Index('blend_bindings',
                'CREATE INDEX IF NOT EXISTS idx_blend_bindings_lookup ON blend_bindings(species_id, stage)'));
            await m.createIndex(Index('blend_items',
                'CREATE INDEX IF NOT EXISTS idx_blend_items_blend ON blend_items(blend_id)'));
            await m.createIndex(Index('feeding_plans',
                'CREATE INDEX IF NOT EXISTS idx_feeding_plans_bird ON feeding_plans(bird_id, stage)'));
            await m.createIndex(Index('feeding_plan_meals',
                'CREATE INDEX IF NOT EXISTS idx_fpm_plan ON feeding_plan_meals(plan_id, sort_order)'));
            await m.createIndex(Index('feeding_plan_meal_recipes',
                'CREATE INDEX IF NOT EXISTS idx_fpmr_meal ON feeding_plan_meal_recipes(plan_meal_id)'));
            // 4. 旧表已弃用（recipes/recipe_bindings/recipe_meals/recipe_meal_items）
            //    不删除，仅不再注册到 Drift，避免影响已存数据
          }
          if (from < 20) {
            // v19 → v20: stage 插件 —— 鸟的生理阶段缓存表
            await m.createTable(birdStages);
            await m.createIndex(Index('bird_stages',
                'CREATE UNIQUE INDEX IF NOT EXISTS idx_bird_stages_bird ON bird_stages(bird_id)'));
          }
          if (from < 21) {
            // v20 → v21: 高频查询路径补索引，消除全表扫描
            // species.name —— 按名查找/模糊搜索；users.username —— 登录与去重
            // rooms.assigned_user_id —— 派发任务按负责人筛选；enclosures.room_id —— 房间→容器层级查询
            await m.createIndex(Index('species',
                'CREATE INDEX IF NOT EXISTS idx_species_name ON species(name)'));
            await m.createIndex(Index('users',
                'CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)'));
            await m.createIndex(Index('rooms',
                'CREATE INDEX IF NOT EXISTS idx_rooms_assigned_user ON rooms(assigned_user_id)'));
            await m.createIndex(Index('enclosures',
                'CREATE INDEX IF NOT EXISTS idx_enclosures_room ON enclosures(room_id)'));
          }
        },
      );

  Future<void> _createIndexes(Migrator m) async {
    await m.createIndex(Index('weights',
        'CREATE INDEX IF NOT EXISTS idx_weights_bird_date ON weights(bird_id, recorded_at DESC)'));
    await m.createIndex(Index('tasks',
        'CREATE INDEX IF NOT EXISTS idx_tasks_due_status ON tasks(due_date, status)'));
    await m.createIndex(Index('activity_logs',
        'CREATE INDEX IF NOT EXISTS idx_activity_logs_bird_time ON activity_logs(bird_id, operated_at DESC)'));
    // v12: perf indexes for filtered lookups (getByRoom / getByEnclosure / alert dedup / medication)
    await m.createIndex(Index('birds',
        'CREATE INDEX IF NOT EXISTS idx_birds_room ON birds(room_id)'));
    await m.createIndex(Index('birds',
        'CREATE INDEX IF NOT EXISTS idx_birds_enclosure ON birds(enclosure_id)'));
    await m.createIndex(Index('alert_records',
        'CREATE INDEX IF NOT EXISTS idx_alert_records_lookup ON alert_records(bird_id, alert_type, is_read, created_at)'));
    await m.createIndex(Index('medications',
        'CREATE INDEX IF NOT EXISTS idx_medications_bird ON medications(bird_id)'));
    // v21: 高频查询路径补索引（与 onUpgrade from < 21 保持一致）
    await m.createIndex(Index('species',
        'CREATE INDEX IF NOT EXISTS idx_species_name ON species(name)'));
    await m.createIndex(Index('users',
        'CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)'));
    await m.createIndex(Index('rooms',
        'CREATE INDEX IF NOT EXISTS idx_rooms_assigned_user ON rooms(assigned_user_id)'));
    await m.createIndex(Index('enclosures',
        'CREATE INDEX IF NOT EXISTS idx_enclosures_room ON enclosures(room_id)'));
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'weight_nest_mvp.db');
  }
}
