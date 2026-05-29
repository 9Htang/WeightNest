DELETE FROM weight_records;

DO $$
DECLARE
  b1_id INT; b2_id INT; b3_id INT; b4_id INT; b5_id INT;
BEGIN
  SELECT id INTO b1_id FROM birds WHERE uuid = 'b001-0000-0000-000000000001';
  SELECT id INTO b2_id FROM birds WHERE uuid = 'b001-0000-0000-000000000002';
  SELECT id INTO b3_id FROM birds WHERE uuid = 'b001-0000-0000-000000000003';
  SELECT id INTO b4_id FROM birds WHERE uuid = 'b001-0000-0000-000000000004';
  SELECT id INTO b5_id FROM birds WHERE uuid = 'b001-0000-0000-000000000005';

  FOR i IN 1..30 LOOP
    INSERT INTO weight_records (uuid, bird_id, weight_g, recorded_at, is_fasting)
    VALUES (gen_random_uuid(), b1_id, 41.0 + (i*0.13) + (random()*0.5 - 0.25), '2026-04-28'::date + i, true);
  END LOOP;

  FOR i IN 1..30 LOOP
    INSERT INTO weight_records (uuid, bird_id, weight_g, recorded_at, is_fasting)
    VALUES (gen_random_uuid(), b2_id, 116.5 + (i*0.38) + (random()*1.0 - 0.5), '2026-04-28'::date + i, true);
  END LOOP;

  FOR i IN 1..30 LOOP
    INSERT INTO weight_records (uuid, bird_id, weight_g, recorded_at, is_fasting)
    VALUES (gen_random_uuid(), b3_id,
      CASE WHEN i <= 10 THEN 33.5 - i*0.5
           WHEN i <= 15 THEN 28.5 + (i-10)*0.3
           ELSE 30.0 + (i-15)*0.35
      END + (random()*0.4 - 0.2), '2026-04-28'::date + i, true);
  END LOOP;

  FOR i IN 1..30 LOOP
    INSERT INTO weight_records (uuid, bird_id, weight_g, recorded_at, is_fasting)
    VALUES (gen_random_uuid(), b4_id,
      CASE WHEN i <= 12 THEN 92.0 - i*0.5
           WHEN i <= 18 THEN 86.0 + (i-12)*0.55
           ELSE 89.5 + (i-18)*0.5
      END + (random()*1.0 - 0.5), '2026-04-28'::date + i, true);
  END LOOP;

  FOR i IN 1..30 LOOP
    INSERT INTO weight_records (uuid, bird_id, weight_g, recorded_at, is_fasting)
    VALUES (gen_random_uuid(), b5_id, 975 + (i*3.5) + (random()*5 - 2.5), '2026-04-28'::date + i, true);
  END LOOP;
END $$;
