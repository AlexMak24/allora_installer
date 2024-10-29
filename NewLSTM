#!/bin/bash

# Ввод данных с клавиатуры
read -p "Введите имя кошелька (wallet_name): " wallet_name
read -p "Введите мнемоническую фразу (mnemonic): " mnemonic
read -p "Введите API ключ CGC (cgc_api_key): " cgc_api_key

# Клонирование репозитория и переход в директорию
git clone https://github.com/0xtnpxsgt/allora-worker-x-reputer.git
cd allora-worker-x-reputer

# Установка прав на выполнение и запуск init.sh
chmod +x init.sh
./init.sh

# Переход в директорию allora-node
cd allora-node

# Установка прав на выполнение и запуск init.config.sh с параметрами
chmod +x ./init.config.sh
./init.config.sh "$wallet_name" "$mnemonic" "$cgc_api_key"

# Загрузка образов Docker и запуск контейнеров
docker compose pull
docker compose up --build -d

# Просмотр логов контейнеров
docker compose logs -f
