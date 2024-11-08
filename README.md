
# Modbus SmartBridge

Modbus SmartBridge ist ein Proxy, der die Verbindung zu mehreren Modbus-Clients herstellt und Daten von diesen weiterleitet. Dieses Tool ermÃ¶glicht eine zentrale Verwaltung und Verteilung von Modbus-Daten und bietet flexible Konfigurationsoptionen, einschlieÃŸlich dynamischer Registerabfragen, Speicheroptionen und Health-Checks. Es kann als Systemd-Service installiert und fÃ¼r regelmÃ¤ÃŸige Updates konfiguriert werden.

## Features

- Verbindung zu mehreren Modbus-Clients Ã¼ber eine zentrale Instanz.
- UnterstÃ¼tzung fÃ¼r verschiedene Modbus-Registertypen (`holding`, `input`, `coil`, `discrete` oder `all` fÃür alle).
- Konfigurationsdatei mit dynamischer Nachladefunktion.
- Anpassbare Health-Checks und Logging-Funktionen.
- Speicheroptionen fÃ¼r RAM oder RAM-Disk.
  
## Installation

1. **Voraussetzungen**: Installieren Sie Python 3.x und Git, wenn diese noch nicht installiert sind.

2. **Projekt klonen**:
   ```bash
   git clone https://github.com/Xerolux/modbus-smartbridge.git
   cd modbus-smartbridge
   ```

3. **Abhängigkeiten installieren**:
   Installieren Sie alle notwendigen Pakete mithilfe der `requirements.txt`.
   ```bash
   pip install -r requirements.txt
   ```

4. **Konfigurationsdatei erstellen**:
   Kopieren Sie die `config.yaml`-Beispieldatei und passen Sie sie an Ihre BedÃ¼rfnisse an.
   ```bash
   cp config.yaml.example config.yaml
   ```

## Konfiguration

Die Konfiguration erfolgt in der Datei `config.yaml`. Hier sind die einzelnen Optionen im Detail beschrieben:

### Server-Konfiguration

```yaml
server:
  host: "0.0.0.0"       # Bind-Adresse fÃ¼r den Modbus-Server
  port: 5020            # Modbus-Server-Port
```

- **`host`**: IP-Adresse, an die der Modbus-Server gebunden wird. StandardmÃ¤ÃŸig `0.0.0.0` fÃ¼r alle Schnittstellen.
- **`port`**: Port, auf dem der Modbus-Server lauscht.

### Modbus-Clients

```yaml
clients:
  - id: 1
    host: "192.168.1.10"
    port: 502
    unit_id: 1
    interval: 5
    timeout: 3
    register_type: "all"
    max_retries: 5
```

- **`id`**: Eindeutige ID des Clients.
- **`host`**: IP-Adresse des Modbus-Clients.
- **`port`**: Port, an dem der Client erreichbar ist.
- **`unit_id`**: Modbus Unit ID des Clients.
- **`interval`**: Intervall in Sekunden, wie oft der Client abgefragt wird.
- **`timeout`**: Timeout fÃ¼r Verbindungsversuche in Sekunden.
- **`register_type`**: Der Registertyp, der abgefragt wird â€“ Optionen sind `holding`, `input`, `coil`, `discrete` oder `all`, um alle Registertypen abzufragen.
- **`max_retries`**: Maximale Anzahl der Wiederholungen bei Verbindungsfehlern, bevor eine lÃ¤ngere Pause erfolgt.

### Speicheroptionen

```yaml
storage:
  type: "ram" 
  path: "/tmp/modbus_data.txt"
```

- **`type`**: Speichertyp â€“ `ram` fÃ¼r RAM-basierte Speicherung oder `ramdisk` fÃ¼r RAM-Disk-Speicherung.
- **`path`**: Pfad zur Speicherdatei (nur relevant, wenn `type` auf `ramdisk` gesetzt ist).

### Cache-Einstellungen

```yaml
cache:
  ttl: 60
```

- **`ttl`**: GÃ¼ltigkeitsdauer des Caches in Sekunden.

### Logging-Einstellungen

```yaml
logging:
  enabled: true
  level: "INFO"
```

- **`enabled`**: Aktiviert oder deaktiviert das Logging.
- **`level`**: Setzt das Logging-Level (`DEBUG`, `INFO`, `WARNING`, `ERROR`).

### Health-Check-Einstellungen

```yaml
health_check:
  enabled: true
  interval: 300
```

- **`enabled`**: Aktiviert oder deaktiviert die Health-Checks.
- **`interval`**: Intervall in Sekunden fÃ¼r die Health-Checks.

## Nutzung

Starten Sie das Skript manuell mit dem folgenden Befehl:
```bash
python modbus_smartbridge.py
```

### Als Systemd-Service installieren

1. **Service-Datei erstellen**: Erstellen Sie die Systemd-Service-Datei `/etc/systemd/system/modbus_smartbridge.service` mit folgendem Inhalt:

   ```ini
   [Unit]
   Description=Modbus SmartBridge Service
   After=network.target

   [Service]
   WorkingDirectory=/path/to/modbus-smartbridge
   ExecStart=/usr/bin/python3 /path/to/modbus-smartbridge/modbus_smartbridge.py
   Restart=always
   User=your-username
   Environment=PYTHONUNBUFFERED=1

   [Install]
   WantedBy=multi-user.target
   ```

   Ersetzen Sie `/path/to/modbus-smartbridge` und `your-username` durch den tatsÃ¤chlichen Pfad zum Projekt und den entsprechenden Benutzernamen.

2. **Service neu laden und starten**:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable modbus_smartbridge.service
   sudo systemctl start modbus_smartbridge.service
   ```

3. **Service-Status prÃ¼fen**:
   ```bash
   sudo systemctl status modbus_smartbridge.service
   ```

### Aktualisieren des Programms

1. **Git-Repository aktualisieren**:
   ```bash
   cd /path/to/modbus-smartbridge
   git pull origin main
   ```

2. **AbhÃ¤ngigkeiten aktualisieren** (falls erforderlich):
   ```bash
   pip install -r requirements.txt --upgrade
   ```

3. **Systemd-Service neu starten**:
   ```bash
   sudo systemctl restart modbus_smartbridge.service
   ```

Durch regelmÃ¤ÃŸiges AusfÃ¼hren dieser Schritte bleibt das Modbus SmartBridge-Programm stets auf dem neuesten Stand.

--- 

Diese Anleitung beschreibt die Installation, Nutzung, Konfiguration und Wartung des Modbus SmartBridge-Programms und erleichtert die Verwaltung und Verteilung von Modbus-Daten Ã¼ber einen zentralen Proxy.
