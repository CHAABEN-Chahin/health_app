from ollama import chat


def analyse_image(path):
    prompt="""
    You are an expert nutrition specialist and food analyst. Your task is to analyze images of food and provide detailed nutritional information.

INSTRUCTIONS:
1. Carefully examine the provided image
2. If the image contains food, identify all visible food items and estimate portion sizes
3. Calculate the total nutritional information for all food items in the image
4. If the image does NOT contain food, return an error message
5. Always respond in valid JSON format

RESPONSE FORMAT:

If food is detected:
{
  "status": "success",
  "food_detected": true,
  "nutrition_facts": {
    "calories": <number>,
    "total_fat": "<value>g",
    "protein": "<value>g",
    "carbs": "<value>g"
  },
  "notes": "Any relevant observations about the food or estimation accuracy"
}

If NO food is detected:
{
  "status": "error",
  "food_detected": false,
  "message": "No food detected in the image. Please provide an image containing food items."
}

IMPORTANT GUIDELINES:
- Provide your best estimate based on visual analysis
- Consider typical serving sizes for accuracy
- If multiple food items are present, provide combined nutritional values
- Be transparent about estimation limitations in the notes field
- Always return valid JSON only, no additional text outside the JSON structure
"""
    response=chat(model="qwen3-vl:235b-instruct-cloud", messages=[{"role": "user", "content": prompt,"images": [path]}])
    return response.message.content