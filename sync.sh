#!/bin/bash

LSF="./last_connection.txt"

prompt() {
    local label=$1
    local default_value=$2
    if [ -n "$default_value" ]; then
        read -p "$label [$default_value]: " input
        echo "${input:-$default_value}"
    else
        read -p "$label: " input
        echo "$input"
    fi
}

# Проверяем, существует ли файл с последним подключением
if [ -f "$LSF" ]; then
    # Считываем данные из файла
    IFS=',' read -r LAST_MODE LAST_LOCAL_PATH LAST_REMOTE_PATH LAST_REMOTE_USER LAST_REMOTE_HOST < "$LSF"
else
    # Если файл отсутствует, задаем пустые значения
    LAST_MODE="" LAST_LOCAL_PATH="" LAST_REMOTE_PATH="" LAST_REMOTE_USER="" LAST_REMOTE_HOST=""
fi

# Запрашиваем режим
MODE=$(prompt "Choose mode (1: Send, 2: Receive)" "$LAST_MODE")

# Запрашиваем пути и данные с возможностью использовать последние значения
LOCAL_PATH=$(prompt "Enter the local directory path" "$LAST_LOCAL_PATH")
REMOTE_PATH=$(prompt "Enter the remote directory path" "$LAST_REMOTE_PATH")
REMOTE_USER=$(prompt "Enter remote username" "$LAST_REMOTE_USER")
REMOTE_HOST=$(prompt "Enter remote host (IP or hostname)" "$LAST_REMOTE_HOST")

# Удаляем завершающие слеши
LOCAL_PATH=${LOCAL_PATH%/}
REMOTE_PATH=${REMOTE_PATH%/}

# Сохраняем данные в файл
echo "$MODE,$LOCAL_PATH,$REMOTE_PATH,$REMOTE_USER,$REMOTE_HOST" > "$LSF"

# Выполняем rsync в зависимости от режима
if [ "$MODE" -eq 1 ]; then
    echo "Sending files to remote host..."
    rsync -avz --progress "$LOCAL_PATH/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"
elif [ "$MODE" -eq 2 ]; then
    echo "Receiving files from remote host..."
    rsync -avz --progress "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/" "$LOCAL_PATH/"
else
    echo "Invalid mode. Use '1' for sending or '2' for receiving."
    exit 1
fi

echo "Operation completed."
