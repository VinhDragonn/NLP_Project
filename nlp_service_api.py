"""
NLP Service API
FastAPI service for natural language processing of movie search queries
"""

import os
from typing import List, Dict, Optional, Any
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from functools import lru_cache
import time

# Import custom NLP modules
from nlp_preprocessing import NLPPreprocessor, TFIDFVectorizer
from nlp_intent_classifier import IntentClassifier
from nlp_ner import QueryAnalyzer, SemanticMatcher
from nlp_semantic_similarity import SemanticSimilarityCalculator, FuzzyMatcher
from nlp_query_expansion import NLPQueryProcessor


# ===== Pydantic Models =====

class VoiceSearchRequest(BaseModel):
    voice_text: str = Field(..., description="Transcribed voice text")
    language: Optional[str] = Field("vi", description="Language code (vi/en)")


class TextAnalysisRequest(BaseModel):
    text: str = Field(..., description="Text to analyze")


class SimilarityRequest(BaseModel):
    text1: str = Field(..., description="First text")
    text2: str = Field(..., description="Second text")
    method: Optional[str] = Field("all", description="Similarity method")


class FuzzyMatchRequest(BaseModel):
    query: str = Field(..., description="Search query")
    candidates: List[str] = Field(..., description="List of candidates to match")
    threshold: Optional[float] = Field(0.6, description="Minimum similarity threshold")


class QueryExpansionRequest(BaseModel):
    query: str = Field(..., description="Query to expand")
    max_expansions: Optional[int] = Field(10, description="Maximum number of expansions")


class VoiceSearchResponse(BaseModel):
    original_text: str
    processed_query: str
    intent: str
    confidence: float
    entities: Dict
    search_parameters: Dict
    expanded_queries: List[str]
    suggestions: List[str]
    analysis: Dict


class IntentClassificationResponse(BaseModel):
    intent: str
    confidence: float
    details: Dict


class SimilarityResponse(BaseModel):
    similarities: Dict[str, float]
    most_similar_method: str
    average_similarity: float


class FuzzyMatchResponse(BaseModel):
    matches: List[Dict[str, Any]]
    best_match: Optional[Dict[str, Any]]


class QueryExpansionResponse(BaseModel):
    original_query: str
    corrected_query: str
    simplified_query: str
    expanded_queries: List[str]
    rewritten_queries: List[str]
    suggestions: List[str]


# ===== Global Variables =====

NLP_PREPROCESSOR = None
INTENT_CLASSIFIER = None
QUERY_ANALYZER = None
SEMANTIC_MATCHER = None
SIMILARITY_CALCULATOR = None
FUZZY_MATCHER = None
QUERY_PROCESSOR = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize NLP models on startup"""
    global NLP_PREPROCESSOR, INTENT_CLASSIFIER, QUERY_ANALYZER
    global SEMANTIC_MATCHER, SIMILARITY_CALCULATOR, FUZZY_MATCHER, QUERY_PROCESSOR
    
    print("\n" + "="*60)
    print("Initializing NLP Service...")
    print("="*60 + "\n")
    
    # Initialize all NLP components
    print("Loading NLP Preprocessor...")
    NLP_PREPROCESSOR = NLPPreprocessor()
    
    print("Loading Intent Classifier...")
    INTENT_CLASSIFIER = IntentClassifier()
    INTENT_CLASSIFIER.train_from_examples()
    
    print("Loading Query Analyzer...")
    QUERY_ANALYZER = QueryAnalyzer()
    
    print("Loading Semantic Matcher...")
    SEMANTIC_MATCHER = SemanticMatcher()
    
    print("Loading Similarity Calculator...")
    SIMILARITY_CALCULATOR = SemanticSimilarityCalculator()
    
    print("Loading Fuzzy Matcher...")
    FUZZY_MATCHER = FuzzyMatcher()
    
    print("Loading Query Processor...")
    QUERY_PROCESSOR = NLPQueryProcessor()
    
    print("\n✅ NLP Service ready!\n")
    
    yield
    
    # Cleanup
    print("\n🔴 Shutting down NLP Service...")


# ===== FastAPI App =====

app = FastAPI(
    title="Movie Search NLP Service",
    description="Natural Language Processing service for movie voice search",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ===== API Endpoints =====

@app.get("/")
def root():
    return {
        "service": "Movie Search NLP Service",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "voice_search": "/api/nlp/voice-search",
            "intent_classification": "/api/nlp/intent",
            "query_analysis": "/api/nlp/analyze",
            "similarity": "/api/nlp/similarity",
            "fuzzy_match": "/api/nlp/fuzzy-match",
            "query_expansion": "/api/nlp/expand-query",
            "preprocess": "/api/nlp/preprocess"
        }
    }


@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "nlp_service",
        "models_loaded": all([
            NLP_PREPROCESSOR is not None,
            INTENT_CLASSIFIER is not None,
            QUERY_ANALYZER is not None,
            SEMANTIC_MATCHER is not None,
            SIMILARITY_CALCULATOR is not None,
            FUZZY_MATCHER is not None,
            QUERY_PROCESSOR is not None
        ])
    }


@lru_cache(maxsize=100)
def _cached_nlp_process(voice_text: str):
    """Cache NLP processing results for faster repeated queries"""
    # Step 1: Preprocess text
    tokens = NLP_PREPROCESSOR.preprocess(voice_text)
    
    # Step 2: Classify intent
    intent_result = INTENT_CLASSIFIER.classify_intent(voice_text)
    
    # Step 3: Analyze query
    query_analysis = QUERY_ANALYZER.analyze_query(voice_text)
    
    # Step 4: Expand query
    query_expansion = QUERY_PROCESSOR.process_query(
        voice_text, 
        query_type=intent_result['intent']
    )
    
    return {
        'tokens': tokens,
        'intent_result': intent_result,
        'query_analysis': query_analysis,
        'query_expansion': query_expansion
    }

@app.post("/api/nlp/voice-search", response_model=VoiceSearchResponse)
def process_voice_search(request: VoiceSearchRequest):
    """
    Complete voice search processing pipeline
    Combines all NLP algorithms for comprehensive analysis
    """
    try:
        voice_text = request.voice_text
        start_time = time.time()
        
        print(f"\n{'='*60}")
        print(f"🎤 Voice Input: {voice_text}")
        
        # Use cached processing for faster results
        cached_result = _cached_nlp_process(voice_text)
        
        tokens = cached_result['tokens']
        intent_result = cached_result['intent_result']
        query_analysis = cached_result['query_analysis']
        query_expansion = cached_result['query_expansion']
        
        processing_time = (time.time() - start_time) * 1000  # Convert to ms
        
        print(f"📝 Tokens: {tokens}")
        print(f"🎯 Intent: {intent_result['intent']}")
        print(f"   Confidence: {intent_result['confidence']:.2%}")
        
        entities = query_analysis['features']['entities']
        print(f"🏷️ Entities Extracted:")
        for key, values in entities.items():
            if values:
                print(f"   {key}: {values}")
        
        print(f"🔄 Processed Query: {query_expansion['corrected_query']}")
        print(f"⚡ Processing Time: {processing_time:.0f}ms")
        print(f"✅ NLP Accuracy Score: {intent_result['confidence']:.2%}")
        print(f"{'='*60}\n")
        
        # Step 5: Build response
        return VoiceSearchResponse(
            original_text=voice_text,
            processed_query=query_expansion['corrected_query'],
            intent=intent_result['intent'],
            confidence=intent_result['confidence'],
            entities=query_analysis['features']['entities'],
            search_parameters=query_analysis['search_parameters'],
            expanded_queries=query_expansion['expanded_queries'],
            suggestions=query_expansion['suggestions'],
            analysis={
                'query_type': query_analysis['query_type'],
                'complexity': query_analysis['complexity'],
                'tokens': tokens,
                'intent_details': intent_result
            }
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Voice search processing error: {str(e)}")


@app.post("/api/nlp/intent", response_model=IntentClassificationResponse)
def classify_intent(request: TextAnalysisRequest):
    """
    Classify user intent using Naive Bayes and SVM
    """
    try:
        result = INTENT_CLASSIFIER.classify_intent(request.text)
        
        return IntentClassificationResponse(
            intent=result['intent'],
            confidence=result['confidence'],
            details={
                'naive_bayes': result['naive_bayes'],
                'svm': result['svm'],
                'rule_based': result['rule_based'],
                'tokens': result['tokens']
            }
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Intent classification error: {str(e)}")


@app.post("/api/nlp/analyze")
def analyze_query(request: TextAnalysisRequest):
    """
    Comprehensive query analysis with NER and feature extraction
    """
    try:
        result = QUERY_ANALYZER.analyze_query(request.text)
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Query analysis error: {str(e)}")


@app.post("/api/nlp/similarity", response_model=SimilarityResponse)
def calculate_similarity(request: SimilarityRequest):
    """
    Calculate semantic similarity between two texts
    """
    try:
        similarities = SIMILARITY_CALCULATOR.calculate_similarity(
            request.text1,
            request.text2,
            method=request.method
        )
        
        # Find method with highest similarity
        if similarities:
            most_similar = max(similarities.items(), key=lambda x: x[1])
            avg_similarity = similarities.get('average', 0.0)
        else:
            most_similar = ('none', 0.0)
            avg_similarity = 0.0
        
        return SimilarityResponse(
            similarities=similarities,
            most_similar_method=most_similar[0],
            average_similarity=avg_similarity
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Similarity calculation error: {str(e)}")


@app.post("/api/nlp/fuzzy-match", response_model=FuzzyMatchResponse)
def fuzzy_match(request: FuzzyMatchRequest):
    """
    Fuzzy string matching for movie titles
    """
    try:
        matches = FUZZY_MATCHER.fuzzy_match(
            request.query,
            request.candidates,
            threshold=request.threshold
        )
        
        formatted_matches = [
            {"text": text, "score": score}
            for text, score in matches
        ]
        
        best_match = formatted_matches[0] if formatted_matches else None
        
        return FuzzyMatchResponse(
            matches=formatted_matches,
            best_match=best_match
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fuzzy matching error: {str(e)}")


@app.post("/api/nlp/expand-query", response_model=QueryExpansionResponse)
def expand_query(request: QueryExpansionRequest):
    """
    Expand query with synonyms, spell correction, and rewriting
    """
    try:
        result = QUERY_PROCESSOR.process_query(request.query)
        
        return QueryExpansionResponse(
            original_query=result['original_query'],
            corrected_query=result['corrected_query'],
            simplified_query=result['simplified_query'],
            expanded_queries=result['expanded_queries'][:request.max_expansions],
            rewritten_queries=result['rewritten_queries'],
            suggestions=result['suggestions']
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Query expansion error: {str(e)}")


@app.post("/api/nlp/preprocess")
def preprocess_text(request: TextAnalysisRequest):
    """
    Preprocess text (tokenization, stemming, stopword removal)
    """
    try:
        # Full preprocessing
        tokens_full = NLP_PREPROCESSOR.preprocess(
            request.text,
            remove_stopwords=True,
            apply_stemming=True,
            normalize=True
        )
        
        # Without stopword removal
        tokens_no_stopwords = NLP_PREPROCESSOR.preprocess(
            request.text,
            remove_stopwords=False,
            apply_stemming=True,
            normalize=True
        )
        
        # Extract n-grams
        bigrams = NLP_PREPROCESSOR.extract_ngrams(tokens_full, n=2)
        trigrams = NLP_PREPROCESSOR.extract_ngrams(tokens_full, n=3)
        
        # Word frequency
        word_freq = NLP_PREPROCESSOR.get_word_frequency(tokens_full)
        
        return {
            "original_text": request.text,
            "tokens": tokens_full,
            "tokens_with_stopwords": tokens_no_stopwords,
            "bigrams": bigrams,
            "trigrams": trigrams,
            "word_frequency": word_freq,
            "token_count": len(tokens_full),
            "unique_token_count": len(set(tokens_full))
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Preprocessing error: {str(e)}")


@app.post("/api/nlp/batch-similarity")
def batch_similarity(query: str, candidates: List[str], top_k: int = 5):
    """
    Find most similar texts from a list of candidates
    """
    try:
        results = SIMILARITY_CALCULATOR.find_most_similar(query, candidates, top_k)
        
        return {
            "query": query,
            "top_matches": [
                {"text": text, "similarity": score}
                for text, score in results
            ]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Batch similarity error: {str(e)}")


# ===== Run Server =====

if __name__ == "__main__":
    import uvicorn
    
    # Support both local development and cloud deployment
    port = int(os.getenv("PORT", os.getenv("NLP_PORT", "8002")))
    
    print(f"\n🚀 Starting NLP Service on port {port}...")
    print(f"📍 Environment: {'Production' if os.getenv('PORT') else 'Development'}")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=port,
        log_level="info"
    )
