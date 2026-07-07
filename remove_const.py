import os
import re
import subprocess

files_to_update = [
    'lib/screens/tasks_screen.dart',
    'lib/screens/calendar_screen.dart',
    'lib/screens/focus_screen.dart',
    'lib/screens/insights_screen.dart',
    'lib/screens/settings_screen.dart',
    'lib/screens/analytics_screen.dart',
    'lib/screens/root_screen.dart',
]

def remove_const(content):
    # Regex to match 'const ' before common widget/class names
    pattern = r'const\s+([A-Z][a-zA-Z0-9_]*\s*(?:\.fromLTRB|\.symmetric|\.all|\.only)?\()'
    return re.sub(pattern, r'\1', content)
    
for file_path in files_to_update:
    if not os.path.exists(file_path):
        continue
        
    with open(file_path, 'r') as f:
        content = f.read()
        
    # We also need to remove 'const [' array literals if they contain Theme.of
    # A simple hack is just to remove ALL 'const ['
    content = content.replace('const [', '[')
    
    new_content = remove_const(content)
    
    with open(file_path, 'w') as f:
        f.write(new_content)
    print(f"Removed const in {file_path}")

