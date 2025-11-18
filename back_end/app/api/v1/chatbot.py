from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware 
from pydantic import BaseModel
from typing import List, Optional, Dict
import uuid
import json
from langchain_community.llms import Ollama
from langchain_community.chat_message_histories import ChatMessageHistory
from langchain_core.messages import HumanMessage, AIMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.output_parsers import StrOutputParser
from prompts import create_health_mentor_prompt
app = FastAPI(title="Chatbot API with LangChain + Ollama")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# ============================================
# CONFIGURE YOUR PROMPT HERE
# ============================================
SYSTEM_PROMPT = """You are a helpful AI assistant.
your name is Alex and you only talk in english."""

MODEL_NAME = "kimi-k2:1t-cloud"  # Change to your model
# ============================================

# Store conversations in memory (use database in production)
conversations: Dict[str, ChatMessageHistory] = {}

# Initialize Ollama LLM
llm = Ollama(
    model=MODEL_NAME,
)


class ChatRequest(BaseModel):
    message: str
    user_id: str  # Required now!
    conversation_id: Optional[str] = None

class ChatResponse(BaseModel):
    response: str
    conversation_id: str

class ConversationResponse(BaseModel):
    conversation_id: str
    messages: List[Dict[str, str]]

# Helper function to get or create conversation
def get_conversation(conv_id: str) -> ChatMessageHistory:
    if conv_id not in conversations:
        conversations[conv_id] = ChatMessageHistory()
    return conversations[conv_id]

# Streaming Chat Endpoint
@app.post("/api/chat/stream")
async def chat_stream(request: ChatRequest):
    """
    Stream the health mentor response personalized to user.
    """
    # Fetch user profile
    user_profile = get_user_profile(request.user_id)
    
    if not user_profile:
        raise HTTPException(status_code=404, detail="User profile not found")
    
    # Create personalized system prompt
    SYSTEM_PROMPT = create_health_mentor_prompt(user_profile)
    
    conv_id = request.conversation_id or str(uuid.uuid4())
    history = get_conversation(conv_id)
    
    # Create prompt template with personalized system message
    prompt = ChatPromptTemplate.from_messages([
        ("system", SYSTEM_PROMPT),
        MessagesPlaceholder(variable_name="history"),
        ("human", "{input}")
    ])
    
    chain = prompt | llm | StrOutputParser()
    
    async def generate():
        try:
            full_response = ""
            yield f"data: {json.dumps({'conversation_id': conv_id, 'type': 'start'})}\n\n"
            
            for chunk in chain.stream({
                "history": history.messages,
                "input": request.message
            }):
                full_response += chunk
                yield f"data: {json.dumps({'content': chunk, 'type': 'chunk'})}\n\n"
            
            history.add_user_message(request.message)
            history.add_ai_message(full_response)
            
            yield f"data: {json.dumps({'type': 'end'})}\n\n"
            
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e), 'type': 'error'})}\n\n"
    
    return StreamingResponse(generate(), media_type="text/event-stream")
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)