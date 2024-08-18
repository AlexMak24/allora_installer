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
read -p "Введите название модели (например, amazon/chronos-t5-tiny): " MODEL_NAME
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

# Создание копии config.example.json как config.json
cp config.example.json config.json

# Замена значений в config.json с использованием введенных данных
echo "Обновление конфигурационного файла config.json..."

jq --arg walletName "$WALLET_NAME" \
   --arg mnemonic "$MNEMONIC" \
   --arg topicId "$TOPIC_ID" \
   --arg token "$TOKEN" \
   --arg rpcAddress "$RPC_ADDRESS" \
   '.wallet.addressKeyName = $walletName |
    .wallet.addressRestoreMnemonic = $mnemonic |
    .wallet.nodeRpc = $rpcAddress |
    .worker[0].topicId = ($topicId | tonumber) |
    .worker[0].parameters.Token = $token' config.json > temp.json && mv temp.json config.json

if [ $? -eq 0 ]; then
    echo "Конфигурационный файл config.json успешно обновлен:"
    cat config.json
else
    echo "Ошибка при обновлении config.json"
    exit 1
fi

# Создание и редактирование файла app.py
cat <<EOF > app.py
from flask import Flask, Response
import requests
import json
import pandas as pd
import torch
from chronos import ChronosPipeline

# create our Flask app
app = Flask(__name__)

# define the Hugging Face model we will use
model_name = "$MODEL_NAME"

def get_coingecko_url(token):
    base_url = "https://api.coingecko.com/api/v3/coins/"
    token_map = {
        'ETH': 'ethereum',
        'SOL': 'solana',
        'BTC': 'bitcoin',
        'BNB': 'binancecoin',
        'ARB': 'arbitrum'
    }
    
    token = token.upper()
    if token in token_map:
        url = f"{base_url}{token_map[token]}/market_chart?vs_currency=usd&days=30&interval=daily"
        return url
    else:
        raise ValueError("Unsupported token")

# define our endpoint
@app.route("/inference/<string:token>")
def get_inference(token):
    """Generate inference for given token."""
    try:
        # use a pipeline as a high-level helper
        pipeline = ChronosPipeline.from_pretrained(
            model_name,
            device_map="auto",
            torch_dtype=torch.bfloat16,
        )
    except Exception as e:
        return Response(json.dumps({"pipeline error": str(e)}), status=500, mimetype='application/json')

    try:
        # get the data from Coingecko
        url = get_coingecko_url(token)
    except ValueError as e:
        return Response(json.dumps({"error": str(e)}), status=400, mimetype='application/json')

    headers = {
        "accept": "application/json",
        "x-cg-demo-api-key": "$API_KEY" # replace with your API key
    }

    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        data = response.json()
        df = pd.DataFrame(data["prices"])
        df.columns = ["date", "price"]
        df["date"] = pd.to_datetime(df["date"], unit='ms')
        df = df[:-1] # removing today's price
        print(df.tail(5))
    else:
        return Response(json.dumps({"Failed to retrieve data from the API": str(response.text)}), 
                        status=response.status_code, 
                        mimetype='application/json')

    # define the context and the prediction length
    context = torch.tensor(df["price"])
    prediction_length = 1

    try:
        forecast = pipeline.predict(context, prediction_length)  # shape [num_series, num_samples, prediction_length]
        print(forecast[0].mean().item()) # taking the mean of the forecasted prediction
        return Response(str(forecast[0].mean().item()), status=200)
    except Exception as e:
        return Response(json.dumps({"error": str(e)}), status=500, mimetype='application/json')

# run our Flask app
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8000, debug=True)
EOF

# Замените плейсхолдер API ключа в файле app.py
sed -i "s/<Your Coingecko API key>/$API_KEY/" app.py

if [ $? -eq 0 ]; then
    echo "Файл app.py успешно обновлен:"
    cat app.py
else
    echo "Ошибка при обновлении app.py"
    exit 1
fi

# Обновление requirements.txt
cat <<EOF > requirements.txt
flask[async]
gunicorn[gthread]
numpy==1.26.2
pandas==2.1.3
Requests==2.32.0
scikit_learn==1.3.2
transformers[torch]
git+https://github.com/amazon-science/chronos-forecasting.git
EOF

if [ $? -eq 0 ]; then
    echo "Файл requirements.txt успешно обновлен:"
    cat requirements.txt
else
    echo "Ошибка при обновлении requirements.txt"
    exit 1
fi

# Сделать файл init.config исполняемым и запустить его
chmod +x init.config
./init.config

# Запуск Docker Compose в фоновом режиме
echo "Запуск ноды..."
docker compose up --build -d
