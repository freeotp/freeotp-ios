import re

def replace_in_file(po_file_path, source_file_dir):
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

                        if 0 <= line_num - 1 < len(lines):
                            lines[line_num - 1] = lines[line_num - 1].replace(msgid, msgstr)

                        with open(file_path, 'w', encoding='utf-8') as file:
                            file.writelines(lines)
                    except FileNotFoundError:
                        print(f"File not found: {file_path}")

# 使用示例
po_file_path = './zh_TW.po'
source_file_dir = '..'
replace_in_file(po_file_path, source_file_dir)
