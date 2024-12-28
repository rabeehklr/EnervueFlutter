from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import random
from datetime import datetime, timedelta
import json
from typing import Dict, List, Optional
from contextlib import asynccontextmanager
import socket
import uvicorn
import logging
from pydantic import BaseModel

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ApplianceData(BaseModel):
    id: str
    name: str
    state: bool
    status: str
    current_power: float
    time_used: int
    last_state_change: str
    image_name: str
    anomaly: bool
    weekly_usage: List[float]
    cost_per_hour: float

class SummaryData(BaseModel):
    total_consumption: float
    total_cost_per_hour: float
    active_appliances: int
    anomalies_detected: int

class WebSocketMessage(BaseModel):
    timestamp: str
    appliances: List[ApplianceData]
    summary: SummaryData

class Appliance:
    def __init__(self, id: str, name: str, max_power: float, image_name: str):
        self.id = id
        self.name = name
        self.state = False
        self.max_power = max_power
        self.current_power = 0
        self.time_used = 0
        self.last_state_change = datetime.now()
        self.image_name = image_name
        self.anomaly = False
        self.weekly_usage = self._generate_weekly_usage()
        self.state_change_probability = 0.1
        self.anomaly_probability = 0.05
        self.last_anomaly = None
        self.min_state_duration = timedelta(minutes=5)

    def _generate_weekly_usage(self) -> List[float]:
        base_load = self.max_power * 0.6  # Base load is 60% of max power
        variation = self.max_power * 0.4   # Allow 40% variation
        return [round(base_load + random.uniform(-variation, variation), 2) for _ in range(7)]

    def generate_data(self) -> Dict:
        current_time = datetime.now()
        time_since_last_change = current_time - self.last_state_change

        # Only allow state changes after minimum duration
        if time_since_last_change >= self.min_state_duration:
            if random.random() < self.state_change_probability:
                self.state = not self.state
                self.last_state_change = current_time
                logger.info(f"Appliance {self.name} state changed to: {'ON' if self.state else 'OFF'}")

        # Anomaly detection logic
        if self.state:
            if self.last_anomaly is None or (current_time - self.last_anomaly) > timedelta(minutes=30):
                if random.random() < self.anomaly_probability:
                    self.anomaly = True
                    self.current_power = round(self.max_power * random.uniform(1.2, 1.5), 2)
                    self.last_anomaly = current_time
                    logger.warning(f"Anomaly detected in {self.name}: Power surge to {self.current_power}W")
                else:
                    self.anomaly = False
                    self.current_power = round(self.max_power * random.uniform(0.5, 1.0), 2)
            elif current_time - self.last_anomaly > timedelta(minutes=5):
                self.anomaly = False
        else:
            self.anomaly = False
            self.current_power = 0

        if self.state:
            self.time_used += 1

        return {
            "id": self.id,
            "name": self.name,
            "state": self.state,
            "status": "on" if self.state else "off",
            "current_power": self.current_power,
            "time_used": self.time_used,
            "last_state_change": self.last_state_change.isoformat(),
            "image_name": self.image_name,
            "anomaly": self.anomaly,
            "weekly_usage": self.weekly_usage,
            "cost_per_hour": round(self.current_power * 0.12 / 1000, 2)  # $0.12 per kWh
        }

def find_available_port(start_port: int = 8000, max_port: int = 8100) -> int:
    for port in range(start_port, max_port):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('0.0.0.0', port))
                return port
        except OSError:
            continue
    raise RuntimeError(f"Could not find an available port between {start_port} and {max_port}")

class WebSocketManager:
    def __init__(self):
        self.connected_clients: List[WebSocket] = []
        self.broadcast_task: Optional[asyncio.Task] = None

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.connected_clients.append(websocket)
        logger.info(f"New client connected. Total clients: {len(self.connected_clients)}")

    async def disconnect(self, websocket: WebSocket):
        if websocket in self.connected_clients:
            self.connected_clients.remove(websocket)
            logger.info(f"Client disconnected. Remaining clients: {len(self.connected_clients)}")

    async def broadcast(self, message: dict):
        disconnected_clients = []
        for client in self.connected_clients:
            try:
                await client.send_json(message)
            except Exception as e:
                logger.error(f"Error broadcasting to client: {str(e)}")
                disconnected_clients.append(client)

        # Clean up disconnected clients
        for client in disconnected_clients:
            await self.disconnect(client)

ws_manager = WebSocketManager()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Create the broadcast task
    ws_manager.broadcast_task = asyncio.create_task(broadcast_appliance_data())
    logger.info("Server started. Broadcasting task initialized.")
    yield
    # Shutdown: Cancel the broadcast task
    if ws_manager.broadcast_task:
        ws_manager.broadcast_task.cancel()
        try:
            await ws_manager.broadcast_task
        except asyncio.CancelledError:
            logger.info("Broadcasting task cancelled.")

app = FastAPI(lifespan=lifespan)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create sample appliances with realistic power ratings
appliances = [
    Appliance("1", "Fan", 75, "fan.png"),
    Appliance("2", "Air Conditioner", 1500, "AC.png"),
    Appliance("3", "Washing Machine", 500, "washingmachine.png"),
    Appliance("4", "Television", 100, "TV.png"),
    Appliance("5", "Microwave", 1200, "microwave.png"),
    Appliance("6", "Refrigerator", 150, "refrigerator.png"),
    Appliance("7", "Laptop Charger", 65, "laptop.png"),
    Appliance("8", "Bulb", 60, "bulb.png"),
]

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await ws_manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text()
    except Exception as e:
        logger.error(f"WebSocket error: {str(e)}")
        await ws_manager.disconnect(websocket)

async def broadcast_appliance_data():
    while True:
        if ws_manager.connected_clients:
            try:
                # Generate new data for all appliances
                data = [appliance.generate_data() for appliance in appliances]

                # Calculate totals
                total_consumption = sum(appliance["current_power"] for appliance in data)
                total_cost = sum(appliance["cost_per_hour"] for appliance in data)
                active_appliances = sum(1 for appliance in data if appliance["state"])
                anomalies = sum(1 for appliance in data if appliance["anomaly"])

                message = {
                    "timestamp": datetime.now().isoformat(),
                    "appliances": data,
                    "summary": {
                        "total_consumption": round(total_consumption, 2),
                        "total_cost_per_hour": round(total_cost, 2),
                        "active_appliances": active_appliances,
                        "anomalies_detected": anomalies
                    }
                }

                await ws_manager.broadcast(message)
            except Exception as e:
                logger.error(f"Error in broadcast loop: {str(e)}")

        await asyncio.sleep(1)

if __name__ == "__main__":
    port = find_available_port()
    logger.info(f"Starting server on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port)