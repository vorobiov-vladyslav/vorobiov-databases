#!/usr/bin/env python3
"""Універсальна вставка hyperlink-ів у N-ий placeholder 'Додай посилання' зошита.

Usage:
    python insert_links.py <pr_index> <url1>[|<label1>] [url2[|label2] ...]
"""
from lxml import etree
import sys
import re

UNPACKED = '/home/vlad/learning/university/databases/notebook/unpacked'
RELS_PATH = f'{UNPACKED}/word/_rels/document.xml.rels'
DOC_PATH  = f'{UNPACKED}/word/document.xml'

NS_W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
NS_R = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
W = '{%s}' % NS_W
R = '{%s}' % NS_R


def next_rid():
    with open(RELS_PATH, 'r', encoding='utf-8') as f:
        content = f.read()
    ids = [int(m) for m in re.findall(r'Id="rId(\d+)"', content)]
    return max(ids) + 1


def add_hyperlink_relationship(rid, url):
    with open(RELS_PATH, 'r', encoding='utf-8') as f:
        content = f.read()
    rel = (f'  <Relationship Id="rId{rid}" '
           f'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" '
           f'Target="{url}" TargetMode="External"/>\n')
    content = content.replace('</Relationships>', f'{rel}</Relationships>')
    with open(RELS_PATH, 'w', encoding='utf-8') as f:
        f.write(content)


def find_link_cell_paragraph(root, pr_index):
    """Знайти параграф у N-ій таблиці-placeholder після '🔷 Додай у це поле посилання'."""
    placeholders = []
    body = root.find(f'{W}body')
    children = list(body)
    for i, elem in enumerate(children):
        if elem.tag != f'{W}p':
            continue
        text = ''.join(t.text or '' for t in elem.iter(f'{W}t'))
        if 'Додай у це поле посилання' in text:
            for j in range(i + 1, min(i + 5, len(children))):
                if children[j].tag == f'{W}tbl':
                    p = children[j].find(f'{W}tr/{W}tc/{W}p')
                    if p is not None:
                        placeholders.append((children[j], p))
                    break
    if pr_index < 1 or pr_index > len(placeholders):
        raise ValueError(f"PR index {pr_index} out of range; found {len(placeholders)} link placeholders")
    return placeholders[pr_index - 1]


def make_hyperlink_xml(rid, label):
    safe_label = (label.replace('&', '&amp;')
                       .replace('<', '&lt;')
                       .replace('>', '&gt;'))
    return f'''<w:hyperlink xmlns:w="{NS_W}" xmlns:r="{NS_R}" r:id="rId{rid}" w:history="0">
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:cs="Times New Roman" w:eastAsia="Times New Roman" w:hAnsi="Times New Roman"/>
      <w:color w:val="1155CC"/>
      <w:sz w:val="22"/>
      <w:szCs w:val="22"/>
      <w:u w:val="single"/>
      <w:rtl w:val="0"/>
    </w:rPr>
    <w:t xml:space="preserve">{safe_label}</w:t>
  </w:r>
</w:hyperlink>'''


def main():
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(1)
    pr_index = int(sys.argv[1])
    entries = sys.argv[2:]

    parser = etree.XMLParser(remove_blank_text=False, strip_cdata=False)
    tree = etree.parse(DOC_PATH, parser)
    root = tree.getroot()

    parent_tbl, anchor_p = find_link_cell_paragraph(root, pr_index)
    parent_cell = anchor_p.getparent()

    # Очищуємо anchor_p
    for child in list(anchor_p):
        if child.tag == f'{W}r':
            anchor_p.remove(child)

    for idx, entry in enumerate(entries):
        url, _, label = entry.partition('|')
        label = label or url
        rid = next_rid()
        add_hyperlink_relationship(rid, url)

        if idx == 0:
            target_p = anchor_p
        else:
            target_p = etree.SubElement(parent_cell, f'{W}p')
            pPr = etree.SubElement(target_p, f'{W}pPr')
            spacing = etree.SubElement(pPr, f'{W}spacing')
            spacing.set(f'{W}line', '240')
            spacing.set(f'{W}lineRule', 'auto')

        hyperlink_elem = etree.fromstring(make_hyperlink_xml(rid, label))
        target_p.append(hyperlink_elem)
        print(f"  + rId{rid} → {label}: {url}")

    tree.write(DOC_PATH, xml_declaration=True, encoding='UTF-8', standalone=True)
    print(f"✅ Inserted {len(entries)} link(s) into PR{pr_index + 2}")


if __name__ == '__main__':
    main()
