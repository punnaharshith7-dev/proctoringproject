import glob

for f in glob.glob('templates/*.html'):
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    content = content.replace("v='5'", "v='6'")
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)
print('Done')
