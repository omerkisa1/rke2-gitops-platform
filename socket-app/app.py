from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import asyncio
import datetime

app = FastAPI()

connected_clients = []

@app.get("/health")
def health():
    return {"status": "ok", "clients": len(connected_clients)}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    connected_clients.append(websocket)
    client_id = id(websocket)
    print(f"[{datetime.datetime.now()}] Client {client_id} connected. Total: {len(connected_clients)}")

    try:
        while True:
            data = await websocket.receive_text()
            timestamp = datetime.datetime.now().isoformat()

            response = f"[{timestamp}] Server received: {data}"
            await websocket.send_text(response)
            print(f"[{timestamp}] Client {client_id}: {data}")

    except WebSocketDisconnect:
        connected_clients.remove(websocket)
        print(f"[{datetime.datetime.now()}] Client {client_id} disconnected. Total: {len(connected_clients)}")
