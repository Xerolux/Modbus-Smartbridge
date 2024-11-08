#!/bin/bash

CONFIG_FILE="/etc/modbus_smartbridge/config.yaml"

# Funktion zum Schreiben in die config.yaml
write_config() {
    cat > "$CONFIG_FILE" <<EOL
server:
  host: "$server_host"
  port: $server_port

clients:
EOL

    for i in "${!client_ids[@]}"; do
        cat >> "$CONFIG_FILE" <<EOL
  - id: ${client_ids[$i]}
    host: "${client_hosts[$i]}"
    port: ${client_ports[$i]}
    unit_id: ${client_unit_ids[$i]}
    interval: ${client_intervals[$i]}
    timeout: ${client_timeouts[$i]}
    register_type: "${client_register_types[$i]}"
    max_retries: ${client_max_retries[$i]}
EOL
    done

    cat >> "$CONFIG_FILE" <<EOL

storage:
  type: "$storage_type"
  path: "$storage_path"

cache:
  ttl: $cache_ttl

logging:
  enabled: $logging_enabled
  level: "$logging_level"

health_check:
  enabled: $health_check_enabled
  interval: $health_check_interval
EOL
}

# Menü für die Konfiguration
while true; do
    choice=$(whiptail --title "Modbus SmartBridge Konfiguration" --menu "Wählen Sie eine Option" 20 60 10 \
        "1" "Server konfigurieren" \
        "2" "Modbus-Clients konfigurieren" \
        "3" "Speicheroptionen konfigurieren" \
        "4" "Cache-Einstellungen konfigurieren" \
        "5" "Logging-Einstellungen konfigurieren" \
        "6" "Health-Check-Einstellungen konfigurieren" \
        "7" "Speichern und Beenden" \
        "8" "Abbrechen" 3>&1 1>&2 2>&3)

    case $choice in
        1)
            server_host=$(whiptail --inputbox "Server Host:" 8 40 "$server_host" --title "Server Host" 3>&1 1>&2 2>&3)
            server_port=$(whiptail --inputbox "Server Port:" 8 40 "$server_port" --title "Server Port" 3>&1 1>&2 2>&3)
            ;;
        2)
            client_count=$(whiptail --inputbox "Anzahl der Clients:" 8 40 "${#client_ids[@]}" --title "Clients Anzahl" 3>&1 1>&2 2>&3)
            client_ids=()
            client_hosts=()
            client_ports=()
            client_unit_ids=()
            client_intervals=()
            client_timeouts=()
            client_register_types=()
            client_max_retries=()

            for ((i=0; i<client_count; i++)); do
                client_ids[i]=$(whiptail --inputbox "Client ID [$i]:" 8 40 "${client_ids[i]}" --title "Client ID" 3>&1 1>&2 2>&3)
                client_hosts[i]=$(whiptail --inputbox "Client Host [$i]:" 8 40 "${client_hosts[i]}" --title "Client Host" 3>&1 1>&2 2>&3)
                client_ports[i]=$(whiptail --inputbox "Client Port [$i]:" 8 40 "${client_ports[i]}" --title "Client Port" 3>&1 1>&2 2>&3)
                client_unit_ids[i]=$(whiptail --inputbox "Client Unit ID [$i]:" 8 40 "${client_unit_ids[i]}" --title "Client Unit ID" 3>&1 1>&2 2>&3)
                client_intervals[i]=$(whiptail --inputbox "Abfrageintervall [$i] (Sekunden):" 8 40 "${client_intervals[i]}" --title "Abfrageintervall" 3>&1 1>&2 2>&3)
                client_timeouts[i]=$(whiptail --inputbox "Timeout [$i] (Sekunden):" 8 40 "${client_timeouts[i]}" --title "Timeout" 3>&1 1>&2 2>&3)
                client_register_types[i]=$(whiptail --inputbox "Registertyp [$i] (holding/input/coil/discrete/all):" 8 40 "${client_register_types[i]}" --title "Registertyp" 3>&1 1>&2 2>&3)
                client_max_retries[i]=$(whiptail --inputbox "Maximale Wiederholungen [$i]:" 8 40 "${client_max_retries[i]}" --title "Maximale Wiederholungen" 3>&1 1>&2 2>&3)
            done
            ;;
        3)
            storage_type=$(whiptail --inputbox "Speichertyp (ram/ramdisk):" 8 40 "$storage_type" --title "Speichertyp" 3>&1 1>&2 2>&3)
            storage_path=$(whiptail --inputbox "Speicherpfad:" 8 40 "$storage_path" --title "Speicherpfad" 3>&1 1>&2 2>&3)
            ;;
        4)
            cache_ttl=$(whiptail --inputbox "Cache Time-to-Live (TTL) in Sekunden:" 8 40 "$cache_ttl" --title "Cache TTL" 3>&1 1>&2 2>&3)
            ;;
        5)
            logging_enabled=$(whiptail --yesno "Logging aktivieren?" 8 40 --title "Logging aktivieren" 3>&1 1>&2 2>&3 && echo "true" || echo "false")
            logging_level=$(whiptail --inputbox "Logging Level (DEBUG/INFO/WARNING/ERROR):" 8 40 "$logging_level" --title "Logging Level" 3>&1 1>&2 2>&3)
            ;;
        6)
            health_check_enabled=$(whiptail --yesno "Health-Check aktivieren?" 8 40 --title "Health-Check aktivieren" 3>&1 1>&2 2>&3 && echo "true" || echo "false")
            health_check_interval=$(whiptail --inputbox "Health-Check Intervall in Sekunden:" 8 40 "$health_check_interval" --title "Health-Check Intervall" 3>&1 1>&2 2>&3)
            ;;
        7)
            write_config
            whiptail --msgbox "Konfiguration gespeichert in $CONFIG_FILE" 8 40 --title "Speichern erfolgreich"
            break
            ;;
        8)
            whiptail --msgbox "Abbruch ohne Speichern." 8 40 --title "Abbruch"
            exit
            ;;
        *)
            whiptail --msgbox "Ungültige Auswahl!" 8 40 --title "Fehler"
            ;;
    esac
done
