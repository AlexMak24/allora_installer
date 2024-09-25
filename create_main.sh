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
read -p "Введите имя кошелька: " WALLET_NAME
read -p "Введите мнемоническую фразу: " MNEMONIC
read -p "Введите ваш Coingecko API ключ: " API_KEY
read -p "Введите название модели (например, BiLSTM): " MODEL_NAME
read -p "Введите RPC-адрес (например, https://allora-rpc.testnet-1.testnet.allora.network/): " RPC_ADDRESS

# Проверка наличия папки с воркером и её обновление
if [ -d "basic-coin-prediction-node" ]; then
    echo "Папка basic-coin-prediction-node уже существует. Удаление..."
    rm -rf basic-coin-prediction-node
fi

echo "Загрузка файлов воркера..."
if git clone https://github.com/allora-network/basic-coin-prediction-node ; then
    echo "Установка файлов воркера: Успешно"
else
    echo "Установка файлов воркера: Ошибка"
    exit 1
fi
cd basic-coin-prediction-node

cp .env.example .env

echo "Создание .env файла с необходимыми параметрами..."
cat > .env <<EOL
TOKEN=ETH
TRAINING_DAYS=30
TIMEFRAME=4h
MODEL=SVR
REGION=US
DATA_PROVIDER=binance
CG_API_KEY=$API_KEY
EOL

echo ".env файл:"
cat .env


fi
ls -l
cd ..
ls -l
docker system prune -a
echo "в папке"

# Клонирование репозитория с моделями, если еще не сделано
if [ ! -d "allora_models" ]; then
    echo "Клонирование репозитория с моделями..."
    if git clone https://github.com/AlexMak24/allora_models ; then
        echo "Клонирование репозитория: Успешно"
    else
        echo "Ошибка при клонировании репозитория"
        exit 1
    fi
fi

# Проверка наличия папки с выбранной моделью и её копирование
if [ -d "allora_models/$MODEL_NAME" ]; then
    echo "Копирование файлов из папки модели $MODEL_NAME..."
    sudo cp -r allora_models/$MODEL_NAME/* ./  # копирование файлов из модели
    echo "Файлы модели $MODEL_NAME успешно скопированы"
else
    echo "Папка модели $MODEL_NAME не найдена в allora_models"
    exit 1
fi

# Создание копии config.example.json как config.json
cp config.example.json config.json

cat > config.json <<EOL
{
   "wallet": {
       "addressKeyName": "$WALLET_NAME",
       "addressRestoreMnemonic": "$MNEMONIC",
       "alloraHomeDir": "",
       "gas": "auto",
       "gasAdjustment": 1.5,
       "nodeRpc": "$RPC_ADDRESS",
       "maxRetries": 1,
       "delay": 1,
       "submitTx": true
   },
   "worker": [
       {
           "topicId": 1,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 1,
           "parameters": {
               "InferenceEndpoint": "http://inference:8000/inference/{Token}",
               "Token": "ETH"
           }
       },
       {
           "topicId": 2,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 3,
           "parameters": {
               "InferenceEndpoint": "http://inference:8000/inference/{Token}",
               "Token": "ETH"
           }
       },
       {
           "topicId": 3,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 5,
           "parameters": {
               "InferenceEndpoint": "http://inference:8000/inference/{Token}",
               "Token": "BTC"
           }
       },
       {
           "topicId": 4,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 2,
           "parameters": {
               "InferenceEndpoint": "http://inference:8000/inference/{Token}",
               "Token": "BTC"
           }
       },
       {
           "topicId": 5,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 4,
           "parameters": {
               "InferenceEndpoint": "http://inference:8000/inference/{Token}",
               "Token": "SOL"
           }
       },
       {
           "topicId": 6,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 5,
           "parameters": {
               "InferenceEndpoint": "http://inference:8000/inference/{Token}",
               "Token": "SOL"
           }
       },
       {
           "topicId": 7,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 2,
           "parameters": {
               "InferenceEndpoint": "http://inference:8000/inference/{Token}",
               "Token": "ETH"
           }
       },
       {
           "topicId": 8,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 3,
           "parameters": {
               "InferenceEndpoint": "http://inference:8000/inference/{Token}",
               "Token": "BNB"
           }
       },
       {
           "topicId": 9,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 5,
           "parameters": {
               "InferenceEndpoint": "http://inference:8000/inference/{Token}",
               "Token": "ARB"
           }
       }
       
   ]
}
EOL



# Замена значений в config.json с использованием введенных данных
echo "Обновление конфигурационного файла config.json..."

jq --arg walletName "$WALLET_NAME" \
   --arg mnemonic "$MNEMONIC" \
   --arg rpcAddress "$RPC_ADDRESS" \
   '.wallet.addressKeyName = $walletName |
    .wallet.addressRestoreMnemonic = $mnemonic |
    .wallet.nodeRpc = $rpcAddress' config.json > temp.json && mv temp.json config.json

if [ $? -eq 0 ]; then
    echo "Конфигурационный файл config.json успешно обновлен:"
    cat config.json
else
    echo "Ошибка при обновлении config.json"
    exit 1
fi

# Установка зависимостей
pip install -r requirements.txt

#Остановка и удаление всех контейнеров
docker stop $(docker ps -aq) && docker rm $(docker ps -aq)


chmod +x init.config
./init.config 
# Запуск Docker Compose в фоновом режиме
echo "Запуск ноды..."

#Удаление и обновление образа контейнера
docker-compose down --rmi all
docker system prune -a

docker compose pull
docker compose up --build -d
