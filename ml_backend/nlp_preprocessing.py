"""
NLP Preprocessing Module
Implements custom algorithms for text preprocessing without using high-level libraries
"""

import re
import math
from collections import Counter, defaultdict
from typing import List, Dict, Tuple, Set
import unicodedata


class VietnameseTokenizer:
    """Custom Vietnamese tokenizer"""
    
    def __init__(self):
        # Vietnamese syllable patterns
        self.vietnamese_chars = set('aàáảãạăằắẳẵặâầấẩẫậeèéẻẽẹêềếểễệiìíỉĩịoòóỏõọôồốổỗộơờớởỡợuùúủũụưừứửữựyỳýỷỹỵđ')
        
    def tokenize(self, text: str) -> List[str]:
        """Tokenize text into words"""
        # Convert to lowercase
        text = text.lower()
        
        # Remove special characters but keep Vietnamese diacritics
        text = re.sub(r'[^\w\s]', ' ', text)
        
        # Split by whitespace
        tokens = text.split()
        
        # Remove empty tokens
        tokens = [t for t in tokens if t.strip()]
        
        return tokens
    
    def is_vietnamese(self, text: str) -> bool:
        """Check if text contains Vietnamese characters"""
        text_lower = text.lower()
        return any(char in self.vietnamese_chars for char in text_lower)


class PorterStemmer:
    """Simplified Porter Stemmer for English"""
    
    def __init__(self):
        self.vowels = set('aeiou')
        
    def _is_consonant(self, word: str, i: int) -> bool:
        """Check if character at position i is consonant"""
        if i >= len(word):
            return False
        char = word[i]
        if char in self.vowels:
            return False
        if char == 'y':
            if i == 0:
                return True
            else:
                return not self._is_consonant(word, i - 1)
        return True
    
    def _measure(self, word: str) -> int:
        """Calculate measure of word (VC)^m"""
        cv_sequence = []
        for i in range(len(word)):
            if self._is_consonant(word, i):
                if not cv_sequence or cv_sequence[-1] != 'C':
                    cv_sequence.append('C')
            else:
                if not cv_sequence or cv_sequence[-1] != 'V':
                    cv_sequence.append('V')
        
        # Count VC patterns
        pattern = ''.join(cv_sequence)
        return pattern.count('VC')
    
    def stem(self, word: str) -> str:
        """Apply Porter stemming algorithm"""
        if len(word) <= 2:
            return word
            
        word = word.lower()
        
        # Step 1a: plurals
        if word.endswith('sses'):
            word = word[:-2]
        elif word.endswith('ies'):
            word = word[:-2]
        elif word.endswith('ss'):
            pass
        elif word.endswith('s'):
            word = word[:-1]
        
        # Step 1b: past tense
        if word.endswith('eed'):
            stem = word[:-3]
            if self._measure(stem) > 0:
                word = stem + 'ee'
        elif word.endswith('ed'):
            stem = word[:-2]
            if any(c in self.vowels for c in stem):
                word = stem
        elif word.endswith('ing'):
            stem = word[:-3]
            if any(c in self.vowels for c in stem):
                word = stem
        
        # Step 2: double consonant removal
        if len(word) >= 2 and word[-1] == word[-2] and word[-1] not in self.vowels:
            word = word[:-1]
        
        return word


class VietnameseStemmer:
    """Custom Vietnamese stemmer"""
    
    def __init__(self):
        # Common Vietnamese suffixes
        self.suffixes = ['tion', 'ing', 'ed', 'ly', 'ness', 'ment']
        
    def stem(self, word: str) -> str:
        """Simple Vietnamese stemming"""
        word = word.lower()
        
        # Remove common suffixes
        for suffix in self.suffixes:
            if word.endswith(suffix) and len(word) > len(suffix) + 2:
                return word[:-len(suffix)]
        
        return word


class StopWordsRemover:
    """Remove stop words for Vietnamese and English"""
    
    def __init__(self):
        self.vietnamese_stopwords = {
            'và', 'của', 'có', 'được', 'trong', 'là', 'với', 'cho', 'từ', 'này',
            'đó', 'những', 'các', 'một', 'để', 'không', 'tôi', 'bạn', 'họ', 'chúng',
            'tìm', 'tìm kiếm', 'phim', 'movie', 'cho tôi', 'tôi muốn', 'làm ơn',
            'có thể', 'bạn có thể', 'giúp', 'tôi', 'xem', 'coi', 'về'
        }
        
        self.english_stopwords = {
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
            'of', 'with', 'by', 'from', 'is', 'are', 'was', 'were', 'be', 'been',
            'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
            'could', 'should', 'may', 'might', 'can', 'find', 'search', 'show', 'me'
        }
        
        self.all_stopwords = self.vietnamese_stopwords | self.english_stopwords
    
    def remove(self, tokens: List[str]) -> List[str]:
        """Remove stop words from token list"""
        return [token for token in tokens if token.lower() not in self.all_stopwords]


class TextNormalizer:
    """Normalize text for NLP processing"""
    
    def __init__(self):
        self.vietnamese_map = {
            'hành động': 'action',
            'hành đông': 'action',
            'tình cảm': 'romance',
            'tình cam': 'romance',
            'kinh dị': 'horror',
            'kinh di': 'horror',
            'hài': 'comedy',
            'hai': 'comedy',
            'hài hước': 'comedy',
            'viễn tưởng': 'sci-fi',
            'vien tuong': 'sci-fi',
            'khoa học viễn tưởng': 'sci-fi',
            'phiêu lưu': 'adventure',
            'phieu luu': 'adventure',
            'giả tưởng': 'fantasy',
            'gia tuong': 'fantasy',
            'tội phạm': 'crime',
            'toi pham': 'crime',
            'chiến tranh': 'war',
            'chien tranh': 'war',
            'thể thao': 'sport',
            'the thao': 'sport',
            'tài liệu': 'documentary',
            'tai lieu': 'documentary',
            'gia đình': 'family',
            'gia dinh': 'family',
            'lịch sử': 'history',
            'lich su': 'history',
            'âm nhạc': 'music',
            'am nhac': 'music',
            'bí ẩn': 'mystery',
            'bi an': 'mystery',
            'hồi hộp': 'thriller',
            'hoi hop': 'thriller',
            'miền tây': 'western',
            'mien tay': 'western',
            'hoạt hình': 'animation',
            'hoat hinh': 'animation',
            'hoạt họa': 'animation',
        }
    
    def normalize(self, text: str) -> str:
        """Normalize Vietnamese text to English equivalents"""
        text = text.lower()
        
        # Replace Vietnamese genre names with English
        for viet, eng in self.vietnamese_map.items():
            text = text.replace(viet, eng)
        
        # Remove accents for better matching
        text = self._remove_accents(text)
        
        return text
    
    def _remove_accents(self, text: str) -> str:
        """Remove Vietnamese accents"""
        # NFD normalization separates base characters from diacritics
        nfd = unicodedata.normalize('NFD', text)
        # Filter out diacritics
        without_accents = ''.join(char for char in nfd if unicodedata.category(char) != 'Mn')
        return without_accents


class NLPPreprocessor:
    """Main preprocessing pipeline"""
    
    def __init__(self):
        self.tokenizer = VietnameseTokenizer()
        self.english_stemmer = PorterStemmer()
        self.vietnamese_stemmer = VietnameseStemmer()
        self.stopwords_remover = StopWordsRemover()
        self.normalizer = TextNormalizer()
    
    def preprocess(self, text: str, remove_stopwords: bool = True, 
                   apply_stemming: bool = True, normalize: bool = True) -> List[str]:
        """Full preprocessing pipeline"""
        
        # Normalize Vietnamese to English
        if normalize:
            text = self.normalizer.normalize(text)
        
        # Tokenize
        tokens = self.tokenizer.tokenize(text)
        
        # Remove stopwords
        if remove_stopwords:
            tokens = self.stopwords_remover.remove(tokens)
        
        # Apply stemming
        if apply_stemming:
            stemmed_tokens = []
            for token in tokens:
                if self.tokenizer.is_vietnamese(token):
                    stemmed_tokens.append(self.vietnamese_stemmer.stem(token))
                else:
                    stemmed_tokens.append(self.english_stemmer.stem(token))
            tokens = stemmed_tokens
        
        return tokens
    
    def extract_ngrams(self, tokens: List[str], n: int = 2) -> List[str]:
        """Extract n-grams from tokens"""
        ngrams = []
        for i in range(len(tokens) - n + 1):
            ngram = ' '.join(tokens[i:i+n])
            ngrams.append(ngram)
        return ngrams
    
    def get_word_frequency(self, tokens: List[str]) -> Dict[str, int]:
        """Calculate word frequency"""
        return dict(Counter(tokens))


class TFIDFVectorizer:
    """Custom TF-IDF implementation"""
    
    def __init__(self):
        self.vocabulary = {}
        self.idf_values = {}
        self.documents = []
    
    def fit(self, documents: List[List[str]]):
        """Fit TF-IDF on documents"""
        self.documents = documents
        
        # Build vocabulary
        all_words = set()
        for doc in documents:
            all_words.update(doc)
        
        self.vocabulary = {word: idx for idx, word in enumerate(sorted(all_words))}
        
        # Calculate IDF
        num_docs = len(documents)
        word_doc_count = defaultdict(int)
        
        for doc in documents:
            unique_words = set(doc)
            for word in unique_words:
                word_doc_count[word] += 1
        
        for word in self.vocabulary:
            # IDF = log(N / (df + 1))
            self.idf_values[word] = math.log(num_docs / (word_doc_count[word] + 1))
    
    def transform(self, document: List[str]) -> Dict[str, float]:
        """Transform document to TF-IDF vector"""
        # Calculate TF
        word_count = Counter(document)
        total_words = len(document)
        
        tfidf_vector = {}
        for word in document:
            if word in self.vocabulary:
                tf = word_count[word] / total_words
                idf = self.idf_values.get(word, 0)
                tfidf_vector[word] = tf * idf
        
        return tfidf_vector
    
    def cosine_similarity(self, vec1: Dict[str, float], vec2: Dict[str, float]) -> float:
        """Calculate cosine similarity between two TF-IDF vectors"""
        # Get common words
        common_words = set(vec1.keys()) & set(vec2.keys())
        
        if not common_words:
            return 0.0
        
        # Calculate dot product
        dot_product = sum(vec1[word] * vec2[word] for word in common_words)
        
        # Calculate magnitudes
        mag1 = math.sqrt(sum(val ** 2 for val in vec1.values()))
        mag2 = math.sqrt(sum(val ** 2 for val in vec2.values()))
        
        if mag1 == 0 or mag2 == 0:
            return 0.0
        
        return dot_product / (mag1 * mag2)


# Example usage
if __name__ == "__main__":
    preprocessor = NLPPreprocessor()
    
    # Test Vietnamese text
    text1 = "Tìm phim hành động mới nhất năm 2024"
    tokens1 = preprocessor.preprocess(text1)
    print(f"Original: {text1}")
    print(f"Tokens: {tokens1}")
    print()
    
    # Test English text
    text2 = "Find action movies released in 2024"
    tokens2 = preprocessor.preprocess(text2)
    print(f"Original: {text2}")
    print(f"Tokens: {tokens2}")
    print()
    
    # Test TF-IDF
    vectorizer = TFIDFVectorizer()
    documents = [tokens1, tokens2, ['action', 'movie', '2024', 'new']]
    vectorizer.fit(documents)
    
    vec1 = vectorizer.transform(tokens1)
    vec2 = vectorizer.transform(tokens2)
    similarity = vectorizer.cosine_similarity(vec1, vec2)
    print(f"Similarity: {similarity:.4f}")
