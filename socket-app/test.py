import asyncio
import websockets
import datetime
from dotenv import load_dotenv
import os

load_dotenv()

MASTER1_FLOATING_IP = os.getenv("MASTER1_FLOATING_IP")

async def test_connection():
    uri = f"ws://{MASTER1_FLOATING_IP}:31918/ws"

    async with websockets.connect(uri) as ws:
        print(f"[{datetime.datetime.now()}] Connected")

        for i in range(20):
            await ws.send(f"ping {i}")
            response = await ws.recv()
            print(f"[{datetime.datetime.now()}] {response}")
            await asyncio.sleep(30)

        print(f"[{datetime.datetime.now()}] Test completed - connection alive for 10+ minutes")

asyncio.run(test_connection())
