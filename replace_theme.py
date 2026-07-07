import os
import re

files_to_update = [
    'lib/screens/tasks_screen.dart',
    'lib/screens/calendar_screen.dart',
    'lib/screens/focus_screen.dart',
    'lib/screens/insights_screen.dart',
    'lib/screens/settings_screen.dart',
    'lib/screens/analytics_screen.dart',
    'lib/screens/root_screen.dart',
]

def replace_theme(content):
    content = content.replace("AppTheme.background", "Theme.of(context).scaffoldBackgroundColor")
    content = content.replace("AppTheme.surfaceVariant", "Theme.of(context).colorScheme.surfaceContainerHigh")
    
    # Use regex to find AppTheme.<property>
    def replacer(match):
        prop = match.group(1)
        if prop == "background":
            return "Theme.of(context).scaffoldBackgroundColor"
        elif prop == "surfaceVariant":
            return "Theme.of(context).colorScheme.surfaceContainerHigh"
        else:
            return f"Theme.of(context).colorScheme.{prop}"
            
    content = re.sub(r'AppTheme\.([a-zA-Z]+)', replacer, content)
    return content

for file_path in files_to_update:
    if not os.path.exists(file_path):
        print(f"Skipping {file_path}, does not exist")
        continue
        
    with open(file_path, 'r') as f:
        content = f.read()
        
    new_content = replace_theme(content)
    
    with open(file_path, 'w') as f:
        f.write(new_content)
    print(f"Updated {file_path}")

