#!/bin/bash

# Variablen für Verzeichnisse
INSTALL_DIR="/etc/modbus_smartbridge"
SERVICE_FILE="/etc/systemd/system/modbus_smartbridge.service"
CONFIG_FILE="$INSTALL_DIR/config.yaml"
CONFIG_SCRIPT="/usr/local/bin/modbus_smartbridge_config.sh"
LOG_FILE="/var/log/modbus_smartbridge_install.log"

# Funktion zur Protokollierung
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE"
}

# Funktion zur Überprüfung und Installation von Paketen
install_package() {
    if ! command -v "$1" &> /dev/null; then
        log_message "$1 wird installiert..."
        sudo apt install -y "$1"
    else
        log_message "$1 ist bereits installiert."
    fi
}

# Funktion zur Überprüfung der Netzwerkverbindung
check_network() {
    if ! ping -c 1 google.com &> /dev/null; then
        log_message "Netzwerkverbindung fehlt. Bitte stellen Sie sicher, dass Sie mit dem Internet verbunden sind."
        exit 1
    else
        log_message "Netzwerkverbindung erfolgreich."
    fi
}

# Funktion zur Installation
install() {
    log_message "Starte Installation von Modbus SmartBridge..."

    # Überprüfen der Netzwerkverbindung
    check_network

    # System aktualisieren und upgraden
    log_message "Führe Systemupdate und Upgrade durch..."
    sudo apt update && sudo apt upgrade -y

    # Überprüfen und Installieren von Python3, venv und whiptail
    install_package python3
    install_package python3-venv
    install_package whiptail

    # Installationsverzeichnis erstellen und Dateien kopieren
    log_message "Erstelle Verzeichnis $INSTALL_DIR..."
    sudo mkdir -p $INSTALL_DIR
    log_message "Kopiere Dateien..."
    sudo cp -r . $INSTALL_DIR

    # Virtuelle Umgebung erstellen und Abhängigkeiten installieren
    log_message "Erstelle virtuelle Umgebung und installiere Abhängigkeiten..."
    cd $INSTALL_DIR
    python3 -m venv venv
    source venv/bin/activate

    # Anforderungen installieren und Fehler überprüfen
    log_message "Installiere Python-Abhängigkeiten..."
    if ! pip install -r requirements.txt; then
        log_message "Fehler beim Installieren der Abhängigkeiten."
        exit 1
    fi
    log_message "Abhängigkeiten erfolgreich installiert."

    # Beispiel-Konfigurationsdatei erstellen, falls keine vorhanden ist
    if [ ! -f "$CONFIG_FILE" ]; then
        log_message "Erstelle Beispiel-Konfigurationsdatei..."
        sudo cp config.yaml.example "$CONFIG_FILE"
    else
        log_message "Konfigurationsdatei vorhanden, wird nicht überschrieben."
    fi

    # Systemd-Service-Datei erstellen
    log_message "Erstelle Systemd-Service..."
    sudo bash -c "cat > $SERVICE_FILE" << EOL
[Unit]
Description=Modbus SmartBridge Service
After=network.target

[Service]
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/modbus_smartbridge.py
Restart=always
User=$(whoami)
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOL

    # Konfigurationsskript global verfügbar machen
    log_message "Erstelle globales Konfigurationsskript..."
    sudo cp $INSTALL_DIR/modbus_smartbridge_config.sh $CONFIG_SCRIPT
    sudo chmod +x $CONFIG_SCRIPT

    # Service starten und aktivieren
    log_message "Aktiviere und starte den Modbus SmartBridge Service..."
    sudo systemctl daemon-reload
    sudo systemctl enable modbus_smartbridge.service
    sudo systemctl start modbus_smartbridge.service

    # Überprüfen, ob der Dienst erfolgreich gestartet wurde
    if ! systemctl is-active --quiet modbus_smartbridge.service; then
        log_message "Der Dienst konnte nicht gestartet werden. Bitte prüfen Sie die Log-Datei."
        echo "Der Dienst läuft nicht. Führen Sie 'sudo systemctl status modbus_smartbridge.service' zur Fehleranalyse aus."
    else
        log_message "Dienst läuft erfolgreich."
    fi

    log_message "Modbus SmartBridge wurde erfolgreich installiert und gestartet."
    echo "Sie können die Konfiguration jetzt mit dem Befehl 'modbus_smartbridge_config.sh' ändern."
    echo "Zum Neustarten des Dienstes: sudo systemctl restart modbus_smartbridge.service"
}

# Funktion zur Deinstallation
uninstall() {
    log_message "Starte Deinstallation..."

    # Systemd-Service stoppen und deaktivieren
    log_message "Stoppe und deaktiviere den Modbus SmartBridge Service..."
    sudo systemctl stop modbus_smartbridge.service
    sudo systemctl disable modbus_smartbridge.service
    sudo rm -f $SERVICE_FILE
    sudo systemctl daemon-reload

    # Dateien entfernen, abhängig vom Argument --purge
    if [[ "$1" == "--purge" ]]; then
        log_message "Vollständige Deinstallation inklusive Konfigurationsdatei..."
        sudo rm -rf "$INSTALL_DIR"
        sudo rm -f "$CONFIG_SCRIPT"
    else
        log_message "Deinstallation ohne Löschen der Konfigurationsdatei..."
        sudo rm -rf "$INSTALL_DIR"
        # Konfigurationsdatei beibehalten
        sudo mkdir -p "$INSTALL_DIR"
        sudo mv "$CONFIG_FILE" "$INSTALL_DIR/"
    fi

    log_message "Modbus SmartBridge wurde erfolgreich deinstalliert."
}

# Überprüfen auf Root-Berechtigungen
if [ "$EUID" -ne 0 ]; then 
    echo "Bitte führen Sie das Skript mit Root-Rechten aus (sudo)."
    exit 1
fi

# Skriptoptionen analysieren
if [[ "$1" == "--uninstall" ]]; then
    if [[ "$2" == "--purge" ]]; then
        uninstall --purge
    else
        uninstall
    fi
else
    install
fi
