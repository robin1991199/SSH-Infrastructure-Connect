#!/bin/bash

clear
echo "SSH Infrastructure Connect"

SERVER_FILE="servers.txt"

# ===== Auto-create servers.txt if missing =====
if [ ! -f "$SERVER_FILE" ]; then
    echo "servers.txt not found. Creating default file..."
    echo "root@127.0.0.1:22,Localhost Example" > "$SERVER_FILE"
    echo "Default servers.txt created!"
    read -p "Press enter to continue..."
fi

while true; do
clear
echo "=================================="
echo "         SSH SERVER MENU"
echo "=================================="
echo

count=0
declare -a entries
declare -a names

# ===== Read servers.txt =====
while IFS=',' read -r server name; do
    if [[ "$server" != "exampleuser@ipadress:port" && "$server" != "" ]]; then
        entries[$count]=$server
        names[$count]=$name
        echo "[$((count+1))] $name - $server"
        ((count++))
    fi
done < "$SERVER_FILE"

if [ $count -eq 0 ]; then
    echo "No servers found."
    echo
    echo "[A] Add new server"
    echo "[Q] Quit"
    read -p "Select: " choice
    case "$choice" in
        A|a) addserver ;;
        Q|q) exit ;;
    esac
    continue
fi

echo
echo "[A] Add new server"
echo "[D] Delete server"
echo "[Q] Quit"
echo

read -p "Select (Number, A, D, Q): " choice

case "$choice" in
    Q|q) exit ;;
    A|a)
        clear
        echo "ADD NEW SERVER"
        echo "Format: user@ip:port"
        read -p "Enter server: " newserver
        read -p "Enter server name: " newname

        if [[ "$newserver" =~ .+@.+:.+ ]]; then
            echo "$newserver,$newname" >> "$SERVER_FILE"
            echo "Server added!"
            sleep 1
        else
            echo "Invalid format!"
            sleep 2
        fi
        ;;
    D|d)
        clear
        echo "DELETE SERVER"
        echo

        for i in "${!entries[@]}"; do
            echo "[$((i+1))] ${names[$i]} (${entries[$i]})"
        done

        echo
        read -p "Enter number to delete (or M): " del

        if [[ "$del" =~ ^[0-9]+$ ]] && [ "$del" -ge 1 ] && [ "$del" -le "$count" ]; then
            index=$((del-1))
            target="${entries[$index]}"
            name="${names[$index]}"

            read -p "Delete '$name'? (Y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                grep -v "^$target" "$SERVER_FILE" > tmp.txt
                mv tmp.txt "$SERVER_FILE"
                echo "Server removed."
                sleep 2
            fi
        fi
        ;;
    *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
            index=$((choice-1))
            server="${entries[$index]}"

            user=$(echo "$server" | cut -d@ -f1)
            host=$(echo "$server" | cut -d@ -f2 | cut -d: -f1)
            port=$(echo "$server" | cut -d: -f2)

            [ -z "$port" ] && port=22

            clear
            echo "=================================="
            echo "     ESTABLISHING CONNECTION"
            echo "=================================="
            echo "User: $user"
            echo "Host: $host"
            echo "Port: $port"
            echo "Name: ${names[$index]}"
            echo "=================================="
            echo

            ssh -p "$port" "$user@$host"

            echo
            read -p "Connection closed. Press enter..."
        fi
        ;;
esac

done
