from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/")
async def read_root():
    return {"Hello": "World"}

@app.get("add/{a}/{b}")
async def add(a: int, b: int) -> int:
    return a + b

@app.get("mult/{a}/{b}")
async def mult(a: int, b: int) -> int:
    return a * b

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8080, log_level="info")
