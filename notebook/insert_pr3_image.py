#!/usr/bin/env python3
"""Вставити ER-діаграму PR3 у відповідний скріншот-плейсхолдер у зошиті."""
from lxml import etree
import shutil
import os
import re

UNPACKED = '/home/vlad/learning/university/databases/notebook/unpacked'
PNG_SRC = '/home/vlad/learning/university/databases/screens/pr3_er_diagram.png'
PNG_NAME = 'image61_pr3_er.png'  # унікальне ім'я
PARA_ID = '0000014A'  # параграф у клітинці після "Додай скрін" ПР3

NS = {
    'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
    'wp': 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
    'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
    'pic': 'http://schemas.openxmlformats.org/drawingml/2006/picture',
    'r_ns': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
}

# 1. Скопіювати PNG у media
media_dst = os.path.join(UNPACKED, 'word/media', PNG_NAME)
shutil.copy(PNG_SRC, media_dst)
print(f"✅ Copied PNG → {media_dst}")

# 2. Додати relationship у document.xml.rels (знайти вільний rId)
rels_path = os.path.join(UNPACKED, 'word/_rels/document.xml.rels')
with open(rels_path, 'r', encoding='utf-8') as f:
    rels_content = f.read()
ids = [int(m) for m in re.findall(r'Id="rId(\d+)"', rels_content)]
new_rid = max(ids) + 1
new_rel = f'  <Relationship Id="rId{new_rid}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/{PNG_NAME}"/>\n'
rels_content = rels_content.replace('</Relationships>', f'{new_rel}</Relationships>')
with open(rels_path, 'w', encoding='utf-8') as f:
    f.write(rels_content)
print(f"✅ Added relationship rId{new_rid} → media/{PNG_NAME}")

# 3. Замінити порожній run у параграфі з paraId на drawing
doc_path = os.path.join(UNPACKED, 'word/document.xml')
parser = etree.XMLParser(remove_blank_text=False, strip_cdata=False)
tree = etree.parse(doc_path, parser)
root = tree.getroot()

# Розрахунок розміру: 545×593 px при 96 DPI → EMU
# Цільова ширина ~5.7 inches = 5,215,000 EMU
target_cx = 5215000
target_cy = int(target_cx * 593 / 545)  # зберігаємо пропорції

# Знайти параграф з потрібним paraId
W = '{%s}' % NS['w']
target_p = None
for p in root.iter(f'{W}p'):
    paraId = p.get(f'{{http://schemas.microsoft.com/office/word/2010/wordml}}paraId')
    if paraId == PARA_ID:
        target_p = p
        break

if target_p is None:
    print(f"❌ Could not find paragraph with paraId={PARA_ID}")
    raise SystemExit(1)

# Видалити старі <w:r> з параграфа
for r in target_p.findall(f'{W}r'):
    target_p.remove(r)

# Створити новий <w:r> з drawing — використаємо XML string і parse fragment
drawing_xml = f'''<w:r xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
        xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
        xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
        xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"
        xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:rPr><w:rFonts w:ascii="Calibri" w:cs="Calibri" w:eastAsia="Calibri" w:hAnsi="Calibri"/></w:rPr>
  <w:drawing>
    <wp:inline distB="0" distT="0" distL="0" distR="0">
      <wp:extent cx="{target_cx}" cy="{target_cy}"/>
      <wp:effectExtent b="0" l="0" r="0" t="0"/>
      <wp:docPr descr="ER-діаграма видавничої компанії publishing (Workbench Reverse Engineer)" id="100" name="{PNG_NAME}"/>
      <a:graphic>
        <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
          <pic:pic>
            <pic:nvPicPr>
              <pic:cNvPr descr="ER-діаграма видавничої компанії publishing" id="0" name="{PNG_NAME}"/>
              <pic:cNvPicPr preferRelativeResize="0"/>
            </pic:nvPicPr>
            <pic:blipFill>
              <a:blip r:embed="rId{new_rid}"/>
              <a:srcRect b="0" l="0" r="0" t="0"/>
              <a:stretch><a:fillRect/></a:stretch>
            </pic:blipFill>
            <pic:spPr>
              <a:xfrm>
                <a:off x="0" y="0"/>
                <a:ext cx="{target_cx}" cy="{target_cy}"/>
              </a:xfrm>
              <a:prstGeom prst="rect"/>
              <a:ln/>
            </pic:spPr>
          </pic:pic>
        </a:graphicData>
      </a:graphic>
    </wp:inline>
  </w:drawing>
</w:r>'''
new_r = etree.fromstring(drawing_xml)
target_p.append(new_r)

# Зберегти
tree.write(doc_path, xml_declaration=True, encoding='UTF-8', standalone=True)
print(f"✅ Inserted drawing into paragraph paraId={PARA_ID} ({target_cx}×{target_cy} EMU)")
