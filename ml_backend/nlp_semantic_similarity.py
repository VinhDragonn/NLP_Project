"""
Semantic Similarity Module
Implements various similarity algorithms for text comparison
"""

import math
from typing import List, Dict, Set, Tuple
from collections import Counter
from nlp_preprocessing import NLPPreprocessor, TFIDFVectorizer


class LevenshteinDistance:
    """Calculate edit distance between strings"""
    
    @staticmethod
    def calculate(s1: str, s2: str) -> int:
        """Calculate Levenshtein distance"""
        if len(s1) < len(s2):
            return LevenshteinDistance.calculate(s2, s1)
        
        if len(s2) == 0:
            return len(s1)
        
        previous_row = range(len(s2) + 1)
        
        for i, c1 in enumerate(s1):
            current_row = [i + 1]
            for j, c2 in enumerate(s2):
                # Cost of insertions, deletions, or substitutions
                insertions = previous_row[j + 1] + 1
                deletions = current_row[j] + 1
                substitutions = previous_row[j] + (c1 != c2)
                current_row.append(min(insertions, deletions, substitutions))
            previous_row = current_row
        
        return previous_row[-1]
    
    @staticmethod
    def similarity(s1: str, s2: str) -> float:
        """Calculate similarity score (0-1)"""
        distance = LevenshteinDistance.calculate(s1, s2)
        max_len = max(len(s1), len(s2))
        if max_len == 0:
            return 1.0
        return 1.0 - (distance / max_len)


class JaccardSimilarity:
    """Calculate Jaccard similarity between sets"""
    
    @staticmethod
    def calculate(set1: Set, set2: Set) -> float:
        """Calculate Jaccard similarity coefficient"""
        if not set1 and not set2:
            return 1.0
        
        intersection = len(set1 & set2)
        union = len(set1 | set2)
        
        if union == 0:
            return 0.0
        
        return intersection / union
    
    @staticmethod
    def token_similarity(tokens1: List[str], tokens2: List[str]) -> float:
        """Calculate Jaccard similarity for token lists"""
        return JaccardSimilarity.calculate(set(tokens1), set(tokens2))


class CosineSimilarity:
    """Calculate cosine similarity between vectors"""
    
    @staticmethod
    def calculate(vec1: Dict[str, float], vec2: Dict[str, float]) -> float:
        """Calculate cosine similarity between two vectors"""
        # Get common keys
        common_keys = set(vec1.keys()) & set(vec2.keys())
        
        if not common_keys:
            return 0.0
        
        # Calculate dot product
        dot_product = sum(vec1[key] * vec2[key] for key in common_keys)
        
        # Calculate magnitudes
        magnitude1 = math.sqrt(sum(val ** 2 for val in vec1.values()))
        magnitude2 = math.sqrt(sum(val ** 2 for val in vec2.values()))
        
        if magnitude1 == 0 or magnitude2 == 0:
            return 0.0
        
        return dot_product / (magnitude1 * magnitude2)
    
    @staticmethod
    def token_vector_similarity(tokens1: List[str], tokens2: List[str]) -> float:
        """Calculate cosine similarity from token lists"""
        # Create frequency vectors
        vec1 = dict(Counter(tokens1))
        vec2 = dict(Counter(tokens2))
        
        # Convert to float
        vec1 = {k: float(v) for k, v in vec1.items()}
        vec2 = {k: float(v) for k, v in vec2.items()}
        
        return CosineSimilarity.calculate(vec1, vec2)


class NGramSimilarity:
    """Calculate n-gram based similarity"""
    
    @staticmethod
    def get_ngrams(text: str, n: int = 2) -> List[str]:
        """Extract character n-grams"""
        text = text.lower()
        return [text[i:i+n] for i in range(len(text) - n + 1)]
    
    @staticmethod
    def calculate(text1: str, text2: str, n: int = 2) -> float:
        """Calculate n-gram similarity"""
        ngrams1 = set(NGramSimilarity.get_ngrams(text1, n))
        ngrams2 = set(NGramSimilarity.get_ngrams(text2, n))
        
        return JaccardSimilarity.calculate(ngrams1, ngrams2)


class WordEmbedding:
    """Simple word embedding using co-occurrence matrix"""
    
    def __init__(self, vector_size: int = 50):
        self.vector_size = vector_size
        self.word_vectors = {}
        self.vocabulary = []
        
    def train(self, documents: List[List[str]], window_size: int = 2):
        """Train word embeddings using co-occurrence"""
        # Build vocabulary
        vocab_set = set()
        for doc in documents:
            vocab_set.update(doc)
        self.vocabulary = sorted(list(vocab_set))
        
        # Build co-occurrence matrix
        cooccurrence = defaultdict(lambda: defaultdict(int))
        
        for doc in documents:
            for i, word in enumerate(doc):
                # Look at context window
                start = max(0, i - window_size)
                end = min(len(doc), i + window_size + 1)
                
                for j in range(start, end):
                    if i != j:
                        context_word = doc[j]
                        cooccurrence[word][context_word] += 1
        
        # Convert to vectors using dimensionality reduction (simple approach)
        # Use most frequent co-occurrences as dimensions
        for word in self.vocabulary:
            vector = {}
            cooccur_words = cooccurrence[word]
            
            # Take top vector_size co-occurring words
            top_cooccur = sorted(cooccur_words.items(), key=lambda x: x[1], reverse=True)[:self.vector_size]
            
            for coword, count in top_cooccur:
                vector[coword] = float(count)
            
            # Normalize
            magnitude = math.sqrt(sum(v ** 2 for v in vector.values()))
            if magnitude > 0:
                vector = {k: v / magnitude for k, v in vector.items()}
            
            self.word_vectors[word] = vector
    
    def get_vector(self, word: str) -> Dict[str, float]:
        """Get vector for word"""
        return self.word_vectors.get(word, {})
    
    def similarity(self, word1: str, word2: str) -> float:
        """Calculate similarity between two words"""
        vec1 = self.get_vector(word1)
        vec2 = self.get_vector(word2)
        
        if not vec1 or not vec2:
            return 0.0
        
        return CosineSimilarity.calculate(vec1, vec2)
    
    def document_similarity(self, doc1: List[str], doc2: List[str]) -> float:
        """Calculate similarity between documents using word embeddings"""
        # Average word vectors for each document
        vec1 = self._average_vectors([self.get_vector(w) for w in doc1])
        vec2 = self._average_vectors([self.get_vector(w) for w in doc2])
        
        return CosineSimilarity.calculate(vec1, vec2)
    
    def _average_vectors(self, vectors: List[Dict[str, float]]) -> Dict[str, float]:
        """Average multiple vectors"""
        if not vectors:
            return {}
        
        # Sum all vectors
        avg_vector = defaultdict(float)
        count = 0
        
        for vec in vectors:
            if vec:
                count += 1
                for key, val in vec.items():
                    avg_vector[key] += val
        
        # Average
        if count > 0:
            avg_vector = {k: v / count for k, v in avg_vector.items()}
        
        return dict(avg_vector)


class SemanticSimilarityCalculator:
    """Main class for calculating semantic similarity"""
    
    def __init__(self):
        self.preprocessor = NLPPreprocessor()
        self.tfidf = TFIDFVectorizer()
        self.word_embedding = None
        
    def train_embeddings(self, documents: List[List[str]]):
        """Train word embeddings"""
        self.word_embedding = WordEmbedding(vector_size=50)
        self.word_embedding.train(documents)
    
    def calculate_similarity(self, text1: str, text2: str, method: str = 'all') -> Dict[str, float]:
        """Calculate similarity using multiple methods"""
        # Preprocess texts
        tokens1 = self.preprocessor.preprocess(text1)
        tokens2 = self.preprocessor.preprocess(text2)
        
        similarities = {}
        
        # Levenshtein similarity
        if method in ['all', 'levenshtein']:
            similarities['levenshtein'] = LevenshteinDistance.similarity(text1.lower(), text2.lower())
        
        # Jaccard similarity
        if method in ['all', 'jaccard']:
            similarities['jaccard'] = JaccardSimilarity.token_similarity(tokens1, tokens2)
        
        # Cosine similarity
        if method in ['all', 'cosine']:
            similarities['cosine'] = CosineSimilarity.token_vector_similarity(tokens1, tokens2)
        
        # N-gram similarity
        if method in ['all', 'ngram']:
            similarities['ngram_2'] = NGramSimilarity.calculate(text1, text2, n=2)
            similarities['ngram_3'] = NGramSimilarity.calculate(text1, text2, n=3)
        
        # Word embedding similarity
        if method in ['all', 'embedding'] and self.word_embedding:
            similarities['embedding'] = self.word_embedding.document_similarity(tokens1, tokens2)
        
        # Calculate average
        if similarities:
            similarities['average'] = sum(similarities.values()) / len(similarities)
        
        return similarities
    
    def find_most_similar(self, query: str, candidates: List[str], top_k: int = 5) -> List[Tuple[str, float]]:
        """Find most similar texts from candidates"""
        similarities = []
        
        for candidate in candidates:
            sim_scores = self.calculate_similarity(query, candidate)
            avg_score = sim_scores.get('average', 0.0)
            similarities.append((candidate, avg_score))
        
        # Sort by similarity
        similarities.sort(key=lambda x: x[1], reverse=True)
        
        return similarities[:top_k]


class FuzzyMatcher:
    """Fuzzy string matching for movie titles"""
    
    def __init__(self):
        self.preprocessor = NLPPreprocessor()
    
    def fuzzy_match(self, query: str, candidates: List[str], threshold: float = 0.6) -> List[Tuple[str, float]]:
        """Fuzzy match query against candidates"""
        matches = []
        query_lower = query.lower()
        
        for candidate in candidates:
            candidate_lower = candidate.lower()
            
            # Calculate multiple similarity scores
            lev_sim = LevenshteinDistance.similarity(query_lower, candidate_lower)
            ngram_sim = NGramSimilarity.calculate(query_lower, candidate_lower, n=2)
            
            # Token-based similarity
            query_tokens = set(self.preprocessor.preprocess(query))
            candidate_tokens = set(self.preprocessor.preprocess(candidate))
            jaccard_sim = JaccardSimilarity.calculate(query_tokens, candidate_tokens)
            
            # Combined score
            combined_score = (lev_sim * 0.3 + ngram_sim * 0.3 + jaccard_sim * 0.4)
            
            if combined_score >= threshold:
                matches.append((candidate, combined_score))
        
        # Sort by score
        matches.sort(key=lambda x: x[1], reverse=True)
        
        return matches


from collections import defaultdict


# Example usage
if __name__ == "__main__":
    calculator = SemanticSimilarityCalculator()
    
    # Test similarity
    text1 = "Find action movies from 2024"
    text2 = "Search for action films released in 2024"
    text3 = "Comedy movies"
    
    print("Similarity between text1 and text2:")
    sim12 = calculator.calculate_similarity(text1, text2)
    for method, score in sim12.items():
        print(f"  {method}: {score:.4f}")
    
    print("\nSimilarity between text1 and text3:")
    sim13 = calculator.calculate_similarity(text1, text3)
    for method, score in sim13.items():
        print(f"  {method}: {score:.4f}")
    
    # Test fuzzy matching
    print("\n" + "="*60)
    print("Fuzzy Matching:")
    matcher = FuzzyMatcher()
    
    query = "avenger"
    candidates = ["The Avengers", "Avengers: Endgame", "Avatar", "The Amazing Spider-Man"]
    
    matches = matcher.fuzzy_match(query, candidates)
    print(f"\nQuery: {query}")
    for candidate, score in matches:
        print(f"  {candidate}: {score:.4f}")
