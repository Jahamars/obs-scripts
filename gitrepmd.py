GITHUB_USERNAME = "username"
GITHUB_TOKEN = "token"

# URL API для получения списка репозиториев
GITHUB_API_URL = f"https://api.github.com/users/{GITHUB_USERNAME}/repos"

# Заголовки для авторизации
HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}"
}

# Получение списка репозиториев
response = requests.get(GITHUB_API_URL, headers=HEADERS)
if response.status_code == 200:
    repos = response.json()
else:
    print("Error fetching repositories:", response.status_code)
    exit()

# Генерация Markdown-файла
with open("projects.md", "w") as md_file:
    md_file.write("# 📂 My GitHub Repositories\n\n")
    for repo in repos:
        name = repo["name"]
        description = repo["description"] or "No description provided"
        url = repo["html_url"]
        md_file.write(f"## [{name}]({url})\n")
        md_file.write(f"- **Description:** {description}\n\n")

print("Markdown file 'projects.md' generated successfully!")
