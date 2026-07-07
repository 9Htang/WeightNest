import zipfile, io, json, sys

# 1. 读入 JSON
with open('tools/seed_data/lovebird_demo_v2.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# 2. 重建 data.json 内容（与 app 导出保持一致：2 空格缩进）
json_str = json.dumps(data, ensure_ascii=False, indent=2)
json_bytes = json_str.encode('utf-8')

# 3. 构造 ZIP（内存中，含单个 data.json）
buf = io.BytesIO()
with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zf:
    zf.writestr('data.json', json_bytes)
zip_bytes = buf.getvalue()

# 4. 组装：magic WNNR + ZIP
magic = bytes([0x57, 0x4E, 0x4E, 0x52])
out = magic + zip_bytes

# 5. 写出 .wnnutrition
out_path = 'tools/seed_data/lovebird_demo.wnnutrition'
with open(out_path, 'wb') as f:
    f.write(out)

print('OK ->', out_path)
print('magic check:', out[:4], '=', out[:4].decode('ascii'))
print('total size:', len(out), 'bytes')
print('zip inner size:', len(zip_bytes), 'bytes')
print('json size:', len(json_bytes), 'bytes')
print('foods:', len(data['foods']))
print('blends:', len(data.get('blends', [])))
print('plans:', len(data.get('feedingPlans', [])))
