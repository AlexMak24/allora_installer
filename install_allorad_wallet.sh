#!/bin/bash

# Установка GO
echo "Происходит установка GO..."
if cd $HOME &&
   ver="1.22.4" &&
   wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" &&
   sudo rm -rf /usr/local/go &&
   sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" &&
   rm "go$ver.linux-amd64.tar.gz"; then
   
   # Добавление GO в PATH
   export PATH=$PATH:/usr/local/go/bin
   echo "export PATH=\$PATH:/usr/local/go/bin" >> $HOME/.bashrc
   
   # Проверка версии GO
   if go version; then
       echo "Установка GO: Успешно"
   else
       echo "Установка GO: Ошибка"
       exit 1
   fi
else
    echo "Установка GO: Ошибка"
    exit 1
fi

# Запрос названия кошелька у пользователя
read -p "Введите название вашего кошелька: " wallet_name

# Проверка и удаление существующей папки
if [ -d "allora-chain" ]; then
    echo "Папка allora-chain уже существует. Удаление..."
    rm -rf allora-chain
fi

# Установка Allorad Wallet
echo "Установка Allorad Wallet..."
if curl -sSL https://raw.githubusercontent.com/allora-network/allora-chain/main/install.sh | bash -s -- v0.2.11; then
   
   # Добавление allorad в PATH
   export PATH=$PATH:$HOME/.local/bin
   echo "export PATH=\$PATH:$HOME/.local/bin" >> $HOME/.bashrc
   
   # Проверка версии allorad
   if allorad version; then
       echo "Установка Allorad Wallet: Успешно"
   else
       echo "Установка Allorad Wallet: Ошибка"
       exit 1
   fi
else
    echo "Установка Allorad Wallet: Ошибка"
    exit 1
fi

# После того, как пользователь ввел название кошелька, предлагается выбрать действие
echo -e "\nВыберите действие:"
echo "1. Создать новый кошелек"
echo "2. Использовать существующий кошелек"
read -p "Выберите действие: " action

if [ "$action" == "1" ]; then
    # Создание нового кошелька с введенным пользователем названием
    echo "Создание нового кошелька с названием $wallet_name..."
	echo "Enter keyring passphrase (attempt 1/3):"
    wallet_info_file="$HOME/${wallet_name}_wallet_info.txt"
    
    # Запись вывода в переменную и сохранение её в файл
    wallet_output=$(allorad keys add $wallet_name 2>&1)
    echo "$wallet_output" | tee "$wallet_info_file"
    
    # Проверка успешного создания кошелька
    if echo "$wallet_output" | grep -q "name: $wallet_name"; then
        echo "Новый кошелек успешно создан. Информация сохранена в $wallet_info_file"
        
        # Вывод содержимого файла с информацией о кошельке
        echo -e "\nСодержимое файла с информацией о кошельке ($wallet_info_file):"
        cat "$wallet_info_file"
    else
        echo "Ошибка при создании нового кошелька"
        exit 1
    fi
elif [ "$action" == "2" ]; then
    # Проверка, хочет ли пользователь использовать существующий кошелек
    read -p "Хотите использовать существующий кошелек с названием $wallet_name? (yes/no): " use_existing

    if [ "$use_existing" == "yes" ]; then
        # Использование существующего кошелька
        echo "Использование существующего кошелька ($wallet_name)..."
        wallet_output=$(allorad keys add $wallet_name --recover 2>&1)
        echo "$wallet_output" | tee "$wallet_info_file"
        
    else
        echo "Выбрано некорректное действие"
        exit 1
    fi
else
    echo "Выбрано некорректное действие"
    exit 1
fi
