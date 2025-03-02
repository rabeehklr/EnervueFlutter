from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import random
from datetime import datetime
import json
from typing import Dict, List
from contextlib import asynccontextmanager
import socket
import uvicorn
import logging

from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import random
from datetime import datetime
import json
from typing import Dict, List
from contextlib import asynccontextmanager
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Store connected clients
connected_clients: List[WebSocket] = []

# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    broadcast_task = asyncio.create_task(broadcast_appliance_data())
    yield
    broadcast_task.cancel()
    try:
        await broadcast_task
    except asyncio.CancelledError:
        pass

app = FastAPI(lifespan=lifespan)

# Enable CORS - Allow connections from anywhere
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Appliance:
    def _init_(self, id: str, name: str, max_power: float, image_name: str):
        self.id = id
        self.name = name
        self.state = False  # off by default
        self.max_power = max_power
        self.current_power = 0
        self.time_used = 0  # in minutes
        self.last_state_change = datetime.now()
        self.image_name = image_name
        self.anomaly = False
        self.weekly_usage = self._generate_weekly_usage()
        self.anomalies_today = 0
        self.cycles = 0
        self.status = "off"

    def _generate_weekly_usage(self) -> List[float]:
        return [round(random.uniform(0.5, 1.0) * self.max_power * 24, 2) for _ in range(7)]

    def generate_data(self) -> Dict:
        # State change logic (10% chance)
        if random.random() < 0.1:
            self.state = not self.state
            self.last_state_change = datetime.now()
            self.status = "on" if self.state else "off"
            self.cycles += 1

        # Anomaly and power consumption logic
        if self.state:
            if random.random() < 0.05:  # 5% chance for anomaly
                self.anomaly = True
                self.current_power = round(self.max_power * random.uniform(1.2, 1.5), 2)
                self.anomalies_today = min(self.anomalies_today + 1, 5)  # Cap at 5 anomalies
            else:
                self.anomaly = False
                self.current_power = round(self.max_power * random.uniform(0.5, 1.0), 2)

            self.time_used += 1
        else:
            self.anomaly = False
            self.current_power = 0

        # Weekly usage data with daily labels
        weekly_usage_with_days = [
            {'day': day, 'usage': usage}
            for day, usage in zip(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                                  self.weekly_usage)
        ]

        # Weekly anomalies data (mock data for visualization)
        weekly_anomalies = [
            {'day': day, 'count': random.randint(0, 3)}
            for day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        ]

        return {
            "id": self.id,
            "name": self.name,
            "state": self.state,
            "status": self.status,
            "current_power": self.current_power,
            "time_used": self.time_used,
            "last_state_change": self.last_state_change.isoformat(),
            "image_name": self.image_name,
            "anomaly": self.anomaly,
            "weekly_usage": self.weekly_usage,
            "cost_per_hour": round(self.current_power * 0.12 / 1000, 2),  # $0.12 per Wh
            "peak_power": round(self.max_power * 1.2, 2),
            "cycles": self.cycles,
            "anomalies_today": self.anomalies_today,
            "weekly_anomalies": weekly_anomalies,
            "weekly_usage_with_days": weekly_usage_with_days
        }

# Create sample appliances
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
    await websocket.accept()
    connected_clients.append(websocket)
    try:
        while True:
            await websocket.receive_text()
    except Exception as e:
        logger.error(f"WebSocket error: {str(e)}")
        connected_clients.remove(websocket)

async def broadcast_appliance_data():
    while True:
        if connected_clients:
            try:
                # Generate new data for all appliances
                data = [appliance.generate_data() for appliance in appliances]

                # Calculate totals
                total_consumption = sum(appliance["current_power"] for appliance in data)
                total_cost = sum(appliance["cost_per_hour"] for appliance in data)
                active_appliances = sum(1 for appliance in data if appliance["state"])

                message = {
                    "timestamp": datetime.now().isoformat(),
                    "appliances": data,
                    "summary": {
                        "total_consumption": round(total_consumption, 2),
                        "total_cost_per_hour": round(total_cost, 2),
                        "active_appliances": active_appliances,
                        "anomalies_detected": sum(1 for appliance in data if appliance["anomaly"])
                    }
                }

                # Broadcast to all connected clients
                for client in connected_clients[:]:
                    try:
                        await client.send_json(message)
                    except Exception as e:
                        logger.error(f"Error broadcasting to client: {str(e)}")
                        connected_clients.remove(client)

            except Exception as e:
                logger.error(f"Error in broadcast loop: {str(e)}")

        await asyncio.sleep(1)

if __name__ == "__main__":
    # Remove the hardcoded IP and use 0.0.0.0 to listen on all interfaces
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)