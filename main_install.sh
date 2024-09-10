#!/bin/bash

# Логотип
echo -e '\e[40m\e[32m'
echo -e ' █████  ██      ██       ██████  ██████   █████          ██ ███    ██ ███████ ████████  █████  ██      ██      ███████ ██████  '
echo -e '██   ██ ██      ██      ██    ██ ██   ██ ██   ██         ██ ████   ██ ██         ██    ██   ██ ██      ██      ██      ██   ██'
echo -e '███████ ██      ██      ██    ██ ██████  ███████         ██ ██ ██  ██ ███████    ██    ███████ ██      ██      █████   ██████ '
echo -e '██   ██ ██      ██      ██    ██ ██   ██ ██   ██         ██ ██  ██ ██      ██    ██    ██   ██ ██      ██      ██      ██   ██'
echo -e '██   ██ ███████ ███████  ██████  ██   ██ ██   ██ ███████ ██ ██   ████ ███████    ██    ██   ██ ███████ ███████ ███████ ██   ██'
echo -e '\e[0m'

echo -e "\nCreated by @AlexMak248\n"

sleep 2

while true; do
    echo "1. Установить нужные библиотеки и зависимости для ноды Allora"
	echo "2. Создание кошелька"
	echo "3. Создать основной контейнер для подключения к Allora"
    echo "4. Проверить логи ноды Allora"
    echo "5. Проверка предсказания ноды"
    echo "6. Выйти из скрипта"
    read -p "Выберите опцию: " option

    case $option in
        1)
            echo "Установка библиотек и зависимостей"
            
            # Установка нужных библиотек
            ./install_libraries.sh
            
            echo "Установка завершена успешно."
            ;;
        2)
            echo "Создание кошелька"
            ./install_allorad_wallet.sh
            ;;
        3)
            echo "Создание основного контейнера для подключения к Allora"
            ./create_main.sh
            ;;
        4)
            echo "Проверка  логов ноды"
			cd allora-huggingface-walkthrough
            if docker compose logs -f worker; then
				echo "Логи контейнера успешно выведены."
			else
				echo "Не удалось вывести логи контейнера. Проверьте состояние Docker."
			fi
			;;
		
		5)
			read -p "Введите название монеты (например, ETH): " TOKEN

			# Проверка предсказания через ноду
			
            echo "Проверка предсказания ноды $TOKEN"
            response=$(curl -s http://localhost:8000/inference/"$TOKEN")
            if [ -z "$response" ]; then
				echo "Не удалось получить цену $TOKEN. Проверьте состояние ноды."
			else
				echo "Цена $TOKEN: $response"
			fi
            ;;
			
		6)
            echo "Выход из скрипта."
            exit 0
            ;;
		*)
            echo "Неверная опция. Пожалуйста, выберите 1, 2, 3, 4 или 5."
            ;;
    esac
done
