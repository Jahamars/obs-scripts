import os
from icalendar import Calendar
from datetime import datetime

def print_help():
    """Вывод справки по использованию программы."""
    print("Использование: python <название программы>.py")
    print("Программа читает .ics файл и генерирует заметки для Obsidian.")
    print("Убедитесь, что указали правильный путь к .ics файлу.")

def read_ics_file(ics_file):
    """Чтение и обработка .ics файла."""
    try:
        with open(ics_file, 'r', encoding='utf-8') as f:
            return Calendar.from_ical(f.read())
    except FileNotFoundError:
        print(f"Ошибка: файл '{ics_file}' не найден.")
        print_help()
        exit(1)
    except IsADirectoryError:
        print(f"Ошибка: '{ics_file}' является директорией, а не файлом.")
        print_help()
        exit(1)
    except Exception as e:
        print(f"Ошибка при чтении файла: {e}")
        exit(1)

def format_event(event):
    """Форматирование события."""
    summary = event.get('SUMMARY', 'Без названия')
    dtstart = event.get('DTSTART').dt
    dtend = event.get('DTEND').dt
    location = event.get('LOCATION', "Место не указано")
    description = event.get('DESCRIPTION', "").strip().replace("\n", " ")
    
    # Фильтрация ненужной информации
    description_lines = [line.strip() for line in description.splitlines() if "Посмотреть" not in line and line.strip()]
    description = " / ".join(description_lines) if description_lines else "Описание отсутствует"

    # Форматирование строки события
    time_range = f"{dtstart.strftime('%H:%M')} - {dtend.strftime('%H:%M')}"
    formatted_event = {
        'time_range': time_range,
        'summary': summary,
        'location': location,
        'description': description
    }
    return formatted_event

def main():
    # Путь к папке с заметками Obsidian
    obsidian_dir = "/home/mars/Документы/Obsidian/days"

    # Путь к файлу .ics
    ics_file = "/home/mars/Загрузки/call.ics"

    # Чтение .ics файла
    calendar = read_ics_file(ics_file)

    # Словарь для хранения событий по датам
    events_by_date = {}

    # Обработка каждого события в файле .ics
    for event in calendar.walk('VEVENT'):
        formatted_event = format_event(event)
        dtstart = event.get('DTSTART').dt
        date_str = dtstart.strftime("%Y-%m-%d")

        # Добавление события в словарь по соответствующей дате
        if date_str not in events_by_date:
            events_by_date[date_str] = []
        events_by_date[date_str].append(formatted_event)

    # Проход по датам и сортировка событий по времени
    for date_str, events in events_by_date.items():
        # Сортировка по времени начала события
        events.sort(key=lambda x: datetime.strptime(x['time_range'].split(' - ')[0], '%H:%M'))

        # Путь к файлу заметки
        file_path = os.path.join(obsidian_dir, f"{date_str}.md")

        # Создание или обновление файла
        with open(file_path, 'w', encoding='utf-8') as note:
            note.write("# do it now\n\n")
            for event in events:
                note.write(f"- [ ] {event['time_range']} {event['summary']} #study\n")
                note.write(f"\t- {event['description']}\n")
                note.write(f"\t- {event['summary']} ({event['location']})\n\n")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Произошла непредвиденная ошибка: {e}")
        print_help()
        exit(1)
