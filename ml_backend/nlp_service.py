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
from hybrid_search_engine import HybridSearchEngine


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


class HybridSearchRequest(BaseModel):
    query: str = Field(..., description="Search query")
    top_k: Optional[int] = Field(5, description="Number of results to return")


class HybridSearchResponse(BaseModel):
    query: str
    intent: str
    alpha: float
    results: List[Dict[str, Any]]
    processing_time_ms: float


# ===== Global Variables =====

NLP_PREPROCESSOR = None
INTENT_CLASSIFIER = None
QUERY_ANALYZER = None
SEMANTIC_MATCHER = None
SIMILARITY_CALCULATOR = None
FUZZY_MATCHER = None
QUERY_PROCESSOR = None
HYBRID_SEARCH_ENGINE = None


# ===== Lifespan =====
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize NLP models on startup"""
    global NLP_PREPROCESSOR, INTENT_CLASSIFIER, QUERY_ANALYZER
    global SEMANTIC_MATCHER, SIMILARITY_CALCULATOR, FUZZY_MATCHER, QUERY_PROCESSOR
    global HYBRID_SEARCH_ENGINE

    print("\n" + "=" * 60)
    print("Initializing NLP Service...")
    print("=" * 60 + "\n")

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

    # Initialize Hybrid Search Engine (optional - requires dataset)
    print("\n" + "=" * 60)
    print("Initializing Hybrid Search Engine (BiLSTM + Hybrid)...")
    print("=" * 60)
    try:
        HYBRID_SEARCH_ENGINE = HybridSearchEngine(data_dir="data")
        
        # Try to load dataset (if available)
        dataset_path = os.getenv("MOVIE_DATASET_PATH", "data/rotten_tomatoes_ENRICHED.csv")
        if os.path.exists(dataset_path):
            print(f"📂 Loading dataset from: {dataset_path}")
            HYBRID_SEARCH_ENGINE.load_dataset(dataset_path)
            HYBRID_SEARCH_ENGINE.initialize_tfidf()
            HYBRID_SEARCH_ENGINE.initialize_sbert()
            
            # Try to load or train intent classifier
            intent_model_path = "data/intent_classifier.h5"
            if os.path.exists(intent_model_path):
                try:
                    HYBRID_SEARCH_ENGINE.load_intent_classifier(intent_model_path)
                    print("✅ Intent classifier loaded")
                except:
                    print("⚠️ Could not load intent classifier, will train if needed")
            else:
                print("⚠️ Intent classifier not found. Train it using train_intent_classifier()")
            
            print("✅ Hybrid Search Engine ready!")
        else:
            print(f"⚠️ Dataset not found at {dataset_path}")
            print("   Hybrid search will be disabled until dataset is available")
            HYBRID_SEARCH_ENGINE = None
    except Exception as e:
        print(f"⚠️ Error initializing Hybrid Search Engine: {e}")
        print("   Hybrid search will be disabled")
        HYBRID_SEARCH_ENGINE = None

    print("\n✅ NLP Service ready!\n")

    yield

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


# ===== Cached NLP Pipeline =====

@lru_cache(maxsize=1000)
def _run_voice_search_pipeline(normalized_text: str, language: str) -> VoiceSearchResponse:

    print(f"\n{'=' * 60}")
    print(f"--- 🏃‍♂️ [CACHE MISS] Running NLP pipeline for: '{normalized_text}' ---")

    tokens = NLP_PREPROCESSOR.preprocess(normalized_text)
    intent_result = INTENT_CLASSIFIER.classify_intent(normalized_text)
    query_analysis = QUERY_ANALYZER.analyze_query(normalized_text)

    query_expansion = QUERY_PROCESSOR.process_query(
        normalized_text,
        query_type=intent_result['intent']
    )

    response = VoiceSearchResponse(
        original_text=normalized_text,
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

    print(f"--- ✅ Pipeline finished. Cached. ---")
    print(f"{'=' * 60}\n")

    return response


# ===== API ENDPOINTS =====

@app.get("/")
def root():
    return {
        "service": "Movie Search NLP Service",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "voice_search": "/api/nlp/voice-search",
            "hybrid_search": "/api/nlp/hybrid-search",
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
            NLP_PREPROCESSOR,
            INTENT_CLASSIFIER,
            QUERY_ANALYZER,
            SEMANTIC_MATCHER,
            SIMILARITY_CALCULATOR,
            FUZZY_MATCHER,
            QUERY_PROCESSOR
        ])
    }


# ===== Voice Search Endpoint =====

@app.post("/api/nlp/voice-search", response_model=VoiceSearchResponse)
def process_voice_search(request: VoiceSearchRequest):

    start_time = time.perf_counter()

    try:
        normalized_text = request.voice_text.lower().strip()
        normalized_lang = request.language.lower()

        # Remove stopwords just for validation
        tokens_after_stopwords = NLP_PREPROCESSOR.preprocess(
            normalized_text,
            remove_stopwords=True,
            apply_stemming=False,
            normalize=True
        )

        if not tokens_after_stopwords:
            end_time = time.perf_counter()
            return VoiceSearchResponse(
                original_text=request.voice_text,
                processed_query=normalized_text,
                intent="generic_query",
                confidence=1.0,
                entities={},
                search_parameters={},
                expanded_queries=[],
                suggestions=[
                    "Vui lòng tìm kiếm cụ thể hơn",
                    "Thử tìm tên phim hoặc diễn viên"
                ],
                analysis={
                    'query_type': 'generic',
                    'complexity': 0,
                    'tokens': [],
                    'intent_details': {
                        'note': 'Query only contains stopwords.'
                    }
                }
            )

        cached_response = _run_voice_search_pipeline(
            normalized_text,
            normalized_lang
        )

        final_response = cached_response.model_copy(
            update={"original_text": request.voice_text}
        )

        return final_response

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Voice search processing error: {str(e)}")


# ===== Hybrid Search Endpoint (BiLSTM + Hybrid) =====

@app.post("/api/nlp/hybrid-search", response_model=HybridSearchResponse)
def hybrid_search(request: HybridSearchRequest):
    """
    Hybrid search using BiLSTM + Attention for intent classification
    and Hybrid Search (TF-IDF + SBERT) for movie search
    """
    start_time = time.perf_counter()
    
    if HYBRID_SEARCH_ENGINE is None:
        raise HTTPException(
            status_code=503,
            detail="Hybrid Search Engine is not available. Please ensure the dataset is loaded."
        )
    
    try:
        results = HYBRID_SEARCH_ENGINE.search_hybrid(request.query, top_k=request.top_k)
        
        end_time = time.perf_counter()
        processing_time_ms = (end_time - start_time) * 1000
        
        # Extract intent and alpha from first result if available
        intent = "PLOT"
        alpha = 0.8
        if results:
            intent = results[0].get('intent', 'PLOT')
            alpha = results[0].get('alpha', 0.8)
        
        return HybridSearchResponse(
            query=request.query,
            intent=intent,
            alpha=alpha,
            results=results,
            processing_time_ms=processing_time_ms
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Hybrid search error: {str(e)}")


# ===== Intent Classification =====

@app.post("/api/nlp/intent", response_model=IntentClassificationResponse)
def classify_intent(request: TextAnalysisRequest):
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


# ===== Query Analysis =====

@app.post("/api/nlp/analyze")
def analyze_query(request: TextAnalysisRequest):
    try:
        return QUERY_ANALYZER.analyze_query(request.text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Query analysis error: {str(e)}")


# ===== Similarity =====

@app.post("/api/nlp/similarity", response_model=SimilarityResponse)
def calculate_similarity(request: SimilarityRequest):
    try:
        similarities = SIMILARITY_CALCULATOR.calculate_similarity(
            request.text1,
            request.text2,
            method=request.method
        )

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


# ===== Fuzzy Match =====

@app.post("/api/nlp/fuzzy-match", response_model=FuzzyMatchResponse)
def fuzzy_match(request: FuzzyMatchRequest):
    try:
        matches = FUZZY_MATCHER.fuzzy_match(
            request.query,
            request.candidates,
            threshold=request.threshold
        )

        formatted_matches = [
            {"text": text, "score": score} for text, score in matches
        ]

        best_match = formatted_matches[0] if formatted_matches else None

        return FuzzyMatchResponse(
            matches=formatted_matches,
            best_match=best_match
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fuzzy matching error: {str(e)}")


# ===== Query Expansion =====

@app.post("/api/nlp/expand-query", response_model=QueryExpansionResponse)
def expand_query(request: QueryExpansionRequest):
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


# ===== Preprocess =====

@app.post("/api/nlp/preprocess")
def preprocess_text(request: TextAnalysisRequest):
    try:
        tokens_full = NLP_PREPROCESSOR.preprocess(
            request.text,
            remove_stopwords=True,
            apply_stemming=True,
            normalize=True
        )

        tokens_no_stopwords = NLP_PREPROCESSOR.preprocess(
            request.text,
            remove_stopwords=False,
            apply_stemming=True,
            normalize=True
        )

        bigrams = NLP_PREPROCESSOR.extract_ngrams(tokens_full, n=2)
        trigrams = NLP_PREPROCESSOR.extract_ngrams(tokens_full, n=3)
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


# ===== Batch Similarity =====

@app.post("/api/nlp/batch-similarity")
def batch_similarity(query: str, candidates: List[str], top_k: int = 5):
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


# ===== RUN SERVER =====

if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", os.getenv("NLP_PORT", "8002")))
    print(f"\n🚀 Starting NLP Service on port {port}...")
    print(f"📍 Environment: {'Production' if os.getenv('PORT') else 'Development'}")

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=port,
        log_level="info"
    )
