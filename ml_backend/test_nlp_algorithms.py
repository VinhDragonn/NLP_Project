"""
Test script to demonstrate all NLP algorithms
Run this to see how each algorithm works
"""

import sys
from nlp_preprocessing import NLPPreprocessor, TFIDFVectorizer
from nlp_intent_classifier import IntentClassifier
from nlp_ner import QueryAnalyzer, SemanticMatcher
from nlp_semantic_similarity import (
    LevenshteinDistance, JaccardSimilarity, CosineSimilarity,
    NGramSimilarity, SemanticSimilarityCalculator, FuzzyMatcher
)
from nlp_query_expansion import NLPQueryProcessor


def print_section(title):
    """Print section header"""
    print("\n" + "="*70)
    print(f"  {title}")
    print("="*70)


def test_preprocessing():
    """Test preprocessing algorithms"""
    print_section("1. TEXT PREPROCESSING")
    
    preprocessor = NLPPreprocessor()
    
    test_texts = [
        "Tìm phim hành động mới nhất năm 2024",
        "Find the best action movies from 2024",
        "Phim kinh dị hay nhất",
        "Tom Cruise movies"
    ]
    
    for text in test_texts:
        print(f"\n📝 Original: {text}")
        
        # Tokenization
        tokens = preprocessor.tokenizer.tokenize(text)
        print(f"   Tokens: {tokens}")
        
        # Full preprocessing
        processed = preprocessor.preprocess(text)
        print(f"   Processed: {processed}")
        
        # N-grams
        bigrams = preprocessor.extract_ngrams(processed, n=2)
        print(f"   Bigrams: {bigrams[:3]}...")
        
        # Word frequency
        freq = preprocessor.get_word_frequency(processed)
        print(f"   Frequency: {dict(list(freq.items())[:3])}")


def test_tfidf():
    """Test TF-IDF algorithm"""
    print_section("2. TF-IDF VECTORIZATION")
    
    preprocessor = NLPPreprocessor()
    vectorizer = TFIDFVectorizer()
    
    # Sample documents
    documents = [
        preprocessor.preprocess("action movies 2024"),
        preprocessor.preprocess("comedy films new"),
        preprocessor.preprocess("action adventure 2024"),
        preprocessor.preprocess("horror movies scary")
    ]
    
    print("\n📚 Training TF-IDF on documents...")
    vectorizer.fit(documents)
    
    print(f"   Vocabulary size: {len(vectorizer.vocabulary)}")
    print(f"   Vocabulary: {list(vectorizer.vocabulary.keys())[:10]}")
    
    # Transform a document
    test_doc = preprocessor.preprocess("action movies 2024")
    tfidf_vec = vectorizer.transform(test_doc)
    
    print(f"\n📊 TF-IDF vector for 'action movies 2024':")
    for word, score in sorted(tfidf_vec.items(), key=lambda x: x[1], reverse=True)[:5]:
        print(f"   {word}: {score:.4f}")
    
    # Cosine similarity
    doc1 = preprocessor.preprocess("action movies")
    doc2 = preprocessor.preprocess("adventure films")
    vec1 = vectorizer.transform(doc1)
    vec2 = vectorizer.transform(doc2)
    similarity = vectorizer.cosine_similarity(vec1, vec2)
    
    print(f"\n🔍 Cosine Similarity:")
    print(f"   'action movies' vs 'adventure films': {similarity:.4f}")


def test_intent_classification():
    """Test intent classification algorithms"""
    print_section("3. INTENT CLASSIFICATION (Naive Bayes + SVM)")
    
    classifier = IntentClassifier()
    
    test_queries = [
        "Tìm phim hành động mới nhất",
        "Find action movies from 2024",
        "Best comedy films",
        "Movies similar to Avengers",
        "Tom Cruise movies",
        "Popular movies trending now"
    ]
    
    for query in test_queries:
        result = classifier.classify_intent(query)
        
        print(f"\n🎯 Query: {query}")
        print(f"   Intent: {result['intent']} (confidence: {result['confidence']:.2f})")
        print(f"   Naive Bayes: {result['naive_bayes']['intent']} ({result['naive_bayes']['confidence']:.2f})")
        print(f"   SVM: {result['svm']['intent']} ({result['svm']['confidence']:.2f})")
        print(f"   Rule-based: {result['rule_based']}")
        print(f"   Tokens: {result['tokens']}")


def test_ner():
    """Test Named Entity Recognition"""
    print_section("4. NAMED ENTITY RECOGNITION (NER)")
    
    analyzer = QueryAnalyzer()
    
    test_queries = [
        "Find action movies from 2024",
        "Tom Cruise thriller films",
        "Best horror movies",
        "Popular sci-fi 2023"
    ]
    
    for query in test_queries:
        result = analyzer.analyze_query(query)
        
        print(f"\n🔎 Query: {query}")
        print(f"   Query Type: {result['query_type']}")
        print(f"   Complexity: {result['complexity']}")
        print(f"   Entities:")
        for entity_type, entities in result['features']['entities'].items():
            if entities:
                print(f"      {entity_type}: {entities}")
        print(f"   Search Parameters:")
        for param, value in result['search_parameters'].items():
            if value:
                print(f"      {param}: {value}")


def test_similarity():
    """Test similarity algorithms"""
    print_section("5. SEMANTIC SIMILARITY ALGORITHMS")
    
    # Test pairs
    test_pairs = [
        ("action movies", "adventure films"),
        ("avenger", "avengers"),
        ("horror", "scary"),
        ("comedy", "drama")
    ]
    
    for text1, text2 in test_pairs:
        print(f"\n📏 Comparing: '{text1}' vs '{text2}'")
        
        # Levenshtein Distance
        lev_sim = LevenshteinDistance.similarity(text1, text2)
        print(f"   Levenshtein Similarity: {lev_sim:.4f}")
        
        # Jaccard Similarity
        tokens1 = set(text1.split())
        tokens2 = set(text2.split())
        jac_sim = JaccardSimilarity.calculate(tokens1, tokens2)
        print(f"   Jaccard Similarity: {jac_sim:.4f}")
        
        # N-gram Similarity
        ngram_sim = NGramSimilarity.calculate(text1, text2, n=2)
        print(f"   N-gram Similarity: {ngram_sim:.4f}")
        
        # Cosine Similarity
        from collections import Counter
        vec1 = {k: float(v) for k, v in Counter(text1.split()).items()}
        vec2 = {k: float(v) for k, v in Counter(text2.split()).items()}
        cos_sim = CosineSimilarity.calculate(vec1, vec2)
        print(f"   Cosine Similarity: {cos_sim:.4f}")


def test_fuzzy_matching():
    """Test fuzzy matching"""
    print_section("6. FUZZY MATCHING")
    
    matcher = FuzzyMatcher()
    
    queries = [
        ("avenger", ["The Avengers", "Avengers: Endgame", "Avatar", "The Amazing Spider-Man"]),
        ("spider man", ["Spider-Man", "The Amazing Spider-Man", "Spider-Man: No Way Home", "Iron Man"]),
        ("batman", ["Batman", "Batman Begins", "The Batman", "Superman"])
    ]
    
    for query, candidates in queries:
        print(f"\n🔍 Query: '{query}'")
        print(f"   Candidates: {candidates}")
        
        matches = matcher.fuzzy_match(query, candidates, threshold=0.3)
        
        print(f"   Matches:")
        for candidate, score in matches[:3]:
            print(f"      {candidate}: {score:.4f}")


def test_query_expansion():
    """Test query expansion and spell correction"""
    print_section("7. QUERY EXPANSION & SPELL CORRECTION")
    
    processor = NLPQueryProcessor()
    
    test_queries = [
        "Find action movies from 2024",
        "tim phim hanh dong moi nhat",
        "best comedy films",
        "horror movies scary"
    ]
    
    for query in test_queries:
        result = processor.process_query(query)
        
        print(f"\n✏️ Original Query: {query}")
        print(f"   Corrected: {result['corrected_query']}")
        print(f"   Simplified: {result['simplified_query']}")
        print(f"   Expanded Queries:")
        for exp_query in result['expanded_queries'][:3]:
            print(f"      - {exp_query}")
        print(f"   Rewritten Queries:")
        for rew_query in result['rewritten_queries'][:3]:
            print(f"      - {rew_query}")


def test_complete_pipeline():
    """Test complete NLP pipeline"""
    print_section("8. COMPLETE NLP PIPELINE")
    
    preprocessor = NLPPreprocessor()
    classifier = IntentClassifier()
    analyzer = QueryAnalyzer()
    processor = NLPQueryProcessor()
    
    voice_text = "Tìm phim hành động mới nhất năm 2024"
    
    print(f"\n🎤 Voice Input: {voice_text}")
    
    # Step 1: Preprocessing
    print(f"\n📝 Step 1: Preprocessing")
    tokens = preprocessor.preprocess(voice_text)
    print(f"   Tokens: {tokens}")
    
    # Step 2: Intent Classification
    print(f"\n🎯 Step 2: Intent Classification")
    intent_result = classifier.classify_intent(voice_text)
    print(f"   Intent: {intent_result['intent']}")
    print(f"   Confidence: {intent_result['confidence']:.2f}")
    
    # Step 3: Query Analysis
    print(f"\n🔎 Step 3: Query Analysis (NER)")
    analysis = analyzer.analyze_query(voice_text)
    print(f"   Query Type: {analysis['query_type']}")
    print(f"   Entities: {analysis['features']['entities']}")
    
    # Step 4: Query Expansion
    print(f"\n✏️ Step 4: Query Expansion")
    expansion = processor.process_query(voice_text)
    print(f"   Corrected: {expansion['corrected_query']}")
    print(f"   Expanded: {expansion['expanded_queries'][:3]}")
    
    # Final output
    print(f"\n✅ Final Search Query:")
    print(f"   Query: {expansion['corrected_query']}")
    print(f"   Intent: {intent_result['intent']}")
    print(f"   Genres: {analysis['features']['entities']['genres']}")
    print(f"   Years: {analysis['features']['entities']['years']}")
    print(f"   Sort By: {analysis['search_parameters']['sort_by']}")


def main():
    """Run all tests"""
    print("\n" + "🚀 "*35)
    print("  NLP ALGORITHMS DEMONSTRATION")
    print("  Custom Implementation for Movie Voice Search")
    print("🚀 "*35)
    
    try:
        test_preprocessing()
        test_tfidf()
        test_intent_classification()
        test_ner()
        test_similarity()
        test_fuzzy_matching()
        test_query_expansion()
        test_complete_pipeline()
        
        print("\n" + "✅ "*35)
        print("  ALL TESTS COMPLETED SUCCESSFULLY!")
        print("✅ "*35 + "\n")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
