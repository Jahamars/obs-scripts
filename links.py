import os

def create_markdown_overview(directory):
    """
    Создает файлы обзора в формате Markdown для всех папок и подпапок в указанной директории.

    Args:
        directory (str): Путь к корневой директории.
    """
    for root, dirs, files in os.walk(directory, topdown=True):
        
        current_folder = os.path.basename(root)
        
        overview_file_name = f"0{current_folder}.md"
        overview_file_path = os.path.join(root, overview_file_name)

        with open(overview_file_path, 'w', encoding='utf-8') as overview_file:
            overview_file.write(f"# Welcome to {current_folder}\n\n")

            
            notes = [f for f in files if f != overview_file_name]
            if notes:
                overview_file.write("## Notes\n")
                for note in notes:
                    note_name, _ = os.path.splitext(note)  
                    relative_path = os.path.relpath(os.path.join(root, note_name), start=directory)
                    relative_path = relative_path.replace("\\", "/")  
                    overview_file.write(f"- [[{relative_path}]]\n")

            
            if dirs:
                overview_file.write("\n## Folders\n")
                for subdir in dirs:
                    subdir_overview = os.path.relpath(os.path.join(root, subdir, f"0{subdir}"), start=directory)
                    subdir_overview = subdir_overview.replace("\\", "/")  
                    overview_file.write(f"- [[{subdir_overview}]]\n")

if __name__ == "__main__":
    base_directory = input("Enter the path to the root directory: ").strip()
    if os.path.isdir(base_directory):
        create_markdown_overview(base_directory)
        print("The review files have been created successfully.")
    else:
        print("The specified directory does not exist.")
