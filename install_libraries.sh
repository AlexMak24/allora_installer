#!/bin/bash

# Обновление пакетов


echo "Происходит обновление пакетов..."
if sudo apt update && sudo apt upgrade -y; then
    echo "Обновление пакетов: Успешно"
else
    echo "Обновление пакетов: Ошибка"
    exit 1
fi

# Установка дополнительных пакетов
echo "Происходит установка дополнительных пакетов..."
if sudo apt install ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make -y; then
    echo "Установка дополнительных пакетов: Успешно"
else
    echo "Установка дополнительных пакетов: Ошибка"
    exit 1
fi

# Установка Python
echo "Происходит установка Python..."
if sudo apt install python3 -y; then
    echo "Установка Python: Успешно"
else
    echo "Установка Python: Ошибка"
    exit 1
fi

echo "Версия Python:"
python3 --version

if sudo apt install python3-pip -y; then
    echo "Установка pip для Python: Успешно"
else
    echo "Установка pip для Python: Ошибка"
    exit 1
fi

echo "Версия pip для Python:"
pip3 --version

# Установка Docker
echo "Происходит установка Docker..."
if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &&
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
   sudo apt-get update &&
   sudo apt-get install docker-ce docker-ce-cli containerd.io -y; then
    echo "Установка Docker: Успешно"
else
    echo "Установка Docker: Ошибка"
    exit 1
fi

echo "Версия Docker:"
docker version

# Установка Docker Compose
echo "Происходит установка Docker Compose..."
if sudo apt-get install docker-compose -y; then
    echo "Установка Docker Compose: Успешно"
else
    echo "Установка Docker Compose: Ошибка"
    exit 1
fi

echo "Версия Docker Compose:"
docker-compose version

# Установка разрешений
echo "Происходит установка разрешений для Docker..."
if sudo groupadd docker && sudo usermod -aG docker $USER; then
    echo "Установка разрешений для Docker: Успешно"
else
    echo "Установка разрешений для Docker: Разрешение было применено по умолчанию"
fi

sudo apt-get install jq -y

