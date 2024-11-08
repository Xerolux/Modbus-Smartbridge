
# Modbus SmartBridge

Modbus SmartBridge ist ein Proxy, der die Verbindung zu mehreren Modbus-Clients herstellt und Daten von diesen weiterleitet. Dieses Tool ermÃ¶glicht eine zentrale Verwaltung und Verteilung von Modbus-Daten und bietet flexible Konfigurationsoptionen, einschlieÃŸlich dynamischer Registerabfragen, Speicheroptionen und Health-Checks. Es kann als Systemd-Service installiert und fÃ¼r regelmÃ¤ÃŸige Updates konfiguriert werden.

## Features

- Verbindung zu mehreren Modbus-Clients Ã¼ber eine zentrale Instanz.
- UnterstÃ¼tzung fÃ¼r verschiedene Modbus-Registertypen (`holding`, `input`, `coil`, `discrete` oder `all` fÃ¼r alle).
- Konfigurationsdatei mit dynamischer Nachladefunktion.
- Anpassbare Health-Checks und Logging-Funktionen.
- Speicheroptionen fÃ¼r RAM oder RAM-Disk.

## Installation

1. **Projekt klonen**:
   ```bash
   git clone https://github.com/Xerolux/modbus-smartbridge.git
   cd modbus-smartbridge
   ```

2. **Installationsskript ausfÃ¼hren**:
   FÃ¼hren Sie das Installationsskript aus, um die Installation unter `/etc/modbus_smartbridge` durchzufÃ¼hren.
   ```bash
   sudo bash install.sh
   ```

Das Skript Ã¼bernimmt folgende Aufgaben:

- ÃœberprÃ¼fung und Installation von Python 3, `venv` und `whiptail`.
- Erstellung des Installationsverzeichnisses `/etc/modbus_smartbridge`.
- Einrichtung einer virtuellen Umgebung und Installation der AbhÃ¤ngigkeiten.
- Einrichtung eines Systemd-Services zur automatischen AusfÃ¼hrung.
- Erstellung des Konfigurationsskripts `modbus_smartbridge_config.sh`, das global verfÃ¼gbar ist.

3. **Service starten**:
   ```bash
   sudo systemctl start modbus_smartbridge.service
   ```

4. **Service-Status prÃ¼fen**:
   ```bash
   sudo systemctl status modbus_smartbridge.service
   ```

### Konfiguration

Nach der Installation kÃ¶nnen Sie die Konfiguration jederzeit mit dem Befehl:

```bash
modbus_smartbridge_config.sh
```

Ã¼ber ein grafisches, textbasiertes MenÃ¼ anpassen. Alle Ã„nderungen werden direkt in der Datei `config.yaml` unter `/etc/modbus_smartbridge/` gespeichert.

### Aktualisieren des Programms

1. **Projektverzeichnis aufrufen**:
   ```bash
   cd /etc/modbus_smartbridge
   ```

2. **Git-Repository aktualisieren und AbhÃ¤ngigkeiten aktualisieren**:
   ```bash
   git pull origin main
   source venv/bin/activate
   pip install -r requirements.txt --upgrade
   ```

3. **Systemd-Service neu starten**:
   ```bash
   sudo systemctl restart modbus_smartbridge.service
   ```

Durch regelmÃ¤ÃŸiges AusfÃ¼hren dieser Schritte bleibt das Modbus SmartBridge-Programm stets auf dem neuesten Stand.

---

## Konfiguration Ã¼ber `modbus_smartbridge_config.sh`

Das Skript `modbus_smartbridge_config.sh` bietet ein textbasiertes MenÃ¼ zur Bearbeitung der Konfigurationsdatei `config.yaml`. Die Optionen umfassen:

- **Server-Konfiguration**: IP-Adresse und Port des Modbus-Servers.
- **Modbus-Clients**: IP-Adressen, Ports und weitere spezifische Einstellungen fÃ¼r jeden Client.
- **Speicheroptionen**: Konfiguration des Speichertyps (RAM oder RAM-Disk) und des Speicherpfads.
- **Cache-Einstellungen**: Time-to-Live (TTL) des Caches in Sekunden.
- **Logging**: Aktivierung und Festlegung des Logging-Levels.
- **Health-Checks**: Aktivierung und Konfiguration des Intervalls fÃ¼r Health-Checks.

### Beispielkonfigurationsdatei (`config.yaml`)

Eine Beispielkonfigurationsdatei ist im Installationsverzeichnis `/etc/modbus_smartbridge/config.yaml` zu finden:

```yaml
server:
  host: "0.0.0.0"       # Bind-Adresse fÃ¼r den Modbus-Server
  port: 5020            # Modbus-Server-Port

clients:
  - id: 1
    host: "192.168.1.10"
    port: 502
    unit_id: 1
    interval: 5         # Abfrageintervall in Sekunden
    timeout: 3          # Timeout in Sekunden fÃ¼r die Verbindung
    register_type: "all" # Optionen: holding, input, coil, discrete, all
    max_retries: 5       # Maximale Anzahl von Wiederholungen vor einer lÃ¤ngeren Pause

storage:
  type: "ram"               # Optionen: "ram" fÃ¼r RAM-basierter Speicher oder "ramdisk" fÃ¼r RAM-Disk
  path: "/tmp/modbus_data.txt"  # Pfad fÃ¼r RAM-Disk-Speicherung

cache:
  ttl: 60                   # Time-to-Live (TTL) fÃ¼r den Cache in Sekunden

logging:
  enabled: true             # Aktiviert oder deaktiviert Logging
  level: "INFO"             # Logging-Level: DEBUG, INFO, WARNING, ERROR

health_check:
  enabled: true             # Aktiviert regelmÃ¤ÃŸige Health-Checks
  interval: 300             # Intervall in Sekunden fÃ¼r den Health-Check
```

---

Diese Anleitung beschreibt die Installation, Nutzung, Konfiguration und Wartung des Modbus SmartBridge-Programms und erleichtert die Verwaltung und Verteilung von Modbus-Daten Ã¼ber einen zentralen Proxy.
