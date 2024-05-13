# 將 freeotp-ios/locale/zh_TW.po 中的繁體中文替換成英文
import os
import re

def replace_in_file(po_file_path, source_file_dir):
    if not os.path.exists(po_file_path):
        print(f"No file found: {po_file_path}")
        return

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
                if current_msgstr not in entries:
                    entries[current_msgstr] = {'references': [], 'msgid': current_msgid}
                entries[current_msgstr]['references'].extend(current_references)
            current_references = []
            current_msgid = None
            current_msgstr = None

    for msgstr, entry in entries.items():
        msgid = entry['msgid']
        if msgid:
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
                            old_text = f'{msgstr}'
                            new_text = f'{msgid}'
                            lines[line_num - 1] = lines[line_num - 1].replace(old_text, new_text)
                        elif file_path.endswith('AboutViewController.swift') and (line_num == 57 or line_num == 59 or line_num == 61 or line_num == 63 or line_num == 64 or line_num == 65):
                            # 針對特定行號進行替換
                            old_text = f'{msgstr}'
                            new_text = f'{msgid}'
                            lines[line_num - 1] = lines[line_num - 1].replace(old_text, new_text)
                        else:
                            # 其他檔案保持原始替換邏輯
                            if file_path.endswith('.plist'):
                                pattern = re.compile(re.escape(msgstr))
                            else:
                                pattern = re.compile(rf'(?<!\w)"{re.escape(msgstr)}"(?!\w)')
                            lines[line_num - 1] = re.sub(pattern, f'"{msgid}"' if not file_path.endswith('.plist') else msgid, lines[line_num - 1])

                        with open(file_path, 'w', encoding='utf-8') as file:
                            file.writelines(lines)
                    except FileNotFoundError:
                        print(f"File not found: {file_path}")

# 使用示例
po_file_path = './zh_TW.po.bak'
source_file_dir = '..'
replace_in_file(po_file_path, source_file_dir)
