#!/usr/bin/env python3
"""Універсальна вставка картинок у N-ий placeholder 'Додай скрін(и)' зошита.

Usage:
    python insert_images.py <pr_index> <png1> [png2 ...]
        pr_index — 1-based індекс ПР (1=ПР3, 2=ПР4, 3=ПР5, ..., 7=ПР9)
        png — шляхи до PNG-файлів
"""
from lxml import etree
import shutil
import os
import re
import sys

UNPACKED = '/home/vlad/learning/university/databases/notebook/unpacked'
MEDIA_DIR = os.path.join(UNPACKED, 'word/media')
RELS_PATH = os.path.join(UNPACKED, 'word/_rels/document.xml.rels')
DOC_PATH  = os.path.join(UNPACKED, 'word/document.xml')

NS_W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
W = '{%s}' % NS_W


def next_rid():
    with open(RELS_PATH, 'r', encoding='utf-8') as f:
        content = f.read()
    ids = [int(m) for m in re.findall(r'Id="rId(\d+)"', content)]
    return max(ids) + 1, content


def add_relationship(rid, png_name):
    with open(RELS_PATH, 'r', encoding='utf-8') as f:
        content = f.read()
    rel = (f'  <Relationship Id="rId{rid}" '
           f'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" '
           f'Target="media/{png_name}"/>\n')
    content = content.replace('</Relationships>', f'{rel}</Relationships>')
    with open(RELS_PATH, 'w', encoding='utf-8') as f:
        f.write(content)


def make_drawing_xml(rid, png_name, cx, cy):
    return f'''<w:r xmlns:w="{NS_W}"
        xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
        xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
        xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"
        xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:rPr><w:rFonts w:ascii="Calibri" w:cs="Calibri" w:eastAsia="Calibri" w:hAnsi="Calibri"/></w:rPr>
  <w:drawing>
    <wp:inline distB="0" distT="0" distL="0" distR="0">
      <wp:extent cx="{cx}" cy="{cy}"/>
      <wp:effectExtent b="0" l="0" r="0" t="0"/>
      <wp:docPr descr="{png_name}" id="100" name="{png_name}"/>
      <a:graphic>
        <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
          <pic:pic>
            <pic:nvPicPr>
              <pic:cNvPr descr="{png_name}" id="0" name="{png_name}"/>
              <pic:cNvPicPr preferRelativeResize="0"/>
            </pic:nvPicPr>
            <pic:blipFill>
              <a:blip r:embed="rId{rid}"/>
              <a:srcRect b="0" l="0" r="0" t="0"/>
              <a:stretch><a:fillRect/></a:stretch>
            </pic:blipFill>
            <pic:spPr>
              <a:xfrm>
                <a:off x="0" y="0"/>
                <a:ext cx="{cx}" cy="{cy}"/>
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


def get_png_size_emu(path, target_width_emu=5215000):
    """Розмір PNG → EMU зі збереженням пропорцій."""
    from PIL import Image
    with Image.open(path) as img:
        w, h = img.size
    cx = target_width_emu
    cy = int(cx * h / w)
    return cx, cy


def find_screenshot_cell_paragraph(root, pr_index):
    """Знайти параграф всередині N-ї screenshot placeholder таблиці.

    Структура у zoshyt:
        <w:p>...🔷 Додай у це поле скрін(и) на виконане завдання...</w:p>
        <w:p>...</w:p>  (spacer)
        <w:tbl>  ← placeholder table з ОДНІЄЮ клітинкою
          <w:tr><w:tc><w:p>...</w:p></w:tc></w:tr>
        </w:tbl>
    """
    placeholders = []
    body = root.find(f'{W}body')
    children = list(body)
    for i, elem in enumerate(children):
        if elem.tag != f'{W}p':
            continue
        text = ''.join(t.text or '' for t in elem.iter(f'{W}t'))
        if 'Додай у це поле скрін' in text:
            # Знайти наступну w:tbl після цього параграфа
            for j in range(i + 1, min(i + 5, len(children))):
                if children[j].tag == f'{W}tbl':
                    # Беремо перший параграф у єдиній клітинці
                    p = children[j].find(f'{W}tr/{W}tc/{W}p')
                    if p is not None:
                        placeholders.append((elem, children[j], p))
                    break
    if pr_index < 1 or pr_index > len(placeholders):
        raise ValueError(f"PR index {pr_index} out of range; found {len(placeholders)} placeholders")
    return placeholders[pr_index - 1]


def main():
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(1)
    pr_index = int(sys.argv[1])
    png_paths = sys.argv[2:]

    # Парсимо документ
    parser = etree.XMLParser(remove_blank_text=False, strip_cdata=False)
    tree = etree.parse(DOC_PATH, parser)
    root = tree.getroot()

    _, _, anchor_p = find_screenshot_cell_paragraph(root, pr_index)
    # Очищуємо anchor_p, додаємо новий контент
    for child in list(anchor_p):
        if child.tag == f'{W}r':
            anchor_p.remove(child)

    parent_cell = anchor_p.getparent()

    rid_base, _ = next_rid()
    for idx, png_path in enumerate(png_paths):
        png_basename = f"pr{pr_index + 2}_extra_{idx}_{os.path.basename(png_path)}"
        png_dst = os.path.join(MEDIA_DIR, png_basename)
        shutil.copy(png_path, png_dst)

        rid = rid_base + idx
        add_relationship(rid, png_basename)

        cx, cy = get_png_size_emu(png_path)

        # Створюємо новий параграф з малюнком
        if idx == 0:
            # У вже існуючий порожній параграф додаємо drawing run
            target_p = anchor_p
        else:
            # Додаємо новий параграф у клітинку
            target_p = etree.SubElement(parent_cell, f'{W}p')
            pPr = etree.SubElement(target_p, f'{W}pPr')
            spacing = etree.SubElement(pPr, f'{W}spacing')
            spacing.set(f'{W}line', '240')
            spacing.set(f'{W}lineRule', 'auto')

        new_r = etree.fromstring(make_drawing_xml(rid, png_basename, cx, cy))
        target_p.append(new_r)
        print(f"  + {png_basename} ({cx}×{cy} EMU) → rId{rid}")

    tree.write(DOC_PATH, xml_declaration=True, encoding='UTF-8', standalone=True)
    print(f"✅ Inserted {len(png_paths)} images into PR{pr_index + 2} screenshot placeholder")


if __name__ == '__main__':
    main()
