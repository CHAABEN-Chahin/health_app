from typing import Optional
from app.services.firebase_service import FirebaseService


async def get_user_prompt_data(user_id: str) -> Optional[dict]:
    """
    Fetch user data from Firebase and prepare it for the health mentor prompt.
    
    This function:
    1. Retrieves the user's basic info from the 'users' collection
    2. Retrieves the user's profile data from 'users/{userId}/profile/data'
    3. Merges both data sources
    4. Returns the combined data ready for prompt generation
    
    Args:
        user_id: The user's document ID in Firestore
    
    Returns:
        A dictionary with combined user and profile data, or None if user not found
    
    Example:
        user_data = await get_user_prompt_data("user123")
        if user_data:
            prompt = create_health_mentor_prompt(user_data)
    """
    firebase_service = FirebaseService()
    
    # Fetch user basic information
    user = await firebase_service.get_user_by_id(user_id)
    if not user:
        return None
    
    # Fetch user profile information
    profile = await firebase_service.get_user_profile(user_id)
    
    # Merge user and profile data
    combined_data = {**user}
    if profile:
        combined_data.update(profile)
    
    return combined_data


def _normalize_user_data(user_data: dict) -> dict:
    """
    Normalize user data to ensure consistent handling of optional fields and type conversions.
    Handles conversion from Firestore format (has_field_name) to consistent format.
    """
    normalized = {}
    
    # Required fields with defaults
    normalized['user_id'] = user_data.get('user_id', 'Unknown')
    normalized['age'] = user_data.get('age') or 0
    normalized['gender'] = user_data.get('gender') or 'Not specified'
    normalized['weight_kg'] = user_data.get('weight_kg') or 0.0
    normalized['height_cm'] = user_data.get('height_cm') or 0.0
    normalized['activity_level'] = user_data.get('activity_level') or 'Moderate'
    
    # Medical conditions (boolean fields)
    normalized['has_hypertension'] = _parse_bool(user_data.get('has_hypertension'))
    normalized['has_diabetes'] = _parse_bool(user_data.get('has_diabetes'))
    normalized['has_heart_condition'] = _parse_bool(user_data.get('has_heart_condition'))
    normalized['has_asthma'] = _parse_bool(user_data.get('has_asthma'))
    normalized['has_high_cholesterol'] = _parse_bool(user_data.get('has_high_cholesterol'))
    normalized['has_thyroid_disorder'] = _parse_bool(user_data.get('has_thyroid_disorder'))
    normalized['other_conditions'] = user_data.get('other_conditions')
    
    # Optional text fields
    normalized['allergies'] = user_data.get('allergies')
    normalized['medications'] = user_data.get('medications')
    normalized['medical_conditions'] = user_data.get('medical_conditions')
    
    # Fitness goals
    normalized['goal_type'] = user_data.get('goal_type')
    normalized['goal_intensity'] = user_data.get('goal_intensity')
    normalized['target_weight_kg'] = user_data.get('target_weight_kg')
    normalized['fitness_goals'] = user_data.get('fitness_goals')
    
    # Daily targets with defaults
    normalized['daily_calorie_goal'] = user_data.get('daily_calorie_goal') or 2000
    normalized['daily_step_goal'] = user_data.get('daily_step_goal') or 10000
    normalized['daily_distance_goal'] = user_data.get('daily_distance_goal') or 5.0
    normalized['daily_active_minutes_goal'] = user_data.get('daily_active_minutes_goal') or 30
    normalized['daily_protein_goal'] = user_data.get('daily_protein_goal') or 150
    normalized['daily_carbs_goal'] = user_data.get('daily_carbs_goal') or 250
    normalized['daily_fats_goal'] = user_data.get('daily_fats_goal') or 70
    
    return normalized


def _parse_bool(value) -> bool:
    """
    Parse various boolean representations safely.
    Handles: bool, int (0/1), str ('true'/'false'/'1'/'0'), None
    """
    if value is None:
        return False
    if isinstance(value, bool):
        return value
    if isinstance(value, int):
        return value == 1
    if isinstance(value, str):
        return value.lower() in ('true', '1', 'yes')
    return False


def create_health_mentor_prompt(user_data: dict) -> str:
    """
    Create a personalized system prompt based on user's health profile.
    Handles optional fields gracefully by checking for None/empty values.
    """
    # Normalize and validate user data
    user_data = _normalize_user_data(user_data)
    
    # Calculate BMI safely
    weight = user_data['weight_kg']
    height = user_data['height_cm']
    bmi = weight / ((height / 100) ** 2) if weight > 0 and height > 0 else 0
    
    # Build medical conditions list from boolean flags and other_conditions
    conditions = []
    if user_data['has_hypertension']:
        conditions.append("hypertension")
    if user_data['has_diabetes']:
        conditions.append("diabetes")
    if user_data['has_heart_condition']:
        conditions.append("heart condition")
    if user_data['has_asthma']:
        conditions.append("asthma")
    if user_data['has_high_cholesterol']:
        conditions.append("high cholesterol")
    if user_data['has_thyroid_disorder']:
        conditions.append("thyroid disorder")
    if user_data['other_conditions']:
        conditions.append(user_data['other_conditions'])
    
    conditions_str = ", ".join(conditions) if conditions else "none reported"
    
    # Build optional field sections with safe defaults
    allergies_str = user_data['allergies'] or 'none reported'
    medications_str = user_data['medications'] or 'none reported'
    goal_type_str = user_data['goal_type'] or 'general wellness'
    goal_intensity_str = user_data['goal_intensity'] or 'moderate'
    target_weight_str = f"{user_data['target_weight_kg']:.1f}" if user_data['target_weight_kg'] else 'not set'
    fitness_goals_str = user_data['fitness_goals'] or 'not specified'
    
    prompt = f"""You are Alex, an expert health mentor and wellness coach with deep knowledge in nutrition, exercise science, and lifestyle medicine.

# USER PROFILE
- Name: User #{user_data['user_id'][:8]}
- Age: {user_data['age']} years old
- Gender: {user_data['gender']}
- Weight: {weight:.1f} kg
- Height: {height:.1f} cm
- BMI: {bmi:.1f}
- Activity Level: {user_data['activity_level']}

# MEDICAL CONDITIONS
{conditions_str}

# ALLERGIES & MEDICATIONS
- Allergies: {allergies_str}
- Current Medications: {medications_str}

# FITNESS GOALS
- Goal Type: {goal_type_str}
- Goal Intensity: {goal_intensity_str}
- Target Weight: {target_weight_str} kg
- Fitness Goals: {fitness_goals_str}

# DAILY TARGETS
- Calories: {user_data['daily_calorie_goal']} kcal
- Steps: {user_data['daily_step_goal']} steps
- Distance: {user_data['daily_distance_goal']} km
- Active Minutes: {user_data['daily_active_minutes_goal']} minutes
- Macros: Protein {user_data['daily_protein_goal']}g | Carbs {user_data['daily_carbs_goal']}g | Fats {user_data['daily_fats_goal']}g

# YOUR ROLE & EXPERTISE
You are a certified health coach specializing in:
1. **Personalized Nutrition**: Provide meal plans, macro guidance, and dietary advice tailored to the user's goals and medical conditions
2. **Exercise Programming**: Design safe, effective workout routines considering their fitness level and health constraints
3. **Lifestyle Optimization**: Offer guidance on sleep, stress management, and daily habits
4. **Medical Awareness**: Always consider their medical conditions when giving advice. NEVER contradict medical advice or suggest stopping medications.

# CRITICAL SAFETY GUIDELINES
- ALWAYS account for their medical conditions in your recommendations
- If they have hypertension: recommend low-sodium foods, avoid intense exercises without clearance
- If they have diabetes: focus on blood sugar management, emphasize complex carbs and fiber
- If they have heart conditions: prioritize heart-healthy foods, recommend consulting doctor before intense exercise
- If they have high cholesterol: suggest foods that lower LDL, emphasize omega-3s
- NEVER diagnose conditions or suggest stopping prescribed medications
- For serious symptoms or concerns, ALWAYS recommend consulting their healthcare provider
- Be especially cautious with supplements if they're on medications

# COMMUNICATION STYLE
- Be supportive, motivating, and empathetic
- Use evidence-based recommendations
- Explain the "why" behind your advice
- Celebrate progress and encourage consistency
- Be realistic and sustainable in your suggestions
- Speak in clear, accessible language (avoid excessive medical jargon)
- When discussing food, provide specific examples and alternatives

# RESPONSE FORMAT
- Keep answers concise but informative
- Use bullet points for lists (meal suggestions, exercise routines)
- Provide actionable advice they can implement today
- When relevant, reference their specific goals and conditions

Remember: You're their partner in health, not their doctor. Empower them with knowledge while respecting medical boundaries."""

    return prompt