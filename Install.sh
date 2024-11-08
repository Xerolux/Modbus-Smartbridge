#!/bin/bash

# Variablen für Verzeichnisse
INSTALL_DIR="/etc/modbus_smartbridge"
SERVICE_FILE="/etc/systemd/system/modbus_smartbridge.service"
CONFIG_SCRIPT="/usr/local/bin/modbus_smartbridge_config.sh"

echo "Starte Installation von Modbus SmartBridge..."

# Überprüfen, ob das Betriebssystem Debian/Ubuntu ist
if ! grep -Ei 'debian|ubuntu' /etc/os-release > /dev/null; then
    echo "Dieses Installationsskript unterstützt nur Debian- und Ubuntu-basierte Systeme."
    echo "Bitte installieren Sie Python 3 und python3-venv manuell und führen Sie die Installation erneut durch."
    exit 1
fi

# 1. Überprüfen und Installieren von Python3, venv und whiptail, falls nicht vorhanden
if ! command -v python3 &> /dev/null; then
    echo "Python3 wird installiert..."
    sudo apt update
    sudo apt install -y python3
fi

if ! python3 -m venv --help &> /dev/null; then
    echo "Python3 venv wird installiert..."
    sudo apt install -y python3-venv
fi

if ! command -v whiptail &> /dev/null; then
    echo "Whiptail wird installiert..."
    sudo apt install -y whiptail
fi

# 2. Erstellen des Installationsverzeichnisses
echo "Erstelle Verzeichnis $INSTALL_DIR..."
sudo mkdir -p $INSTALL_DIR

# 3. Dateien kopieren
echo "Kopiere Dateien..."
sudo cp -r . $INSTALL_DIR

# 4. Virtuelle Umgebung erstellen und Abhängigkeiten installieren
echo "Erstelle virtuelle Umgebung und installiere Abhängigkeiten..."
cd $INSTALL_DIR
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 5. Beispiel-Konfigurationsdatei kopieren
if [ ! -f "$INSTALL_DIR/config.yaml" ]; then
  echo "Erstelle Beispiel-Konfigurationsdatei..."
  sudo cp config.yaml.example config.yaml
fi

# 6. Systemd-Service-Datei erstellen
echo "Erstelle Systemd-Service..."
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

# 7. Konfigurationsskript global verfügbar machen
echo "Erstelle globales Konfigurationsskript..."
sudo cp $INSTALL_DIR/modbus_smartbridge_config.sh $CONFIG_SCRIPT
sudo chmod +x $CONFIG_SCRIPT

# 8. Service starten und aktivieren
echo "Aktiviere und starte den Modbus SmartBridge Service..."
sudo systemctl daemon-reload
sudo systemctl enable modbus_smartbridge.service
sudo systemctl start modbus_smartbridge.service

echo "Modbus SmartBridge wurde erfolgreich installiert und gestartet."
echo "Sie können die Konfiguration jetzt mit dem Befehl 'modbus_smartbridge_config.sh' ändern."
echo "Zum Neustarten des Dienstes: sudo systemctl restart modbus_smartbridge.service"
