from fastapi import FastAPI,File,UploadFile,APIRouter
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware  # Add this
from ollama_service import analyse_image
import base64
import json
from pathlib import Path

upload_dir=Path("uploads")
upload_dir.mkdir(exist_ok=True)

router = APIRouter()

@router.post("/get_calories")
async def get_calories(file: UploadFile = File(...)):
    try:
        image_data= await file.read()
        file_path = upload_dir / file.filename
        with open(file_path, "wb") as f:
            f.write(image_data)
        image_base64 = base64.b64encode(image_data).decode('utf-8')
        result = analyse_image(file_path)
        print("Raw result:", result)
        print("Result type:", type(result))
        
        try:
            result_json = json.loads(result)
            return JSONResponse(content=result_json)
        except json.JSONDecodeError as je:
            print(f"JSON decode error: {je}")
            return JSONResponse(content={"raw_result": result, "error": "Invalid JSON response from LLM"})
    except Exception as e:
        print(e)
        return JSONResponse(content={"error": str(e)}, status_code=500)