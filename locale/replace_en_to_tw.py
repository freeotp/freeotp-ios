# 將 freeotp-ios/locale/zh_TW.po 中的英文文字替換成繁體中文
# 如果msgstr為空則不替換、已替換過則不影響
import os
import shutil
import re

def backup_file(file_path):
    backup_path = file_path + '.bak'
    try:
        shutil.copyfile(file_path, backup_path)
        print(f"Backup created: {backup_path}")
    except Exception as e:
        print(f"Error creating backup: {e}")

def replace_in_file(po_file_path, source_file_dir):
    # 備份檔案
    backup_file(po_file_path)

    with open(po_file_path, 'r', encoding='utf-8') as po_file:
        po_contents = po_file.readlines()

    entries = {}
    current_references = []
    current_msgid = None
    current_msgstr = None

    for line in po_contents:
        if line.startswith('#:'):
            current_references.append(line.strip().split()[1])
        elif line.startswith('msgid'):
            current_msgid = line.strip()[7:-1]
        elif line.startswith('msgstr'):
            current_msgstr = line.strip()[8:-1]
            if current_msgid and current_msgstr and current_references:
                if current_msgid not in entries:
                    entries[current_msgid] = {'references': [], 'msgstr': current_msgstr}
                entries[current_msgid]['references'].extend(current_references)
            current_references = []
            current_msgid = None
            current_msgstr = None

    for msgid, entry in entries.items():
        msgstr = entry['msgstr']
        if msgstr:
            for ref in entry['references']:
                match = re.search(r'([^:]+):(\d+)', ref)
                if match:
                    file_path = f"{source_file_dir}/{match.group(1).strip()}"
                    line_num = int(match.group(2))

                    try:
                        with open(file_path, 'r', encoding='utf-8') as file:
                            lines = file.readlines()

                        # 判斷是否為特定檔案和行號
                        if file_path.endswith('Main.storyboard') and (line_num == 574 or line_num == 576):
                            # 針對特定行號進行替換
                            old_text = f'{msgid}'
                            new_text = f'{msgstr}'
                            lines[line_num - 1] = lines[line_num - 1].replace(old_text, new_text)
                        elif file_path.endswith('AboutViewController.swift') and (line_num == 57 or line_num == 59 or line_num == 61 or line_num == 63 or line_num == 64 or line_num == 65):
                            # 針對特定行號進行替換
                            old_text = f'{msgid}'
                            new_text = f'{msgstr}'
                            lines[line_num - 1] = lines[line_num - 1].replace(old_text, new_text)
                        else:
                            # 其他檔案保持原始替換邏輯
                            if file_path.endswith('.plist'):
                                pattern = re.compile(re.escape(msgid))
                            else:
                                pattern = re.compile(rf'(?<!\w)"{re.escape(msgid)}"(?!\w)')
                            lines[line_num - 1] = re.sub(pattern, f'"{msgstr}"' if not file_path.endswith('.plist') else msgstr, lines[line_num - 1])

                        with open(file_path, 'w', encoding='utf-8') as file:
                            file.writelines(lines)
                    except FileNotFoundError:
                        print(f"File not found: {file_path}")

# 使用示例
po_file_path = './zh_TW.po'
source_file_dir = '..'
replace_in_file(po_file_path, source_file_dir)
