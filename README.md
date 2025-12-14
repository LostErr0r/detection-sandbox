# detection-sandbox
Для начала установим git
```
sudo apt install git -y 
```
Клонируем проект
```
git clone https://github.com/LostErr0r/detection-sandbox
```
Переходим в папку, устанавливаем все нужные утилиты, включаем auditd, заполняем конфиг auditd
```
cd detection-sandbox
./setup.sh
```
```
newgrp docker
make deploy
```


# troubleshiiting
Если в dashboard нет никакних бордов, то добавляем вручную, из главной папки проекта где лежит файл export.ndjson

```
curl -sS -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  --form file=@"./export.ndjson"
```
