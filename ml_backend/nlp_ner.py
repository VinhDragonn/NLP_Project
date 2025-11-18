"""
Named Entity Recognition (NER) Module
Custom implementation for recognizing movie-related entities
"""

import re
from typing import List, Dict, Tuple, Set
from collections import defaultdict
from nlp_preprocessing import NLPPreprocessor


class EntityRecognizer:
    """Custom NER for movie domain"""
    
    def __init__(self):
        self.preprocessor = NLPPreprocessor()
        
        # Movie genres (English)
        self.genres = {
            'action', 'adventure', 'animation', 'comedy', 'crime', 'documentary',
            'drama', 'family', 'fantasy', 'history', 'horror', 'music', 'mystery',
            'romance', 'scifi', 'sci-fi', 'science fiction', 'sport', 'thriller',
            'war', 'western'
        }
        
        # Vietnamese to English genre mapping
        self.genre_mapping = {
            'hành động': 'action',
            'hanh dong': 'action',
            'phiêu lưu': 'adventure',
            'phieu luu': 'adventure',
            'hoạt hình': 'animation',
            'hoat hinh': 'animation',
            'hài': 'comedy',
            'hai': 'comedy',
            'hài kịch': 'comedy',
            'tội phạm': 'crime',
            'toi pham': 'crime',
            'tài liệu': 'documentary',
            'tai lieu': 'documentary',
            'chính kịch': 'drama',
            'chinh kich': 'drama',
            'gia đình': 'family',
            'gia dinh': 'family',
            'viễn tưởng': 'fantasy',
            'vien tuong': 'fantasy',
            'lịch sử': 'history',
            'lich su': 'history',
            'kinh dị': 'horror',
            'kinh di': 'horror',
            'ma': 'horror',
            'âm nhạc': 'music',
            'am nhac': 'music',
            'bí ẩn': 'mystery',
            'bi an': 'mystery',
            'lãng mạn': 'romance',
            'lang man': 'romance',
            'tình cảm': 'romance',
            'tinh cam': 'romance',
            'khoa học viễn tưởng': 'scifi',
            'khoa hoc vien tuong': 'scifi',
            'thể thao': 'sport',
            'the thao': 'sport',
            'gay cấn': 'thriller',
            'gay can': 'thriller',
            'chiến tranh': 'war',
            'chien tranh': 'war',
            'cao bồi': 'western',
            'cao boi': 'western',
        }
        
        # Time-related keywords
        self.time_keywords = {
            'new', 'latest', 'recent', 'old', 'classic', 'vintage',
            'moi', 'moi nhat', 'cu', 'kinh dien'
        }
        
        # Rating-related keywords
        self.rating_keywords = {
            'best', 'top', 'worst', 'good', 'bad', 'excellent', 'poor',
            'hay', 'te', 'tot', 'xau', 'hay nhat', 'te nhat'
        }
        
        # Popularity keywords
        self.popularity_keywords = {
            'popular', 'trending', 'hot', 'viral', 'famous',
            'pho bien', 'noi tieng', 'hot'
        }
        
        # Common movie title patterns
        self.title_patterns = [
            r'\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b',  # Capitalized words
            r'\b(?:The|A|An)\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b',  # With articles
        ]
        
        # Famous people (actors/directors) - Expanded list
        self.famous_people = {
            # Hollywood Actors
            'tom cruise', 'leonardo dicaprio', 'brad pitt', 'robert downey jr',
            'scarlett johansson', 'jennifer lawrence', 'will smith',
            'dwayne johnson', 'chris hemsworth', 'chris evans', 'chris pratt',
            'tom holland', 'zendaya', 'margot robbie', 'emma stone',
            'ryan gosling', 'keanu reeves', 'johnny depp', 'angelina jolie',
            'natalie portman', 'anne hathaway', 'matt damon', 'mark wahlberg',
            'vin diesel', 'jason statham', 'gal gadot', 'brie larson',
            
            # Directors
            'christopher nolan', 'steven spielberg', 'quentin tarantino',
            'martin scorsese', 'james cameron', 'ridley scott', 'denis villeneuve',
            'wes anderson', 'guillermo del toro', 'peter jackson',
            'jj abrams', 'j.j. abrams', 'russo brothers', 'jon favreau',
            
            # Marvel/DC
            'robert downey', 'chris evans', 'chris hemsworth', 'mark ruffalo',
            'scarlett johansson', 'jeremy renner', 'paul rudd', 'benedict cumberbatch',
            'tom hiddleston', 'chadwick boseman', 'brie larson', 'tom holland',
            'ben affleck', 'henry cavill', 'gal gadot', 'jason momoa',
            
            # Vietnamese names (transliterated)
            'tran thanh', 'trấn thành', 'truong giang', 'trường giang',
            'ngo thanh van', 'ngô thanh vân', 'ly hai', 'lý hải'
        }
        
        # Common speech recognition errors mapping
        self.name_corrections = {
            'non': 'nolan',
            'chrystal non': 'christopher nolan',
            'crystal non': 'christopher nolan',
            'no lan': 'nolan',
            'tom crew': 'tom cruise',
            'tom cruz': 'tom cruise',
            'leo dicaprio': 'leonardo dicaprio',
            'leo di caprio': 'leonardo dicaprio',
            'robert downey': 'robert downey jr',
            'chris evan': 'chris evans',
            'chris hemsworth': 'chris hemsworth',
        }
    
    def extract_entities(self, text: str) -> Dict[str, List[str]]:
        """Extract all entities from text"""
        text_lower = text.lower()
        
        # Apply name corrections first
        for wrong, correct in self.name_corrections.items():
            if wrong in text_lower:
                text_lower = text_lower.replace(wrong, correct)
        
        entities = {
            'genres': [],
            'years': [],
            'titles': [],
            'people': [],
            'time_expressions': [],
            'rating_expressions': [],
            'popularity_expressions': []
        }
        
        # Extract genres (English)
        for genre in self.genres:
            if genre in text_lower:
                entities['genres'].append(genre)
        
        # Extract genres (Vietnamese → English)
        for viet_genre, eng_genre in self.genre_mapping.items():
            if viet_genre in text_lower:
                if eng_genre not in entities['genres']:
                    entities['genres'].append(eng_genre)
        
        # Extract years
        year_pattern = r'\b(19|20)\d{2}\b'
        years = re.findall(year_pattern, text)
        entities['years'] = list(set(years))
        
        # Extract time expressions
        for keyword in self.time_keywords:
            if keyword in text_lower:
                entities['time_expressions'].append(keyword)
        
        # Extract rating expressions
        for keyword in self.rating_keywords:
            if keyword in text_lower:
                entities['rating_expressions'].append(keyword)
        
        # Extract popularity expressions
        for keyword in self.popularity_keywords:
            if keyword in text_lower:
                entities['popularity_expressions'].append(keyword)
        
        # Extract people (actors/directors)
        for person in self.famous_people:
            if person in text_lower:
                entities['people'].append(person)
        
        # Fuzzy matching for people names (handle speech recognition errors)
        # Check if text contains "dao dien" (director) or "dien vien" (actor)
        if 'dao dien' in text_lower or 'đạo diễn' in text_lower or 'director' in text_lower:
            # Try to find director name after these keywords
            words = text_lower.split()
            for i, word in enumerate(words):
                if word in ['dao', 'đạo', 'director'] and i + 1 < len(words):
                    # Get next few words as potential name
                    potential_name = ' '.join(words[i+1:min(i+4, len(words))])
                    # Fuzzy match with famous directors
                    for person in self.famous_people:
                        if 'nolan' in person and ('nolan' in potential_name or 'non' in potential_name):
                            entities['people'].append('christopher nolan')
                            break
                        elif 'spielberg' in person and 'spielberg' in potential_name:
                            entities['people'].append('steven spielberg')
                            break
                        elif 'tarantino' in person and 'tarantino' in potential_name:
                            entities['people'].append('quentin tarantino')
                            break
        
        # Extract potential movie titles (capitalized sequences)
        for pattern in self.title_patterns:
            matches = re.findall(pattern, text)
            entities['titles'].extend(matches)
        
        return entities
    
    def extract_year_range(self, text: str) -> Tuple[int, int]:
        """Extract year range from text"""
        years = re.findall(r'\b(19|20)\d{2}\b', text)
        
        if not years:
            return None, None
        
        years = [int(y) for y in years]
        return min(years), max(years)
    
    def extract_genre_combinations(self, text: str) -> List[List[str]]:
        """Extract genre combinations (e.g., 'action comedy')"""
        text_lower = text.lower()
        found_genres = [g for g in self.genres if g in text_lower]
        
        if len(found_genres) > 1:
            return [found_genres]
        return []


class FeatureExtractor:
    """Extract features for NLP tasks"""
    
    def __init__(self):
        self.entity_recognizer = EntityRecognizer()
        self.preprocessor = NLPPreprocessor()
    
    def extract_search_features(self, text: str) -> Dict[str, any]:
        """Extract comprehensive search features"""
        # Basic preprocessing
        tokens = self.preprocessor.preprocess(text, remove_stopwords=False)
        clean_tokens = self.preprocessor.preprocess(text, remove_stopwords=True)
        
        # Entity recognition
        entities = self.entity_recognizer.extract_entities(text)
        
        # Extract n-grams
        bigrams = self.preprocessor.extract_ngrams(tokens, n=2)
        trigrams = self.preprocessor.extract_ngrams(tokens, n=3)
        
        # Word frequency
        word_freq = self.preprocessor.get_word_frequency(clean_tokens)
        
        # Year range
        year_min, year_max = self.entity_recognizer.extract_year_range(text)
        
        features = {
            'original_text': text,
            'tokens': tokens,
            'clean_tokens': clean_tokens,
            'bigrams': bigrams,
            'trigrams': trigrams,
            'word_frequency': word_freq,
            'entities': entities,
            'year_range': {
                'min': year_min,
                'max': year_max
            },
            'has_genre': len(entities['genres']) > 0,
            'has_year': len(entities['years']) > 0,
            'has_person': len(entities['people']) > 0,
            'has_time_expression': len(entities['time_expressions']) > 0,
            'has_rating_expression': len(entities['rating_expressions']) > 0,
            'has_popularity_expression': len(entities['popularity_expressions']) > 0,
            'token_count': len(tokens),
            'unique_token_count': len(set(tokens))
        }
        
        return features


class QueryAnalyzer:
    """Analyze and understand user queries"""
    
    def __init__(self):
        self.feature_extractor = FeatureExtractor()
        self.entity_recognizer = EntityRecognizer()
    
    def analyze_query(self, query: str) -> Dict[str, any]:
        """Comprehensive query analysis"""
        # Extract features
        features = self.feature_extractor.extract_search_features(query)
        
        # Determine query type
        query_type = self._determine_query_type(features)
        
        # Extract search parameters
        search_params = self._extract_search_parameters(features)
        
        # Generate search suggestions
        suggestions = self._generate_suggestions(features)
        
        # Calculate query complexity
        complexity = self._calculate_complexity(features)
        
        return {
            'query': query,
            'query_type': query_type,
            'search_parameters': search_params,
            'suggestions': suggestions,
            'complexity': complexity,
            'features': features
        }
    
    def _determine_query_type(self, features: Dict) -> str:
        """Determine the type of query"""
        entities = features['entities']
        
        if features['has_person']:
            return 'person_search'
        elif features['has_genre'] and features['has_year']:
            return 'genre_year_search'
        elif features['has_genre']:
            return 'genre_search'
        elif features['has_year']:
            return 'year_search'
        elif features['has_rating_expression']:
            return 'rating_search'
        elif features['has_popularity_expression']:
            return 'popularity_search'
        elif features['has_time_expression']:
            return 'time_based_search'
        elif len(entities['titles']) > 0:
            return 'title_search'
        else:
            return 'general_search'
    
    def _extract_search_parameters(self, features: Dict) -> Dict[str, any]:
        """Extract structured search parameters"""
        entities = features['entities']
        
        params = {
            'genres': entities['genres'],
            'years': entities['years'],
            'year_range': features['year_range'],
            'people': entities['people'],
            'titles': entities['titles'],
            'sort_by': None,
            'filters': {}
        }
        
        # Determine sort order
        if features['has_rating_expression']:
            params['sort_by'] = 'rating'
        elif features['has_popularity_expression']:
            params['sort_by'] = 'popularity'
        elif features['has_time_expression']:
            if any(word in features['clean_tokens'] for word in ['new', 'moi', 'latest', 'nhat']):
                params['sort_by'] = 'release_date_desc'
            else:
                params['sort_by'] = 'release_date_asc'
        
        # Add filters
        if params['year_range']['min']:
            params['filters']['year_min'] = params['year_range']['min']
        if params['year_range']['max']:
            params['filters']['year_max'] = params['year_range']['max']
        
        return params
    
    def _generate_suggestions(self, features: Dict) -> List[str]:
        """Generate search suggestions"""
        suggestions = []
        entities = features['entities']
        
        # Genre-based suggestions
        if entities['genres']:
            for genre in entities['genres'][:3]:
                suggestions.append(f"Top {genre} movies")
                suggestions.append(f"New {genre} releases")
        
        # Year-based suggestions
        if entities['years']:
            for year in entities['years'][:2]:
                suggestions.append(f"Best movies of {year}")
        
        # Person-based suggestions
        if entities['people']:
            for person in entities['people'][:2]:
                suggestions.append(f"Movies starring {person}")
        
        return suggestions[:5]  # Limit to 5 suggestions
    
    def _calculate_complexity(self, features: Dict) -> str:
        """Calculate query complexity"""
        score = 0
        
        # Add points for different features
        if features['has_genre']:
            score += 1
        if features['has_year']:
            score += 1
        if features['has_person']:
            score += 2
        if features['has_rating_expression']:
            score += 1
        if features['has_popularity_expression']:
            score += 1
        if len(features['entities']['titles']) > 0:
            score += 2
        
        if score <= 1:
            return 'simple'
        elif score <= 3:
            return 'moderate'
        else:
            return 'complex'


class SemanticMatcher:
    """Match queries to movie database using semantic understanding"""
    
    def __init__(self):
        self.query_analyzer = QueryAnalyzer()
        
        # Synonym mappings
        self.synonyms = {
            'movie': ['film', 'cinema', 'phim', 'picture'],
            'good': ['great', 'excellent', 'amazing', 'hay', 'tot'],
            'bad': ['poor', 'terrible', 'awful', 'te', 'xau'],
            'new': ['latest', 'recent', 'fresh', 'moi', 'moi nhat'],
            'old': ['classic', 'vintage', 'retro', 'cu', 'kinh dien'],
            'popular': ['trending', 'hot', 'viral', 'pho bien', 'noi tieng']
        }
    
    def expand_query(self, query: str) -> List[str]:
        """Expand query with synonyms"""
        analysis = self.query_analyzer.analyze_query(query)
        tokens = analysis['features']['clean_tokens']
        
        expanded_queries = [query]
        
        for token in tokens:
            if token in self.synonyms:
                for synonym in self.synonyms[token]:
                    expanded_query = query.replace(token, synonym)
                    expanded_queries.append(expanded_query)
        
        return expanded_queries[:5]  # Limit expansions
    
    def match_score(self, query: str, movie_data: Dict) -> float:
        """Calculate match score between query and movie"""
        analysis = self.query_analyzer.analyze_query(query)
        score = 0.0
        
        query_tokens = set(analysis['features']['clean_tokens'])
        entities = analysis['features']['entities']
        
        # Match title
        if 'title' in movie_data:
            title_tokens = set(self.query_analyzer.feature_extractor.preprocessor.preprocess(
                movie_data['title'], remove_stopwords=True
            ))
            title_overlap = len(query_tokens & title_tokens)
            score += title_overlap * 3.0
        
        # Match genres
        if 'genres' in movie_data and entities['genres']:
            movie_genres = set(g.lower() for g in movie_data['genres'])
            genre_overlap = len(set(entities['genres']) & movie_genres)
            score += genre_overlap * 2.0
        
        # Match year
        if 'year' in movie_data and entities['years']:
            if str(movie_data['year']) in entities['years']:
                score += 2.0
        
        # Match overview/description
        if 'overview' in movie_data:
            overview_tokens = set(self.query_analyzer.feature_extractor.preprocessor.preprocess(
                movie_data['overview'], remove_stopwords=True
            ))
            overview_overlap = len(query_tokens & overview_tokens)
            score += overview_overlap * 0.5
        
        return score


# Example usage
if __name__ == "__main__":
    analyzer = QueryAnalyzer()
    
    test_queries = [
        "Find action movies from 2024",
        "Tìm phim hài mới nhất",
        "Tom Cruise movies",
        "Best horror films",
        "Popular sci-fi movies"
    ]
    
    for query in test_queries:
        result = analyzer.analyze_query(query)
        print(f"\n{'='*60}")
        print(f"Query: {query}")
        print(f"Type: {result['query_type']}")
        print(f"Complexity: {result['complexity']}")
        print(f"Entities: {result['features']['entities']}")
        print(f"Search Parameters: {result['search_parameters']}")
        print(f"Suggestions: {result['suggestions']}")
