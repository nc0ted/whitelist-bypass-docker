# Whitelist Bypass - Docker Setup

Инструкция по запуску whitelist-bypass через Docker для обхода блокировок через Yandex Telemost.

## Требования

**Server (VPS):**

- Linux VPS с публичным IP (например, в Германии)
- Docker установлен
- Аккаунт Yandex с доступом к Telemost

**Client (локальная машина):**

- Linux: Docker
- Windows: WSL2 + Docker Desktop
- macOS: Docker Desktop

## Быстрый старт

### 1. Server (Creator) - VPS

```bash
# Клонировать репозиторий
git clone https://github.com/nc0ted/whitelist-bypass-docker.git
cd  whitelist-bypass-docker

# Получить cookies от Yandex Telemost
# 1. Откройте https://telemost.yandex.ru в браузере
# 2. Войдите в аккаунт
# 3. Используя расширение Cookie-Editor экспортируйте куки в буфер обмена

# Создать файл с cookies
nano cookies-yandex.json
# Вставьте JSON с cookies, сохраните (Ctrl+O, Enter, Ctrl+X)

# Собрать server image
cd docker
./build-server.sh
docker build -f Dockerfile.server -t whitelist-bypass-server ..

# Запустить server
docker run -d \
  --name whitelist-bypass-server \
  -v ~/whitelist-bypass-docker/cookies-yandex.json:/app/cookies-yandex.json \
  -e PLATFORM=telemost \
  -e TUNNEL_MODE=video \
  whitelist-bypass-server:latest

# Посмотреть логи и скопировать CALL_LINK
docker logs -f whitelist-bypass-server
# Найдите строку: join_link: https://telemost.yandex.ru/j/XXXXX
# Скопируйте эту ссылку для клиента
```

### 2. Client (Joiner) - Локальная машина

**Linux:**

```bash
# Клонировать репозиторий
git clone https://github.com/nc0ted/whitelist-bypass-docker.git
cd  whitelist-bypass-docker/docker

# Создать .env файл
cp .env.example .env
nano .env
# Вставьте CALL_LINK из логов сервера:
# CALL_LINK=https://telemost.yandex.ru/j/XXXXX

# Собрать client image
./build-client.sh
docker build -f Dockerfile.client -t whitelist-bypass-client ..

# Запустить client
docker-compose -f docker-compose.client.yml up -d

# Проверить что работает
curl --proxy socks5h://127.0.0.1:1080 https://ifconfig.me
# Должен показать IP вашего VPS
```

**Windows (WSL2):**

```powershell
# 1. Установите WSL2 (если еще не установлен)
wsl --install

# 2. Установите Docker Desktop for Windows
# Скачайте с https://www.docker.com/products/docker-desktop

# 3. В Docker Desktop включите WSL2 integration

# 4. Откройте WSL2 терминал и следуйте инструкциям для Linux выше
wsl
```

**macOS:**

```bash
# 1. Установите Docker Desktop for Mac
# Скачайте с https://www.docker.com/products/docker-desktop

# 2. Следуйте инструкциям для Linux выше
```

### 3. Использование прокси

**SOCKS5 прокси доступен на:**

- Локально: `127.0.0.1:1080`
- В локальной сети: `<IP вашего клиента>:1080` (например `192.168.1.100:1080`)

**Пример настройки в приложениях:**

**Firefox:**

1. Settings → Network Settings → Manual proxy configuration
2. SOCKS Host: `127.0.0.1`, Port: `1080`
3. SOCKS v5: ✓
4. Proxy DNS when using SOCKS v5: ✓ (ВАЖНО!)

Аналогично в телеграм и других приложениях.

В Happ **+** в правом верхнем углу → ручной ввод → Протокол Socks, Адрес - IP устройства где запущен клиент, Порт - 1080

## Переменные окружения

**Server (.env или docker run -e):**

- `PLATFORM` - платформа: `telemost` (по умолчанию) или `vk`
- `TUNNEL_MODE` - режим туннеля: `video` (рекомендуется) или `dc` (экспериментальный)
- `RESOURCES` - режим ресурсов: `default`, `moderate`, `unlimited`
- `COOKIE_FILE` - путь к файлу cookies (по умолчанию `/app/cookies-yandex.json`)

**Client (.env):**

- `PLATFORM` - платформа: `telemost` (по умолчанию) или `vk`
- `TUNNEL_MODE` - режим туннеля: `video` (рекомендуется) или `dc` (экспериментальный)
- `CALL_LINK` - ссылка на звонок от сервера (ОБЯЗАТЕЛЬНО!)
- `DISPLAY_NAME` - имя в звонке (по умолчанию `Joiner`)

## Доступ из локальной сети

Чтобы использовать прокси с других устройств (телефон, планшет):

1. Узнайте IP вашего клиента в локальной сети:

   ```bash
   ip addr show | grep "inet 192"
   # Например: 192.168.1.100
   ```
2. На других устройствах используйте:

   - SOCKS5: `192.168.1.100:1080`
3. ⚠️ Прокси доступен всем в локальной сети без пароля.

## Обход рекурсии с TUN mode

Если используете VPN клиент с TUN mode на том же устройстве где запущен client, может возникать рекурсия и впн не будет работать. Можете попробовать добавить bypass rules для Yandex доменов, но лучше просто использовать прокси отдельно в приложениях, либо перенести клиента на другое устройство в локальной сети.

## Проверка работы

```bash
# Проверить прокси
curl --proxy socks5h://127.0.0.1:1080 https://ifconfig.me
# Должен показать IP VPS
```

## Остановка и перезапуск

**Server:**

```bash
docker stop whitelist-bypass-server
docker start whitelist-bypass-server
docker logs -f whitelist-bypass-server
```

**Client:**

```bash
cd docker
docker-compose -f docker-compose.client.yml down
docker-compose -f docker-compose.client.yml up -d
docker logs -f whitelist-bypass-joiner
```

## Известные ограничения

- ✅ **Video mode** - протестирован и работает стабильно
- ⚠️ **DC mode** - экспериментальный, может не работать
- ✅ **Yandex Telemost** - протестирован и работает
- ⚠️ **VK Call** - не протестирован в Docker mode
- ⚠️ **Windows** - требует WSL2, нативный Docker Desktop может не работать из-за `network_mode: host`
