#!/usr/bin/env python3
import asyncio
import json
import sys
from redis.asyncio import Redis

async def test_websocket():
    # Get a valid session from Redis
    redis = Redis.from_url("redis://localhost:6379/0", decode_responses=True)

    sessions = await redis.keys("session:*")
    if not sessions:
        print("❌ No sessions found in Redis. Please login first.")
        await redis.close()
        return False

    session_id = sessions[0].replace("session:", "")
    user_id = await redis.get(f"session:{session_id}")
    print(f"✓ Found valid session: {session_id} for user {user_id}")

    # Test WebSocket connection
    try:
        import websockets
    except ImportError:
        print("❌ websockets library not found. Install with: pip install websockets")
        await redis.close()
        return False

    try:
        async with websockets.connect(f"ws://localhost:8000/ws?session={session_id}") as websocket:
            print(f"✓ WebSocket connected successfully")

            # Send a test message
            await asyncio.sleep(0.5)

            # Try to receive
            try:
                msg = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                print(f"✓ Received: {msg}")
            except asyncio.TimeoutError:
                print(f"✓ No messages received (this is normal)")

            await websocket.close()
            print("✓ WebSocket closed successfully")
            await redis.close()
            return True
    except Exception as e:
        print(f"❌ WebSocket connection failed: {type(e).__name__}: {e}")
        await redis.close()
        return False

if __name__ == "__main__":
    result = asyncio.run(test_websocket())
    sys.exit(0 if result else 1)
