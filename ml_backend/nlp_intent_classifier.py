"""
Intent Classification Module
Implements Naive Bayes and SVM classifiers from scratch
"""

import math
import json
from collections import defaultdict, Counter
from typing import List, Dict, Tuple, Any
from nlp_preprocessing import NLPPreprocessor, TFIDFVectorizer


class NaiveBayesClassifier:
    """Naive Bayes classifier for intent classification"""
    
    def __init__(self):
        self.class_probs = {}  # P(class)
        self.word_probs = defaultdict(lambda: defaultdict(float))  # P(word|class)
        self.vocabulary = set()
        self.classes = set()
        
    def train(self, documents: List[List[str]], labels: List[str]):
        """Train Naive Bayes classifier"""
        # Count classes
        class_counts = Counter(labels)
        total_docs = len(labels)
        
        # Calculate P(class)
        for cls, count in class_counts.items():
            self.class_probs[cls] = count / total_docs
            self.classes.add(cls)
        
        # Count words per class
        word_counts_per_class = defaultdict(Counter)
        total_words_per_class = defaultdict(int)
        
        for doc, label in zip(documents, labels):
            for word in doc:
                self.vocabulary.add(word)
                word_counts_per_class[label][word] += 1
                total_words_per_class[label] += 1
        
        # Calculate P(word|class) with Laplace smoothing
        vocab_size = len(self.vocabulary)
        
        for cls in self.classes:
            for word in self.vocabulary:
                word_count = word_counts_per_class[cls][word]
                total_words = total_words_per_class[cls]
                # Laplace smoothing: (count + 1) / (total + vocab_size)
                self.word_probs[cls][word] = (word_count + 1) / (total_words + vocab_size)
    
    def predict(self, document: List[str]) -> Tuple[str, float]:
        """Predict class for document"""
        class_scores = {}
        
        for cls in self.classes:
            # Start with log probability of class
            score = math.log(self.class_probs[cls])
            
            # Add log probabilities of words
            for word in document:
                if word in self.vocabulary:
                    score += math.log(self.word_probs[cls][word])
            
            class_scores[cls] = score
        
        # Get class with highest score
        predicted_class = max(class_scores, key=class_scores.get)
        
        # Convert log probabilities to probabilities
        max_score = max(class_scores.values())
        exp_scores = {cls: math.exp(score - max_score) for cls, score in class_scores.items()}
        total = sum(exp_scores.values())
        confidence = exp_scores[predicted_class] / total
        
        return predicted_class, confidence
    
    def predict_proba(self, document: List[str]) -> Dict[str, float]:
        """Get probability distribution over classes"""
        class_scores = {}
        
        for cls in self.classes:
            score = math.log(self.class_probs[cls])
            for word in document:
                if word in self.vocabulary:
                    score += math.log(self.word_probs[cls][word])
            class_scores[cls] = score
        
        # Convert to probabilities
        max_score = max(class_scores.values())
        exp_scores = {cls: math.exp(score - max_score) for cls, score in class_scores.items()}
        total = sum(exp_scores.values())
        
        return {cls: exp_score / total for cls, exp_score in exp_scores.items()}


class SimpleSVM:
    """Simplified SVM using gradient descent"""
    
    def __init__(self, learning_rate: float = 0.001, lambda_param: float = 0.01, n_iterations: int = 1000):
        self.learning_rate = learning_rate
        self.lambda_param = lambda_param
        self.n_iterations = n_iterations
        self.weights = {}
        self.bias = {}
        self.classes = []
        
    def _create_feature_vector(self, document: List[str], vocabulary: List[str]) -> List[float]:
        """Create feature vector from document"""
        word_count = Counter(document)
        return [word_count.get(word, 0) for word in vocabulary]
    
    def train(self, documents: List[List[str]], labels: List[str]):
        """Train SVM using one-vs-rest approach"""
        # Build vocabulary
        vocabulary = sorted(set(word for doc in documents for word in doc))
        
        # Get unique classes
        self.classes = sorted(set(labels))
        
        # Convert documents to feature vectors
        X = [self._create_feature_vector(doc, vocabulary) for doc in documents]
        n_features = len(vocabulary)
        
        # Train one classifier per class
        for target_class in self.classes:
            # Create binary labels (1 for target class, -1 for others)
            y = [1 if label == target_class else -1 for label in labels]
            
            # Initialize weights
            weights = [0.0] * n_features
            bias = 0.0
            
            # Gradient descent
            for iteration in range(self.n_iterations):
                for i, x in enumerate(X):
                    # Calculate margin
                    margin = y[i] * (sum(w * xi for w, xi in zip(weights, x)) + bias)
                    
                    # Update weights
                    if margin < 1:
                        # Misclassified or within margin
                        for j in range(n_features):
                            weights[j] += self.learning_rate * (y[i] * x[j] - 2 * self.lambda_param * weights[j])
                        bias += self.learning_rate * y[i]
                    else:
                        # Correctly classified
                        for j in range(n_features):
                            weights[j] += self.learning_rate * (-2 * self.lambda_param * weights[j])
            
            self.weights[target_class] = weights
            self.bias[target_class] = bias
        
        self.vocabulary = vocabulary
    
    def predict(self, document: List[str]) -> Tuple[str, float]:
        """Predict class for document"""
        x = self._create_feature_vector(document, self.vocabulary)
        
        scores = {}
        for cls in self.classes:
            score = sum(w * xi for w, xi in zip(self.weights[cls], x)) + self.bias[cls]
            scores[cls] = score
        
        predicted_class = max(scores, key=scores.get)
        
        # Normalize scores to get confidence
        max_score = max(scores.values())
        min_score = min(scores.values())
        if max_score != min_score:
            confidence = (scores[predicted_class] - min_score) / (max_score - min_score)
        else:
            confidence = 1.0 / len(self.classes)
        
        return predicted_class, confidence


class IntentClassifier:
    """Main intent classifier combining multiple algorithms"""
    
    def __init__(self):
        self.preprocessor = NLPPreprocessor()
        self.naive_bayes = NaiveBayesClassifier()
        self.svm = SimpleSVM()
        self.trained = False
        
        # Define intents
        self.intent_definitions = {
            'search_by_title': {
                'keywords': ['find', 'search', 'look', 'tim', 'movie', 'film', 'phim'],
                'patterns': ['find * movie', 'search for *', 'tim phim *']
            },
            'search_by_genre': {
                'keywords': ['action', 'comedy', 'horror', 'romance', 'thriller', 'genre', 'the loai'],
                'patterns': ['* action *', '* comedy *', 'the loai *']
            },
            'search_by_year': {
                'keywords': ['year', 'nam', '2024', '2023', 'new', 'moi', 'latest', 'moi nhat'],
                'patterns': ['* year *', '* nam *', 'phim * 2024']
            },
            'search_popular': {
                'keywords': ['popular', 'trending', 'hot', 'pho bien', 'noi tieng'],
                'patterns': ['popular *', 'trending *', 'hot *']
            },
            'search_high_rating': {
                'keywords': ['best', 'top', 'rating', 'hay nhat', 'danh gia cao', 'good'],
                'patterns': ['best *', 'top *', 'hay nhat']
            },
            'search_similar': {
                'keywords': ['similar', 'like', 'tuong tu', 'giong', 'related'],
                'patterns': ['similar to *', 'like *', 'giong *']
            },
            'search_by_actor': {
                'keywords': ['actor', 'actress', 'dien vien', 'starring', 'cast'],
                'patterns': ['* actor *', 'dien vien *', 'starring *']
            }
        }
    
    def train_from_examples(self):
        """Train classifiers with example data"""
        # Training examples
        training_data = [
            # Search by title
            (['find', 'avenger', 'movie'], 'search_by_title'),
            (['search', 'spider', 'man'], 'search_by_title'),
            (['tim', 'phim', 'batman'], 'search_by_title'),
            (['look', 'iron', 'man'], 'search_by_title'),
            
            # Search by genre
            (['action', 'movie'], 'search_by_genre'),
            (['comedy', 'film'], 'search_by_genre'),
            (['horror', 'movie'], 'search_by_genre'),
            (['romance', 'phim'], 'search_by_genre'),
            (['thriller', 'movie'], 'search_by_genre'),
            
            # Search by year
            (['movie', '2024'], 'search_by_year'),
            (['new', 'movie'], 'search_by_year'),
            (['latest', 'film'], 'search_by_year'),
            (['phim', 'moi', 'nhat'], 'search_by_year'),
            (['movie', 'nam', '2023'], 'search_by_year'),
            
            # Search popular
            (['popular', 'movie'], 'search_popular'),
            (['trending', 'film'], 'search_popular'),
            (['hot', 'movie'], 'search_popular'),
            (['phim', 'pho', 'bien'], 'search_popular'),
            
            # Search high rating
            (['best', 'movie'], 'search_high_rating'),
            (['top', 'rated', 'film'], 'search_high_rating'),
            (['hay', 'nhat'], 'search_high_rating'),
            (['good', 'movie'], 'search_high_rating'),
            
            # Search similar
            (['similar', 'movie'], 'search_similar'),
            (['like', 'avenger'], 'search_similar'),
            (['tuong', 'tu'], 'search_similar'),
            (['giong', 'phim'], 'search_similar'),
            
            # Search by actor
            (['actor', 'tom', 'cruise'], 'search_by_actor'),
            (['dien', 'vien', 'brad', 'pitt'], 'search_by_actor'),
            (['starring', 'robert', 'downey'], 'search_by_actor'),
        ]
        
        documents = [doc for doc, _ in training_data]
        labels = [label for _, label in training_data]
        
        # Train both classifiers
        self.naive_bayes.train(documents, labels)
        self.svm.train(documents, labels)
        self.trained = True
    
    def classify_intent(self, text: str) -> Dict[str, Any]:
        """Classify intent of user query"""
        # Preprocess text
        tokens = self.preprocessor.preprocess(text)
        
        if not self.trained:
            self.train_from_examples()
        
        # Get predictions from both classifiers
        nb_intent, nb_confidence = self.naive_bayes.predict(tokens)
        svm_intent, svm_confidence = self.svm.predict(tokens)
        
        # Ensemble: average confidence
        if nb_intent == svm_intent:
            final_intent = nb_intent
            final_confidence = (nb_confidence + svm_confidence) / 2
        else:
            # Choose the one with higher confidence
            if nb_confidence > svm_confidence:
                final_intent = nb_intent
                final_confidence = nb_confidence
            else:
                final_intent = svm_intent
                final_confidence = svm_confidence
        
        # Rule-based fallback
        rule_based_intent = self._rule_based_classification(tokens)
        
        # If rule-based is confident, use it
        if rule_based_intent and final_confidence < 0.7:
            final_intent = rule_based_intent
            final_confidence = 0.8
        
        return {
            'intent': final_intent,
            'confidence': final_confidence,
            'naive_bayes': {'intent': nb_intent, 'confidence': nb_confidence},
            'svm': {'intent': svm_intent, 'confidence': svm_confidence},
            'rule_based': rule_based_intent,
            'tokens': tokens
        }
    
    def _rule_based_classification(self, tokens: List[str]) -> str:
        """Rule-based intent classification"""
        token_set = set(tokens)
        
        # Check for year patterns
        if any(token.isdigit() and len(token) == 4 for token in tokens):
            return 'search_by_year'
        
        # Check for genre keywords
        genre_keywords = {'action', 'comedy', 'horror', 'romance', 'thriller', 'drama', 'scifi'}
        if token_set & genre_keywords:
            return 'search_by_genre'
        
        # Check for popularity keywords
        popularity_keywords = {'popular', 'trending', 'hot', 'pho', 'bien'}
        if token_set & popularity_keywords:
            return 'search_popular'
        
        # Check for rating keywords
        rating_keywords = {'best', 'top', 'hay', 'nhat', 'good', 'great'}
        if token_set & rating_keywords:
            return 'search_high_rating'
        
        # Check for similarity keywords
        similarity_keywords = {'similar', 'like', 'tuong', 'tu', 'giong'}
        if token_set & similarity_keywords:
            return 'search_similar'
        
        # Check for actor keywords
        actor_keywords = {'actor', 'actress', 'dien', 'vien', 'starring', 'cast'}
        if token_set & actor_keywords:
            return 'search_by_actor'
        
        # Default to title search
        return 'search_by_title'
    
    def save_model(self, filepath: str):
        """Save trained model"""
        model_data = {
            'naive_bayes': {
                'class_probs': self.naive_bayes.class_probs,
                'word_probs': dict(self.naive_bayes.word_probs),
                'vocabulary': list(self.naive_bayes.vocabulary),
                'classes': list(self.naive_bayes.classes)
            },
            'svm': {
                'weights': self.svm.weights,
                'bias': self.svm.bias,
                'classes': self.svm.classes,
                'vocabulary': self.svm.vocabulary if hasattr(self.svm, 'vocabulary') else []
            }
        }
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(model_data, f, ensure_ascii=False, indent=2)
    
    def load_model(self, filepath: str):
        """Load trained model"""
        with open(filepath, 'r', encoding='utf-8') as f:
            model_data = json.load(f)
        
        # Load Naive Bayes
        self.naive_bayes.class_probs = model_data['naive_bayes']['class_probs']
        self.naive_bayes.word_probs = defaultdict(lambda: defaultdict(float), model_data['naive_bayes']['word_probs'])
        self.naive_bayes.vocabulary = set(model_data['naive_bayes']['vocabulary'])
        self.naive_bayes.classes = set(model_data['naive_bayes']['classes'])
        
        # Load SVM
        self.svm.weights = model_data['svm']['weights']
        self.svm.bias = model_data['svm']['bias']
        self.svm.classes = model_data['svm']['classes']
        self.svm.vocabulary = model_data['svm']['vocabulary']
        
        self.trained = True


# Example usage
if __name__ == "__main__":
    classifier = IntentClassifier()
    
    # Test queries
    test_queries = [
        "Tìm phim hành động mới nhất",
        "Find action movies",
        "Popular movies 2024",
        "Best comedy films",
        "Movies similar to Avengers",
        "Tom Cruise movies"
    ]
    
    for query in test_queries:
        result = classifier.classify_intent(query)
        print(f"\nQuery: {query}")
        print(f"Intent: {result['intent']} (confidence: {result['confidence']:.2f})")
        print(f"Tokens: {result['tokens']}")
