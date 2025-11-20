"""
Query Expansion and Spell Correction Module
Implements algorithms for improving search queries
"""

import re
from typing import List, Dict, Set, Tuple, Optional
from collections import defaultdict, Counter
from nlp_preprocessing import NLPPreprocessor
from nlp_semantic_similarity import LevenshteinDistance

# Try to import translator
try:
    from googletrans import Translator
    TRANSLATOR_AVAILABLE = True
except ImportError:
    TRANSLATOR_AVAILABLE = False
    Translator = None


class SpellCorrector:
    """Spell correction using edit distance and frequency"""
    
    def __init__(self):
        self.word_frequency = Counter()
        self.vocabulary = set()
        
    def train(self, documents: List[List[str]]):
        """Train spell corrector with documents"""
        for doc in documents:
            self.word_frequency.update(doc)
        self.vocabulary = set(self.word_frequency.keys())
    
    def _edits1(self, word: str) -> Set[str]:
        """Generate all edits that are one edit away"""
        letters = 'abcdefghijklmnopqrstuvwxyz'
        splits = [(word[:i], word[i:]) for i in range(len(word) + 1)]
        
        # Deletions
        deletes = [L + R[1:] for L, R in splits if R]
        
        # Transpositions
        transposes = [L + R[1] + R[0] + R[2:] for L, R in splits if len(R) > 1]
        
        # Replacements
        replaces = [L + c + R[1:] for L, R in splits if R for c in letters]
        
        # Insertions
        inserts = [L + c + R for L, R in splits for c in letters]
        
        return set(deletes + transposes + replaces + inserts)
    
    def _edits2(self, word: str) -> Set[str]:
        """Generate all edits that are two edits away"""
        return set(e2 for e1 in self._edits1(word) for e2 in self._edits1(e1))
    
    def _known(self, words: Set[str]) -> Set[str]:
        """Return subset of words that are in vocabulary"""
        return set(w for w in words if w in self.vocabulary)
    
    def correct(self, word: str) -> str:
        """Correct spelling of word"""
        if word in self.vocabulary:
            return word
        
        # Try edits of distance 1
        candidates = self._known(self._edits1(word))
        
        # If no candidates, try edits of distance 2
        if not candidates:
            candidates = self._known(self._edits2(word))
        
        # If still no candidates, return original
        if not candidates:
            return word
        
        # Return most frequent candidate
        return max(candidates, key=lambda w: self.word_frequency[w])
    
    def correct_text(self, text: str) -> str:
        """Correct spelling in entire text"""
        words = text.split()
        corrected_words = [self.correct(word.lower()) for word in words]
        return ' '.join(corrected_words)


class VietnameseSpellCorrector:
    """Spell correction for Vietnamese text"""
    
    def __init__(self):
        # Common Vietnamese misspellings
        self.corrections = {
            'hanh dong': 'hành động',
            'hanh đong': 'hành động',
            'tinh cam': 'tình cảm',
            'tinh cảm': 'tình cảm',
            'kinh di': 'kinh dị',
            'vien tuong': 'viễn tưởng',
            'phieu luu': 'phiêu lưu',
            'gia tuong': 'giả tưởng',
            'toi pham': 'tội phạm',
            'chien tranh': 'chiến tranh',
            'the thao': 'thể thao',
            'tai lieu': 'tài liệu',
            'gia dinh': 'gia đình',
            'lich su': 'lịch sử',
            'am nhac': 'âm nhạc',
            'bi an': 'bí ẩn',
            'hoi hop': 'hồi hộp',
            'mien tay': 'miền tây',
            'hoat hinh': 'hoạt hình',
        }
    
    def correct(self, text: str) -> str:
        """Correct Vietnamese spelling"""
        text_lower = text.lower()
        
        # Only correct if the wrong spelling exists in the text
        # Don't modify words that are already correct
        for wrong, correct in self.corrections.items():
            if wrong in text_lower:
                text_lower = text_lower.replace(wrong, correct)
        
        # Return original if no corrections needed
        return text_lower


class QueryExpander:
    """Expand queries with synonyms and related terms"""
    
    def __init__(self):
        self.preprocessor = NLPPreprocessor()
        
        # Synonym dictionary
        self.synonyms = {
            'movie': ['film', 'cinema', 'picture', 'motion picture', 'phim'],
            'film': ['movie', 'cinema', 'picture', 'phim'],
            'find': ['search', 'look', 'discover', 'tìm', 'tìm kiếm'],
            'search': ['find', 'look', 'discover', 'tìm', 'tìm kiếm'],
            'good': ['great', 'excellent', 'amazing', 'wonderful', 'hay', 'tốt'],
            'bad': ['poor', 'terrible', 'awful', 'horrible', 'tệ', 'xấu'],
            'new': ['latest', 'recent', 'fresh', 'modern', 'mới', 'mới nhất'],
            'old': ['classic', 'vintage', 'retro', 'ancient', 'cũ', 'kinh điển'],
            'popular': ['trending', 'hot', 'viral', 'famous', 'phổ biến', 'nổi tiếng'],
            'best': ['top', 'greatest', 'finest', 'excellent', 'hay nhất', 'tốt nhất'],
            'action': ['adventure', 'thriller', 'hành động'],
            'comedy': ['humor', 'funny', 'hài', 'hài hước'],
            'horror': ['scary', 'terror', 'frightening', 'kinh dị'],
            'romance': ['love', 'romantic', 'tình cảm'],
            'drama': ['theatrical', 'kịch'],
            'scifi': ['science fiction', 'sci-fi', 'viễn tưởng'],
            'fantasy': ['magical', 'giả tưởng'],
        }
        
        # Hypernyms (more general terms)
        self.hypernyms = {
            'action': 'movie',
            'comedy': 'movie',
            'horror': 'movie',
            'romance': 'movie',
            'thriller': 'movie',
            'drama': 'movie',
        }
        
        # Hyponyms (more specific terms)
        self.hyponyms = {
            'movie': ['action', 'comedy', 'horror', 'romance', 'thriller', 'drama'],
            'good': ['excellent', 'amazing', 'wonderful'],
            'bad': ['terrible', 'awful', 'horrible'],
        }
    
    def expand_with_synonyms(self, query: str, max_expansions: int = 3) -> List[str]:
        """Expand query with synonyms"""
        tokens = self.preprocessor.preprocess(query, remove_stopwords=False)
        expanded_queries = [query]
        
        for token in tokens:
            if token in self.synonyms:
                synonyms = self.synonyms[token][:max_expansions]
                for syn in synonyms:
                    expanded_query = query.replace(token, syn)
                    if expanded_query not in expanded_queries:
                        expanded_queries.append(expanded_query)
        
        return expanded_queries
    
    def expand_with_hypernyms(self, query: str) -> List[str]:
        """Expand query with more general terms"""
        tokens = self.preprocessor.preprocess(query, remove_stopwords=False)
        expanded_queries = [query]
        
        for token in tokens:
            if token in self.hypernyms:
                hypernym = self.hypernyms[token]
                expanded_query = query.replace(token, hypernym)
                if expanded_query not in expanded_queries:
                    expanded_queries.append(expanded_query)
        
        return expanded_queries
    
    def expand_with_hyponyms(self, query: str) -> List[str]:
        """Expand query with more specific terms"""
        tokens = self.preprocessor.preprocess(query, remove_stopwords=False)
        expanded_queries = [query]
        
        for token in tokens:
            if token in self.hyponyms:
                hyponyms = self.hyponyms[token]
                for hypo in hyponyms:
                    expanded_query = query + ' ' + hypo
                    if expanded_query not in expanded_queries:
                        expanded_queries.append(expanded_query)
        
        return expanded_queries
    
    def expand_all(self, query: str, max_total: int = 10) -> List[str]:
        """Expand query using all methods"""
        all_expansions = set([query])
        
        # Add synonym expansions
        all_expansions.update(self.expand_with_synonyms(query))
        
        # Add hypernym expansions
        all_expansions.update(self.expand_with_hypernyms(query))
        
        # Add hyponym expansions
        all_expansions.update(self.expand_with_hyponyms(query))
        
        return list(all_expansions)[:max_total]


class QueryTranslator:
    """Translate queries to English for better search results"""
    
    def __init__(self):
        self.translator = None
        if TRANSLATOR_AVAILABLE:
            try:
                self.translator = Translator()
            except:
                self.translator = None
        
        # Only remove action words at the beginning, not descriptive words
        self.action_stopwords = {
            'tìm', 'tìm kiếm', 'xem', 'cho', 'tôi', 'muốn', 'cần',
            'find', 'search', 'watch', 'want', 'need', 'show me', 'give me'
        }
        
        # Common speech-recognition mistakes to fix before translation
        self.voice_error_map = {
            'fim': 'phim',
            'fim.': 'phim',
            'fim,': 'phim',
            'phin': 'phim',
            'film': 'phim',  # sometimes Vietnamese accent recognized as film
        }
    
    def _normalize_voice_errors(self, query: str) -> str:
        text = query
        for wrong, correct in self.voice_error_map.items():
            text = re.sub(rf'\b{re.escape(wrong)}\b', correct, text, flags=re.IGNORECASE)
        return text
    
    def clean_action_words(self, query: str) -> str:
        """Remove action words at the beginning only"""
        normalized_query = self._normalize_voice_errors(query)
        query_lower = normalized_query.lower().strip()
        words = query_lower.split()
        
        # Remove action words from the beginning
        while words and words[0] in self.action_stopwords:
            words.pop(0)
        
        # Also check for "tìm phim" or "find movie" pattern at start
        if len(words) >= 2:
            if (words[0] in ['tìm', 'find', 'search'] and 
                words[1] in ['phim', 'movie', 'film']):
                words = words[2:]  # Remove both words
        
        return ' '.join(words).strip() if words else query
    
    def translate_to_english(self, query: str) -> str:
        """Translate query to English if needed, preserving descriptive content"""
        query = self._normalize_voice_errors(query)
        if not self.translator:
            # If translator not available, just clean action words
            return self.clean_action_words(query)
        
        try:
            # Detect language first
            detected = self.translator.detect(query)
            
            # If already English, just clean action words
            if detected.lang.lower() == 'en':
                return self.clean_action_words(query)
            
            # Translate to English (translate everything, including descriptions)
            # This matches the Colab behavior: "tìm phim avatar" -> "Find avatar movies"
            translated = self.translator.translate(query, dest='en')
            translated_text = translated.text.strip()
            
            # Now clean action words from the translated text
            # Remove patterns like "find movie", "find film", "search movie" at the beginning
            words = translated_text.lower().split()
            
            # Remove "find movie" or "find film" pattern at start
            if len(words) >= 2:
                if (words[0] in ['find', 'search', 'look', 'show'] and 
                    words[1] in ['movie', 'film', 'movies', 'films']):
                    words = words[2:]
            
            # Remove single action words at start
            while words and words[0] in ['find', 'search', 'look', 'show', 'give', 'get']:
                words.pop(0)
            
            result = ' '.join(words).strip() if words else translated_text
            
            # If result is empty, return the original translation
            return result if result else translated_text
            
        except Exception as e:
            # If translation fails, return cleaned query
            print(f"Translation error: {e}")
            return self.clean_action_words(query)


class QueryRewriter:
    """Rewrite queries to improve search results"""
    
    def __init__(self):
        self.preprocessor = NLPPreprocessor()
        self.expander = QueryExpander()
        
        # Query templates
        self.templates = {
            'genre_search': [
                '{genre} movies',
                'best {genre} films',
                '{genre} cinema'
            ],
            'year_search': [
                'movies from {year}',
                '{year} films',
                'movies released in {year}'
            ],
            'actor_search': [
                '{actor} movies',
                'films starring {actor}',
                '{actor} filmography'
            ],
            'rating_search': [
                'top rated movies',
                'best movies',
                'highly rated films'
            ]
        }
    
    def rewrite(self, query: str, query_type: str = None) -> List[str]:
        """Rewrite query based on type"""
        rewrites = [query]
        
        if not query_type:
            return rewrites
        
        # Extract entities from query
        tokens = self.preprocessor.preprocess(query, remove_stopwords=False)
        
        if query_type == 'genre_search':
            genres = ['action', 'comedy', 'horror', 'romance', 'thriller', 'drama']
            for genre in genres:
                if genre in tokens:
                    for template in self.templates['genre_search']:
                        rewrites.append(template.format(genre=genre))
        
        elif query_type == 'year_search':
            # Extract year
            year_pattern = r'\b(19|20)\d{2}\b'
            years = re.findall(year_pattern, query)
            if years:
                year = years[0]
                for template in self.templates['year_search']:
                    rewrites.append(template.format(year=year))
        
        elif query_type == 'rating_search':
            rewrites.extend(self.templates['rating_search'])
        
        return list(set(rewrites))
    
    def simplify(self, query: str) -> str:
        """Simplify complex query - extract key terms for better TMDB search"""
        # For descriptive queries, extract key nouns and adjectives
        # Remove common words like "about", "a", "the", "movie", "film"
        common_words = {'about', 'a', 'an', 'the', 'movie', 'film', 'movies', 'films', 
                       'with', 'from', 'in', 'on', 'at', 'to', 'for', 'of', 'is', 'are'}
        
        # Remove stopwords
        tokens = self.preprocessor.preprocess(query, remove_stopwords=True)
        
        # Keep only important words (nouns, adjectives, proper nouns)
        important_tokens = []
        for token in tokens:
            if len(token) > 2 and token.lower() not in common_words:
                important_tokens.append(token)
        
        # If we have important tokens, use them; otherwise use original
        if important_tokens:
            return ' '.join(important_tokens)
        
        return ' '.join(important_tokens)


class QuerySuggester:
    """Generate query suggestions"""
    
    def __init__(self):
        self.preprocessor = NLPPreprocessor()
        self.popular_queries = Counter()
        
        # Predefined popular queries
        self.predefined_suggestions = [
            'action movies 2024',
            'best comedy films',
            'horror movies',
            'romantic comedies',
            'sci-fi movies',
            'thriller films',
            'animated movies',
            'documentary films',
            'classic movies',
            'popular movies'
        ]
    
    def add_query(self, query: str):
        """Add query to history"""
        normalized = self.preprocessor.preprocess(query, remove_stopwords=False)
        self.popular_queries[' '.join(normalized)] += 1
    
    def get_suggestions(self, partial_query: str, max_suggestions: int = 5) -> List[str]:
        """Get query suggestions based on partial input"""
        suggestions = []
        partial_lower = partial_query.lower()
        
        # Check predefined suggestions
        for suggestion in self.predefined_suggestions:
            if suggestion.startswith(partial_lower):
                suggestions.append(suggestion)
        
        # Check popular queries
        for query, count in self.popular_queries.most_common(20):
            if query.startswith(partial_lower):
                suggestions.append(query)
        
        # Remove duplicates and limit
        suggestions = list(dict.fromkeys(suggestions))
        return suggestions[:max_suggestions]
    
    def get_related_queries(self, query: str, max_related: int = 5) -> List[str]:
        """Get related queries"""
        tokens = set(self.preprocessor.preprocess(query))
        related = []
        
        # Find queries with overlapping tokens
        for stored_query, count in self.popular_queries.most_common(50):
            stored_tokens = set(self.preprocessor.preprocess(stored_query))
            overlap = len(tokens & stored_tokens)
            
            if overlap > 0 and stored_query != query:
                related.append((stored_query, overlap, count))
        
        # Sort by overlap and frequency
        related.sort(key=lambda x: (x[1], x[2]), reverse=True)
        
        return [q for q, _, _ in related[:max_related]]


class NLPQueryProcessor:
    """Main query processing pipeline"""
    
    def __init__(self):
        self.spell_corrector = SpellCorrector()
        self.vietnamese_corrector = VietnameseSpellCorrector()
        self.query_expander = QueryExpander()
        self.query_rewriter = QueryRewriter()
        self.query_suggester = QuerySuggester()
        self.query_translator = QueryTranslator()
        self.preprocessor = NLPPreprocessor()
    
    def process_query(self, query: str, query_type: str = None) -> Dict[str, any]:
        """Complete query processing pipeline"""
        # Step 1: Translate to English FIRST (preserves Vietnamese descriptions)
        translated_query = self.query_translator.translate_to_english(query)
        
        # Step 2: If translation didn't change much, apply spell correction
        if translated_query == query or not translated_query:
            corrected_query = self.vietnamese_corrector.correct(query)
            translated_query = self.query_translator.translate_to_english(corrected_query)
        
        corrected_query = translated_query if translated_query else query
        
        # Step 3: Simplify query (extract key terms for better TMDB search)
        simplified_query = self.query_rewriter.simplify(corrected_query)
        
        # Use simplified query if it's better (shorter, more focused)
        # For TMDB, shorter queries with key terms work better than long descriptions
        if simplified_query and len(simplified_query.split()) < len(corrected_query.split()):
            final_query = simplified_query
        else:
            final_query = corrected_query
        
        # Step 4: Expand query
        expanded_queries = self.query_expander.expand_all(final_query, max_total=5)
        
        # Step 5: Rewrite query
        rewritten_queries = self.query_rewriter.rewrite(final_query, query_type)
        
        # Step 6: Get suggestions
        suggestions = self.query_suggester.get_suggestions(final_query[:10])
        
        # Step 7: Get related queries
        related_queries = self.query_suggester.get_related_queries(final_query)
        
        return {
            'original_query': query,
            'corrected_query': final_query,  # Use simplified/final version for better TMDB search
            'simplified_query': simplified_query,
            'expanded_queries': expanded_queries,
            'rewritten_queries': rewritten_queries,
            'suggestions': suggestions,
            'related_queries': related_queries
        }


# Example usage
if __name__ == "__main__":
    processor = NLPQueryProcessor()
    
    # Test queries
    test_queries = [
        "Find action movies from 2024",
        "tim phim hanh dong moi nhat",
        "best comedy films",
        "horror movies"
    ]
    
    for query in test_queries:
        print(f"\n{'='*60}")
        print(f"Original Query: {query}")
        
        result = processor.process_query(query)
        
        print(f"Corrected: {result['corrected_query']}")
        print(f"Simplified: {result['simplified_query']}")
        print(f"Expanded: {result['expanded_queries'][:3]}")
        print(f"Rewritten: {result['rewritten_queries'][:3]}")
