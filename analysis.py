import os
import re
from datetime import datetime
from rich.console import Console
from rich.table import Table

# Initialize the console for beautiful output
console = Console()

# Function to parse the time in HH:MM format and calculate the duration
def parse_time_range(time_range):
    start_time_str, end_time_str = time_range.split(" - ")
    start_time = datetime.strptime(start_time_str, "%H:%M")
    end_time = datetime.strptime(end_time_str, "%H:%M")
    return (end_time - start_time).total_seconds() / 3600  # Return time in hours

# Function to analyze tasks from a list of lines
def analyze_tasks(lines):
    total_tasks = 0
    completed_tasks = 0
    categories = {}
    
    for line in lines:
        match = re.match(r"(- \[(x| )\] (\d{2}:\d{2} - \d{2}:\d{2}) .+? #(\w+))", line)
        if match:
            total_tasks += 1
            status = match.group(2)
            time_range = match.group(3)
            category = match.group(4)
            
            if category not in categories:
                categories[category] = {'completed_time': 0, 'total_tasks': 0, 'completed_tasks': 0}
            
            categories[category]['total_tasks'] += 1
            
            if status == "x":  # Completed task
                completed_tasks += 1
                categories[category]['completed_tasks'] += 1
                time_spent = parse_time_range(time_range)
                categories[category]['completed_time'] += time_spent
    
    return total_tasks, completed_tasks, categories

# Function to display the analysis results using rich
def display_results(total_tasks, completed_tasks, categories):
    if total_tasks == 0:
        console.print("[bold red]No tasks found.[/bold red]")
        return
    
    # Calculate and display the overall completion percentage
    completion_percentage = (completed_tasks / total_tasks) * 100
    console.print(f"[bold]Total tasks:[/bold] {total_tasks}")
    console.print(f"[bold]Completed tasks:[/bold] {completed_tasks}")
    console.print(f"[bold]Completion percentage:[/bold] {completion_percentage:.2f}%\n")
    
    # Display the category-wise breakdown
    table = Table(title="Category-wise Task Analysis")
    table.add_column("Category", justify="left", style="cyan", no_wrap=True)
    table.add_column("Completed Tasks", justify="right", style="green")
    table.add_column("Total Tasks", justify="right", style="yellow")
    table.add_column("Completion %", justify="right", style="blue")
    table.add_column("Time Spent (hours)", justify="right", style="magenta")
    
    for category, data in categories.items():
        category_completion = (data['completed_tasks'] / data['total_tasks']) * 100 if data['total_tasks'] else 0
        table.add_row(
            category,
            str(data['completed_tasks']),
            str(data['total_tasks']),
            f"{category_completion:.2f}%",
            f"{data['completed_time']:.2f}"
        )
    
    console.print(table)

# Main function to load and analyze the notes
def main():
    folder_path = "/home/mars/Документы/Obsidian/days"
    all_lines = []
    
    # Load all notes from the folder
    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)
        if os.path.isfile(file_path):
            with open(file_path, "r", encoding="utf-8") as file:
                all_lines.extend(file.readlines())
    
    total_tasks, completed_tasks, categories = analyze_tasks(all_lines)
    display_results(total_tasks, completed_tasks, categories)

if __name__ == "__main__":
    main()
