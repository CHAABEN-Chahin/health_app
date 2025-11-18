# Health Mentor Prompt Generator - Usage Guide

## Overview

The `prompts.py` module provides functionality to generate personalized health mentor prompts based on user data stored in Firebase. It handles optional fields gracefully and ensures data consistency.

## Key Components

### 1. `get_user_prompt_data(user_id: str) -> Optional[dict]`

Fetches user data from Firestore and prepares it for prompt generation.

**What it does:**

- Retrieves user basic info from `users` collection
- Retrieves user profile from `users/{userId}/profile/data`
- Merges both data sources into a single dictionary
- Returns combined data or `None` if user not found

**Usage:**

```python
from app.api.v1.prompts import get_user_prompt_data, create_health_mentor_prompt

async def get_mentor_prompt(user_id: str) -> str:
    # Fetch user data from Firebase
    user_data = await get_user_prompt_data(user_id)

    if not user_data:
        raise ValueError(f"User {user_id} not found")

    # Generate personalized prompt
    prompt = create_health_mentor_prompt(user_data)
    return prompt
```

### 2. `create_health_mentor_prompt(user_data: dict) -> str`

Generates a personalized system prompt based on user profile.

**Features:**

- Handles missing/optional fields gracefully
- Normalizes data types (booleans, numbers, strings)
- Calculates BMI from weight and height
- Builds dynamic medical conditions list
- Includes fitness goals and daily targets
- Provides safety guidelines based on medical conditions

**Data Handling:**

- **Optional fields** with `None` or empty values are replaced with defaults
- **Boolean fields** (medical conditions) safely parse various formats (bool, int, string)
- **Numeric fields** (weight, height, targets) default to 0 or sensible defaults if missing

### 3. `_normalize_user_data(user_data: dict) -> dict`

Normalizes incoming user data to ensure consistent structure and types.

**What it normalizes:**

- Ensures all fields are present (even if empty/null)
- Converts boolean fields from various formats
- Applies sensible defaults to required fields
- Preserves optional text fields as-is

### 4. `_parse_bool(value) -> bool`

Safely parses boolean values from various formats.

**Supported formats:**

- Python `bool`: `True` / `False`
- Integers: `1` (True) or `0` (False)
- Strings: `'true'`, `'1'`, `'yes'` (case-insensitive)
- `None`: defaults to `False`

## Field Mapping

### From UserProfile (Flutter/Dart)

| Dart Field               | Firestore Field             | Type    | Default         |
| ------------------------ | --------------------------- | ------- | --------------- |
| `age`                    | `age`                       | int     | 0               |
| `gender`                 | `gender`                    | string  | "Not specified" |
| `weightKg`               | `weight_kg`                 | double  | 0.0             |
| `heightCm`               | `height_cm`                 | double  | 0.0             |
| `activityLevel`          | `activity_level`            | string  | "Moderate"      |
| `hasHypertension`        | `has_hypertension`          | bool    | false           |
| `hasDiabetes`            | `has_diabetes`              | bool    | false           |
| `hasHeartCondition`      | `has_heart_condition`       | bool    | false           |
| `hasAsthma`              | `has_asthma`                | bool    | false           |
| `hasHighCholesterol`     | `has_high_cholesterol`      | bool    | false           |
| `hasThyroidDisorder`     | `has_thyroid_disorder`      | bool    | false           |
| `otherConditions`        | `other_conditions`          | string? | null            |
| `allergies`              | `allergies`                 | string? | null            |
| `medications`            | `medications`               | string? | null            |
| `fitnessGoals`           | `fitness_goals`             | string? | null            |
| `goalType`               | `goal_type`                 | string? | null            |
| `goalIntensity`          | `goal_intensity`            | string? | null            |
| `targetWeightKg`         | `target_weight_kg`          | double? | null            |
| `dailyCalorieGoal`       | `daily_calorie_goal`        | int     | 2000            |
| `dailyStepGoal`          | `daily_step_goal`           | int     | 10000           |
| `dailyDistanceGoal`      | `daily_distance_goal`       | double  | 5.0             |
| `dailyActiveMinutesGoal` | `daily_active_minutes_goal` | int     | 30              |
| `dailyProteinGoal`       | `daily_protein_goal`        | int     | 150             |
| `dailyCarbsGoal`         | `daily_carbs_goal`          | int     | 250             |
| `dailyFatsGoal`          | `daily_fats_goal`           | int     | 70              |

## Example Usage in API Endpoint

```python
from fastapi import APIRouter, HTTPException
from app.api.v1.prompts import get_user_prompt_data, create_health_mentor_prompt

router = APIRouter()

@router.get("/users/{user_id}/mentor-prompt")
async def get_user_mentor_prompt(user_id: str):
    """
    Get the personalized health mentor prompt for a user.
    This is typically called by the chatbot to initialize the mentor's context.
    """
    try:
        user_data = await get_user_prompt_data(user_id)

        if not user_data:
            raise HTTPException(status_code=404, detail="User not found")

        prompt = create_health_mentor_prompt(user_data)

        return {
            "success": True,
            "user_id": user_id,
            "prompt": prompt
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

## Handling Optional Fields

The system is designed to work with incomplete user profiles:

```python
# User with minimal data
minimal_user = {
    'user_id': 'user123',
    'age': 30
    # All other fields missing or None
}

# This will NOT crash - missing fields get defaults
prompt = create_health_mentor_prompt(minimal_user)

# User with comprehensive data
comprehensive_user = {
    'user_id': 'user456',
    'age': 35,
    'weight_kg': 75.5,
    'height_cm': 180.0,
    'has_diabetes': True,
    'medications': 'Metformin 500mg twice daily',
    'allergies': 'Penicillin',
    'fitness_goals': 'Lose weight and improve cardiovascular health',
    # ... more fields
}

# This generates a full prompt with all user details
prompt = create_health_mentor_prompt(comprehensive_user)
```

## Important Notes

1. **Boolean Conversions**: Medical conditions stored as `1`/`0` in some systems are safely converted to boolean
2. **Type Flexibility**: Numeric fields accept int or float and are normalized
3. **Empty String Handling**: Empty strings and None are treated the same (replaced with defaults)
4. **BMI Calculation**: Only calculated if both weight and height are > 0
5. **User ID Truncation**: User ID is truncated to first 8 characters in the prompt for privacy

## Error Handling

```python
try:
    user_data = await get_user_prompt_data(user_id)
    if not user_data:
        # User not found in Firestore
        print("User profile not found")
    else:
        prompt = create_health_mentor_prompt(user_data)
        # Use prompt with AI model
except Exception as e:
    # Handle Firebase connection errors or other exceptions
    print(f"Error fetching user data: {e}")
```

## Testing

```python
# Test with mock data
test_data = {
    'user_id': 'test_user_123',
    'age': 28,
    'gender': 'Male',
    'weight_kg': 80.5,
    'height_cm': 185.0,
    'activity_level': 'Moderate',
    'has_diabetes': True,
    'has_hypertension': False,
    'medications': 'Insulin injections daily',
    'allergies': None,  # This is fine - will show as "none reported"
    'fitness_goals': 'Control blood sugar and lose weight',
    'daily_calorie_goal': 1800,
}

prompt = create_health_mentor_prompt(test_data)
print(prompt)
```

## Related Files

- `app/models/user.py` - User and UserProfile models (matches Firestore structure)
- `app/services/firebase_service.py` - Firebase operations (get_user_by_id, get_user_profile)
- `front_end/lib/models/user.dart` - Flutter UserProfile class (source of truth for fields)
