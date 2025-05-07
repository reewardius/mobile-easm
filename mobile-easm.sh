#!/bin/bash

rm -f *.txt && rm -rf *_APK{,/,Pure} _xapk_temp
shopt -s nullglob

# Создаём временную папку для .apk из .xapk
mkdir -p "_xapk_temp"

# Обрабатываем все файлы .apk и .xapk в папке
for file in *.apk *.xapk; do
    if [[ "$file" == *.xapk ]]; then
        # Если файл .xapk, распаковываем его
        base="${file%.*}"
        apk_output_dir="${base}_APK"  # Общая папка для всех APK

        # Создаём директорию для распаковки .apk
        mkdir -p "$apk_output_dir"

        # Временная папка для распаковки .xapk
        temp_dir="_xapk_temp/$base"
        mkdir -p "$temp_dir"

        echo "[*] Распаковка \"$file\"..."
        unzip -qq "$file" -d "$temp_dir"

        # Находим все .apk внутри .xapk
        mapfile -t inner_apks < <(find "$temp_dir" -name '*.apk')

        for inner_apk in "${inner_apks[@]}"; do
            # Получаем имя .apk внутри и создаём имя для папки внутри общей папки
            inner_name="$(basename "${inner_apk%.*}")"
            out_dir="$apk_output_dir/$inner_name"  # Каждое .apk будет в своей папке

            # Извлекаем .apk в соответствующую папку
            mkdir -p "$out_dir"
            echo "[*] Извлечение \"$inner_apk\" в \"$out_dir\""
            java -jar /usr/local/bin/apktool.jar d -f "$inner_apk" -o "$out_dir" >/dev/null 2>&1
        done

        # После того как все .apk извлечены, сканируем всю папку
        echo "[*] Сканирование \"$apk_output_dir\"..."
        echo $apk_output_dir | nuclei -silent -file -t nuclei-fast-templates/ -es unknown -o "$apk_output_dir.txt"
        echo "[+] Готово: \"$apk_output_dir.txt\""
    elif [[ "$file" == *.apk ]]; then
        # Если файл .apk, сразу обрабатываем его
        base="${file%.*}"
        apk_output_dir="${base}_APK"  # Общая папка для APK

        # Создаём директорию для распаковки .apk
        mkdir -p "$apk_output_dir"

        # Извлекаем .apk
        echo "[*] Извлечение \"$file\" в \"$apk_output_dir\""
        java -jar /usr/local/bin/apktool.jar d -f "$file" -o "$apk_output_dir" >/dev/null 2>&1

        # После того как .apk извлечен, сканируем всю папку
        echo "[*] Сканирование \"$apk_output_dir\"..."
        echo $apk_output_dir | nuclei -silent -file -t nuclei-fast-templates/ -es unknown -o "$apk_output_dir.txt"
        echo "[+] Готово: \"$apk_output_dir.txt\""
    fi
done

# Удаляем временные файлы
rm -rf "_xapk_temp"
cat *.txt > results.txt
