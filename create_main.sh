#!/bin/bash

# Проверка установки Go
if ! command -v go &> /dev/null; then
    echo "Go не найден, устанавливаем Go..."
    ver="1.22.4"
    if wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" &&
       sudo rm -rf /usr/local/go &&
       sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" &&
       rm "go$ver.linux-amd64.tar.gz" &&
       echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> $HOME/.bash_profile &&
       echo "export GOPATH=\$HOME/go" >> $HOME/.bash_profile &&
       source $HOME/.bash_profile &&
       go version; then
        echo "Установка Go: Успешно"
    else
        echo "Установка Go: Ошибка"
        exit 1
    fi
else
    echo "Go уже установлен"
fi

# Запрос данных от пользователя
read -p "Введите TOPIC_ID: " TOPIC_ID
read -p "Введите имя кошелька: " WALLET_NAME
read -p "Введите мнемоническую фразу: " MNEMONIC
read -p "Введите токен (например, ETH): " TOKEN
read -p "Введите ваш Coingecko API ключ: " API_KEY
read -p "Введите название модели (например, BiLSTM): " MODEL_NAME
read -p "Введите RPC-адрес (например, https://allora-rpc.testnet-1.testnet.allora.network/): " RPC_ADDRESS

# Проверка наличия папки с воркером и её обновление
if [ -d "allora-huggingface-walkthrough" ]; then
    echo "Папка allora-huggingface-walkthrough уже существует. Удаление..."
    rm -rf allora-huggingface-walkthrough
fi

echo "Загрузка файлов воркера..."
if git clone https://github.com/allora-network/allora-huggingface-walkthrough ; then
    echo "Установка файлов воркера: Успешно"
else
    echo "Установка файлов воркера: Ошибка"
    exit 1
fi
cd allora-huggingface-walkthrough

# Проверка и клонирование репозитория с моделями, если еще не сделано
if [ ! -d "allora_installer" ]; then
    echo "Клонирование репозитория с моделями..."
    if git clone https://github.com/AlexMak24/allora_installer ; then
        echo "Клонирование репозитория: Успешно"
    else
        echo "Ошибка при клонировании репозитория"
        exit 1
    fi
fi

# Проверка наличия папки с выбранной моделью и её копирование
if [ -d "allora_installer/$MODEL_NAME" ]; then
    echo "Копирование файлов из папки модели $MODEL_NAME..."
    sudo cp -r allora_installer/$MODEL_NAME/* ./
    echo "Файлы модели $MODEL_NAME успешно скопированы"
else
    echo "Папка модели $MODEL_NAME не найдена в allora_installer"
    exit 1
fi

# Создание копии config.example.json как config.json
cp config.example.json config.json

# Замена значений в config.json с использованием введенных данных
echo "Обновление конфигурационного файла config.json..."

jq --arg walletName "$WALLET_NAME" \
   --arg mnemonic "$MNEMONIC" \
   --arg rpcAddress "$RPC_ADDRESS" \
   --arg topicId "$TOPIC_ID" \
   --arg token "$TOKEN" \
   '.wallet.addressKeyName = $walletName |
    .wallet.addressRestoreMnemonic = $mnemonic |
    .wallet.nodeRpc = $rpcAddress |
    .worker[] |= (if .topicId == ($topicId | tonumber) then .parameters.Token = $token else . end)' config.json > temp.json && mv temp.json config.json

if [ $? -eq 0 ]; then
    echo "Конфигурационный файл config.json успешно обновлен:"
    cat config.json
else
    echo "Ошибка при обновлении config.json"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "Файл app.py успешно обновлен:"
    cat app.py
else
    echo "Ошибка при обновлении app.py"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "Файл requirements.txt успешно обновлен:"
    cat requirements.txt
else
    echo "Ошибка при обновлении requirements.txt"
    exit 1
fi

# Установка зависимостей
pip install -r requirements.txt

# Запуск Docker Compose в фоновом режиме
echo "Запуск ноды..."
docker-compose up -d
