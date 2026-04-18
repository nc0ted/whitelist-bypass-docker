import os, time, vk_api, docker, re
from vk_api.longpoll import VkLongPoll, VkEventType

VK_TOKEN = os.getenv('VK_TOKEN')
USER_ID = os.getenv('ALLOWED_USER_ID')
CONTAINER_NAME = os.getenv('CREATOR_CONTAINER_NAME')
LINK_FILE = os.getenv('CALL_LINK_FILE')

vk_session = vk_api.VkApi(token=VK_TOKEN)
vk = vk_session.get_api()
longpoll = VkLongPoll(vk_session)
docker_client = docker.DockerClient(base_url='unix:///var/run/docker.sock')

def send(msg):
    vk.messages.send(user_id=USER_ID, message=msg, random_id=int(time.time() * 1000))

def get_link():
    if not os.path.exists(LINK_FILE): return None
    with open(LINK_FILE, 'r') as f:
        links = re.findall(r'https://telemost\.yandex\.ru/j/\d+', f.read())
        return links[-1] if links else None

def restart_creator():
    try:
        container = docker_client.containers.get(CONTAINER_NAME)
        if os.path.exists(LINK_FILE): os.remove(LINK_FILE)
        container.restart()
        send("🔄 Перезапуск...")
        for _ in range(10):
            time.sleep(2)
            link = get_link()
            if link:
                send(f"✅ Ссылка:\n{link}")
                return
        send("❌ Ссылка не появилась.")
    except Exception as e:
        send(f"❌ Ошибка Docker: {e}")

def stop_creator():
    try:
        container = docker_client.containers.get(CONTAINER_NAME)
        if container.status == 'running':
            container.stop()
            if os.path.exists(LINK_FILE): open(LINK_FILE, 'w').close()
            send("⏹️ Контейнер остановлен, ссылка очищена")
        else:
            send(f"⚠️ Контейнер уже остановлен (статус: {container.status})")
    except Exception as e:
        send(f"❌ Ошибка: {e}")

def get_logs():
    try:
        container = docker_client.containers.get(CONTAINER_NAME)
        logs = container.logs(tail=10).decode('utf-8')
        send(f"📋 Последние 10 строк:\n\n{logs}")
    except Exception as e:
        send(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    for event in longpoll.listen():
        if event.type == VkEventType.MESSAGE_NEW and event.to_me and str(event.user_id) == str(USER_ID):
            cmd = event.text.strip().lower()
            if cmd == '/restart': restart_creator()
            elif cmd == '/stop': stop_creator()
            elif cmd == '/link': send(f"🔗 Ссылка: {get_link() or 'не найдена'}")
            elif cmd == '/logs': get_logs()