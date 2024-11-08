import asyncio
import logging
from pymodbus.client import AsyncModbusTcpClient
from pymodbus.server.async_io import StartAsyncTcpServer
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext
from pymodbus.device import ModbusDeviceIdentification
import yaml
import os
from cachetools import TTLCache
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Konfiguration laden
def load_config():
    global config, client_backoff
    with open("config.yaml", "r") as f:
        config = yaml.safe_load(f)

    client_backoff = {client['id']: 0 for client in config['clients']}

    # Logging konfigurieren
    if config["logging"].get("enabled", False):
        log_level = config["logging"].get("level", "INFO").upper()
        logging.basicConfig(level=getattr(logging, log_level), filename='/tmp/modbus_proxy.log')
        global logger
        logger = logging.getLogger(__name__)
    else:
        logger = None

    # Cache und Speicher initialisieren
    global data_cache, store, context
    data_cache = TTLCache(maxsize=100, ttl=config["cache"]["ttl"])

    if config["storage"]["type"] == "ram":
        store = ModbusSlaveContext(di=None, co=None, hr=None, ir=None)
    elif config["storage"]["type"] == "ramdisk":
        path = config["storage"]["path"]
        if not os.path.exists(path):
            with open(path, "w") as f:
                f.write("")

        def save_to_ramdisk(data):
            with open(path, "w") as f:
                f.write(str(data))
            if logger:
                logger.info(f"Speichere Daten auf RAM-Disk: {data}")

        def set_values_ramdisk(context, register_type, address, values):
            context.setValues(register_type, address, values)
            save_to_ramdisk(values)

        store = ModbusSlaveContext(di=None, co=None, hr=None, ir=None)
        store.setValues = lambda f, a, v: set_values_ramdisk(store, a, v)

    context = ModbusServerContext(slaves=store, single=True)

load_config()

# Watchdog für dynamisches Nachladen der Konfiguration
class ConfigHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if event.src_path.endswith("config.yaml"):
            load_config()
            if logger:
                logger.info("Konfiguration neu geladen")

observer = Observer()
observer.schedule(ConfigHandler(), path=".", recursive=False)
observer.start()

# Funktion: Daten von einem Client abrufen mit individuellem Backoff
async def poll_client(client_config):
    client_id = client_config['id']
    while True:
        try:
            client = AsyncModbusTcpClient(client_config["host"], port=client_config["port"], timeout=client_config.get("timeout", 3))
            await client.connect()

            while client.connected:
                # Registertyp auswählen oder alle Registertypen abfragen
                if client_config["register_type"] == "all":
                    # Abfrage aller Registertypen
                    responses = {}
                    responses["holding"] = await client.read_holding_registers(0, 10, unit=client_config["unit_id"])
                    responses["input"] = await client.read_input_registers(0, 10, unit=client_config["unit_id"])
                    responses["coil"] = await client.read_coils(0, 10, unit=client_config["unit_id"])
                    responses["discrete"] = await client.read_discrete_inputs(0, 10, unit=client_config["unit_id"])
                    
                    # Speichern der Daten, wenn erfolgreich
                    for reg_type, response in responses.items():
                        if not response.isError():
                            store.setValues(3 if reg_type == "holding" else 4, 0, response.bits if reg_type in ["coil", "discrete"] else response.registers)
                            if logger:
                                logger.info(f"Client {client_id} - {reg_type.capitalize()} Register aktualisiert: {response.registers if reg_type in ['holding', 'input'] else response.bits}")
                else:
                    # Einzeln spezifizierter Registertyp
                    if client_config["register_type"] == "holding":
                        response = await client.read_holding_registers(0, 10, unit=client_config["unit_id"])
                    elif client_config["register_type"] == "input":
                        response = await client.read_input_registers(0, 10, unit=client_config["unit_id"])
                    elif client_config["register_type"] == "coil":
                        response = await client.read_coils(0, 10, unit=client_config["unit_id"])
                    elif client_config["register_type"] == "discrete":
                        response = await client.read_discrete_inputs(0, 10, unit=client_config["unit_id"])

                    # Speichern der Daten
                    if not response.isError():
                        store.setValues(3, 0, response.registers if client_config["register_type"] in ["holding", "input"] else response.bits)
                        if logger:
                            logger.info(f"Client {client_id} - {client_config['register_type'].capitalize()} Register aktualisiert: {response.registers if client_config['register_type'] in ['holding', 'input'] else response.bits}")
                
                client_backoff[client_id] = 0  # Reset bei erfolgreicher Verbindung
                await asyncio.sleep(client_config["interval"])
        except Exception as e:
            if logger:
                logger.error(f"Verbindungsfehler bei Client {client_id}: {e}")
            client_backoff[client_id] += 1
            if client_backoff[client_id] >= client_config.get("max_retries", 5):
                if logger:
                    logger.warning(f"Client {client_id} erreicht max. Wiederholungen. Warten vor neuem Versuch.")
                await asyncio.sleep(300)
                client_backoff[client_id] = 0
            else:
                backoff = min(client_backoff[client_id] * 5, 60)
                await asyncio.sleep(backoff)

# Health-Check-Funktion
async def health_check():
    while True:
        for client_id in client_backoff:
            if client_backoff[client_id] > 0 and logger:
                logger.info(f"Health-Check: Client {client_id} hat {client_backoff[client_id]} Verbindungsfehler.")
        await asyncio.sleep(config["health_check"]["interval"])

# Modbus-Server starten
async def run_server():
    identity = ModbusDeviceIdentification()
    identity.VendorName = "Custom Modbus Proxy"
    identity.ProductCode = "PM"
    identity.VendorUrl = "https://example.com"
    identity.ProductName = "Modbus Proxy Server"
    identity.ModelName = "Modbus Proxy"
    identity.MajorMinorRevision = "1.0"

    await StartAsyncTcpServer(
        context, address=(config["server"]["host"], config["server"]["port"]), identity=identity
    )

# Hauptfunktion
async def main():
    tasks = [poll_client(client_config) for client_config in config["clients"]]
    if config.get("health_check", {}).get("enabled", False):
        tasks.append(health_check())
    await asyncio.gather(run_server(), *tasks)

# Proxy starten
asyncio.run(main())
