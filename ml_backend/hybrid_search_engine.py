"""
Hybrid Movie Search Engine
Tang 1: BiLSTM + Attention (Intent Classification)
Tang 2: Hybrid Search (TF-IDF + SBERT)
"""

import os
import pandas as pd
import torch
import numpy as np
import re
import time
import warnings
from typing import List, Dict, Tuple, Optional
from pathlib import Path

warnings.filterwarnings('ignore')

# Import libraries for Tang 1 (BiLSTM + Attention)
try:
    import tensorflow as tf
    from tensorflow.keras.models import Model
    from tensorflow.keras.layers import Input, Embedding, Bidirectional, LSTM, Dense, Layer
    from tensorflow.keras import backend as K
    from tensorflow.keras.preprocessing.text import Tokenizer
    from tensorflow.keras.preprocessing.sequence import pad_sequences
    from sklearn.model_selection import train_test_split
    TENSORFLOW_AVAILABLE = True
except ImportError:
    TENSORFLOW_AVAILABLE = False
    print("⚠️ TensorFlow not available. BiLSTM features will be disabled.")

# Import libraries for Tang 2 (Hybrid Search)
try:
    from sentence_transformers import SentenceTransformer, util
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.metrics.pairwise import cosine_similarity
    SENTENCE_TRANSFORMERS_AVAILABLE = True
except ImportError:
    SENTENCE_TRANSFORMERS_AVAILABLE = False
    print("⚠️ sentence-transformers not available. SBERT features will be disabled.")

try:
    from googletrans import Translator
    TRANSLATOR_AVAILABLE = True
except ImportError:
    TRANSLATOR_AVAILABLE = False
    print("⚠️ googletrans not available. Translation will be disabled.")


# ==============================
# Helper Functions
# ==============================

def clean_text(text):
    """Clean text for processing"""
    text = str(text).lower()
    text = re.sub(r'[^a-z0-9\s]', ' ', text)
    text = re.sub(r'\s+', ' ', text)
    return text.strip()


# ==============================
# Self-Attention Layer (Tang 1)
# ==============================

if TENSORFLOW_AVAILABLE:
    class SelfAttention(Layer):
        def __init__(self, **kwargs):
            super(SelfAttention, self).__init__(**kwargs)
        
        def build(self, input_shape):
            self.W = self.add_weight(
                name="att_weight",
                shape=(input_shape[-1], 1),
                initializer="glorot_uniform",
                trainable=True
            )
            self.b = self.add_weight(
                name="att_bias",
                shape=(input_shape[1], 1),
                initializer="zeros",
                trainable=True
            )
            super(SelfAttention, self).build(input_shape)
        
        def call(self, x):
            e = K.tanh(K.dot(x, self.W) + self.b)
            a = K.softmax(e, axis=1)
            output = K.sum(x * a, axis=1)
            return output
        
        def compute_output_shape(self, input_shape):
            return (input_shape[0], input_shape[-1])


# ==============================
# Hybrid Search Engine Class
# ==============================

class HybridSearchEngine:
    """
    Hybrid Movie Search Engine
    - Tang 1: BiLSTM + Attention for intent classification
    - Tang 2: Hybrid search (TF-IDF + SBERT)
    """
    
    def __init__(self, data_dir: str = "data"):
        self.data_dir = Path(data_dir)
        self.data_dir.mkdir(exist_ok=True)
        
        # Initialize components
        self.df = None
        self.tfidf_vectorizer = None
        self.tfidf_matrix = None
        self.sbert_model = None
        self.movie_embeddings = None
        self.intent_classifier = None
        self.tokenizer = None
        self.translator = None
        
        # Configuration
        self.MAX_VOCAB_SIZE = 10000
        self.MAX_LEN = 30
        self.EMBEDDING_DIM = 128
        
        # Device
        self.device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
        print(f"🔧 Using device: {self.device}")
        
        # Initialize translator
        if TRANSLATOR_AVAILABLE:
            try:
                self.translator = Translator()
            except:
                self.translator = None
    
    def load_dataset(self, dataset_path: Optional[str] = None):
        """Load movie dataset"""
        if dataset_path is None:
            dataset_path = self.data_dir / "rotten_tomatoes_ENRICHED.csv"
        
        if not os.path.exists(dataset_path):
            raise FileNotFoundError(
                f"Dataset not found at {dataset_path}\n"
                f"Please download the dataset and place it in the data directory."
            )
        
        print(f"📂 Loading dataset from: {dataset_path}")
        self.df = pd.read_csv(dataset_path)
        
        # Clean data
        self.df['keywords'] = self.df['keywords'].fillna("")
        self.df['genres'] = self.df['genres'].fillna("")
        self.df = self.df.dropna(subset=['movie_title', 'movie_info']).reset_index(drop=True)
        
        # Clean text fields
        print("🧹 Cleaning data...")
        self.df['movie_title'] = self.df['movie_title'].apply(clean_text)
        self.df['movie_info'] = self.df['movie_info'].apply(clean_text)
        self.df['genres'] = self.df['genres'].apply(clean_text)
        self.df['keywords'] = self.df['keywords'].apply(clean_text)
        
        # Prepare combined fields
        self.df['combined_tfidf'] = (
            (self.df['movie_title'] + " ") * 20 +
            (self.df['keywords'] + " ") * 3 +
            (self.df['genres'] + " ") * 2 +
            self.df['movie_info']
        )
        
        self.df['combined_sbert'] = self.df.apply(
            lambda row: f"Title: {row['movie_title']}. Genres: {row['genres']}. "
                       f"Keywords: {row['keywords']}. Plot: {row['movie_info']}",
            axis=1
        )
        
        print(f"✅ Loaded {len(self.df)} movies")
        return self.df
    
    def initialize_tfidf(self):
        """Initialize TF-IDF pipeline"""
        if self.df is None:
            raise ValueError("Dataset not loaded. Call load_dataset() first.")
        
        if not SENTENCE_TRANSFORMERS_AVAILABLE:
            raise ImportError("sentence-transformers not available")
        
        print("🔧 Initializing TF-IDF pipeline...")
        self.tfidf_vectorizer = TfidfVectorizer(stop_words='english', max_features=20000)
        self.tfidf_matrix = self.tfidf_vectorizer.fit_transform(self.df['combined_tfidf'])
        print(f"✅ TF-IDF matrix shape: {self.tfidf_matrix.shape}")
    
    def initialize_sbert(self, model_name: str = "all-mpnet-base-v2"):
        """Initialize SBERT pipeline"""
        if self.df is None:
            raise ValueError("Dataset not loaded. Call load_dataset() first.")
        
        if not SENTENCE_TRANSFORMERS_AVAILABLE:
            raise ImportError("sentence-transformers not available")
        
        print(f"🔧 Initializing SBERT pipeline ({model_name})...")
        self.sbert_model = SentenceTransformer(model_name)
        
        # Load or create embeddings
        emb_path = self.data_dir / "movie_embeddings_ENRICHED.pt"
        
        if emb_path.exists():
            print(f"📂 Loading cached embeddings from: {emb_path}")
            self.movie_embeddings = torch.load(emb_path, map_location=self.device)
        else:
            print("🔄 Creating embeddings (this may take a while)...")
            self.movie_embeddings = self.sbert_model.encode(
                self.df['combined_sbert'].tolist(),
                convert_to_tensor=True,
                show_progress_bar=True
            )
            torch.save(self.movie_embeddings.cpu(), emb_path)
            print(f"✅ Saved embeddings to: {emb_path}")
        
        # Move to device
        self.sbert_model.to(self.device)
        self.movie_embeddings = self.movie_embeddings.to(self.device)
        print(f"✅ SBERT initialized on {self.device}")
    
    def train_intent_classifier(self, n_samples: int = 2000):
        """Train BiLSTM + Attention intent classifier"""
        if self.df is None:
            raise ValueError("Dataset not loaded. Call load_dataset() first.")
        
        if not TENSORFLOW_AVAILABLE:
            raise ImportError("TensorFlow not available")
        
        print("🎓 Training intent classifier (BiLSTM + Attention)...")
        
        # Create training data
        intent_df_auto = pd.DataFrame()
        
        # Label 0: INTENT_FIND_TITLE
        titles_df = pd.DataFrame()
        titles_df['text'] = self.df['movie_title'].dropna().sample(
            n_samples, random_state=42, replace=True
        )
        titles_df['label'] = 0
        
        # Label 1: INTENT_FIND_PLOT
        plots_df = pd.DataFrame()
        plots_df['text'] = self.df['movie_info'].dropna().apply(
            lambda x: " ".join(x.split()[:20])
        ).sample(n_samples, random_state=42, replace=True)
        plots_df['label'] = 1
        
        # Label 2: INTENT_FIND_CATEGORY
        category_df = pd.DataFrame()
        category_text = (self.df['genres'] + " " + self.df['keywords'])
        category_df['text'] = category_text.dropna().apply(
            lambda x: " ".join(x.split()[:20])
        ).sample(n_samples, random_state=42, replace=True)
        category_df['label'] = 2
        
        # Combine
        intent_df_auto = pd.concat([titles_df, plots_df, category_df])
        
        # Manual examples
        train_data_manual = [
            ("a hero in a red suit of armor", 1),
            ("boy bitten by a spider becomes superhero", 1),
            ("a man living in a fake town broadcast live", 1),
            ("movies about time travel", 2),
            ("best comedy films", 2),
            ("action movies with tom cruise", 2),
            ("horror movies", 2),
        ]
        
        manual_df = pd.DataFrame(train_data_manual, columns=['text_original', 'label'])
        
        # Translate manual examples if needed
        if self.translator:
            translated_texts = []
            for text in manual_df['text_original']:
                try:
                    if self.translator.detect(text).lang != 'en':
                        translated_texts.append(
                            self.translator.translate(text, dest='en').text
                        )
                    else:
                        translated_texts.append(text)
                except:
                    translated_texts.append(text)
            manual_df['text'] = [clean_text(t) for t in translated_texts]
        else:
            manual_df['text'] = manual_df['text_original'].apply(clean_text)
        
        # Combine all
        intent_df = pd.concat([
            intent_df_auto[['text', 'label']],
            manual_df[['text', 'label']]
        ])
        
        intent_df = intent_df.sample(frac=1, random_state=42).reset_index(drop=True)
        intent_df = intent_df[intent_df['text'].str.len() > 0]
        
        print(f"📊 Training data: {len(intent_df)} samples")
        
        # Build tokenizer
        self.tokenizer = Tokenizer(num_words=self.MAX_VOCAB_SIZE, oov_token="<OOV>")
        self.tokenizer.fit_on_texts(intent_df['text'])
        vocab_size = len(self.tokenizer.word_index) + 1
        
        # Build model
        input_layer = Input(shape=(self.MAX_LEN,))
        embedding_layer = Embedding(
            input_dim=vocab_size,
            output_dim=self.EMBEDDING_DIM,
            input_length=self.MAX_LEN
        )(input_layer)
        bilstm_layer = Bidirectional(LSTM(64, return_sequences=True))(embedding_layer)
        attention_layer = SelfAttention()(bilstm_layer)
        dense_layer = Dense(32, activation='relu')(attention_layer)
        output_layer = Dense(3, activation='softmax')(dense_layer)
        
        self.intent_classifier = Model(inputs=input_layer, outputs=output_layer)
        self.intent_classifier.compile(
            loss='sparse_categorical_crossentropy',
            optimizer='adam',
            metrics=['accuracy']
        )
        
        # Prepare data
        X = self.tokenizer.texts_to_sequences(intent_df['text'])
        X = pad_sequences(X, maxlen=self.MAX_LEN, padding='post', truncating='post')
        y = intent_df['label'].values
        
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
        
        # Train
        self.intent_classifier.fit(
            X_train, y_train,
            epochs=5,
            batch_size=32,
            validation_data=(X_test, y_test),
            verbose=1
        )
        
        # Save model
        model_path = self.data_dir / "intent_classifier.h5"
        self.intent_classifier.save(model_path)
        print(f"✅ Intent classifier saved to: {model_path}")
    
    def load_intent_classifier(self, model_path: Optional[str] = None):
        """Load pre-trained intent classifier"""
        if not TENSORFLOW_AVAILABLE:
            raise ImportError("TensorFlow not available")
        
        if model_path is None:
            model_path = self.data_dir / "intent_classifier.h5"
        
        if not os.path.exists(model_path):
            raise FileNotFoundError(
                f"Intent classifier not found at {model_path}\n"
                f"Please train the model first using train_intent_classifier()"
            )
        
        print(f"📂 Loading intent classifier from: {model_path}")
        self.intent_classifier = tf.keras.models.load_model(
            model_path,
            custom_objects={'SelfAttention': SelfAttention}
        )
        
        # Load tokenizer (need to rebuild from training data)
        # For now, we'll need to retrain or save tokenizer separately
        print("⚠️ Note: Tokenizer needs to be rebuilt. Please ensure training data is available.")
    
    def search_hybrid(self, query: str, top_k: int = 5) -> List[Dict]:
        """
        Hybrid search with BiLSTM intent classification
        
        Returns:
            List of movie results with scores
        """
        start_time = time.time()
        
        # Step 1: Translate if needed
        query_to_search = query
        if self.translator:
            try:
                detected_lang = self.translator.detect(query).lang.lower()
                if detected_lang != 'en':
                    translated = self.translator.translate(query, dest='en')
                    query_to_search = translated.text
                    print(f"🌐 Translated: '{query}' -> '{query_to_search}'")
            except Exception as e:
                print(f"⚠️ Translation error: {e}")
        
        # Step 2: Intent classification (Tang 1)
        intent_label = 1  # Default to PLOT
        intent_name = "PLOT"
        alpha = 0.8  # Default alpha
        
        if self.intent_classifier and self.tokenizer:
            try:
                seq = self.tokenizer.texts_to_sequences([clean_text(query_to_search)])
                pad_seq = pad_sequences(seq, maxlen=self.MAX_LEN, padding='post', truncating='post')
                prediction = self.intent_classifier.predict(pad_seq, verbose=0)[0]
                intent_label = np.argmax(prediction)
                
                if intent_label == 0:  # TITLE
                    alpha = 0.05
                    intent_name = "TITLE"
                elif intent_label == 1:  # PLOT
                    alpha = 0.8
                    intent_name = "PLOT"
                else:  # CATEGORY
                    alpha = 0.9
                    intent_name = "CATEGORY"
                
                print(f"🎯 Intent: {intent_name} (confidence: {prediction[intent_label]:.2f}, alpha: {alpha})")
            except Exception as e:
                print(f"⚠️ Intent classification error: {e}")
        
        # Step 3: Calculate scores (Tang 2)
        results = []
        
        if self.sbert_model and self.movie_embeddings is not None:
            query_emb = self.sbert_model.encode(query_to_search, convert_to_tensor=True)
            sbert_scores = util.cos_sim(query_emb, self.movie_embeddings)[0]
            sbert_scores = sbert_scores.cpu()
        else:
            sbert_scores = torch.zeros(len(self.df))
        
        if self.tfidf_vectorizer and self.tfidf_matrix is not None:
            query_clean = clean_text(query_to_search)
            query_vec = self.tfidf_vectorizer.transform([query_clean])
            tfidf_scores = cosine_similarity(query_vec, self.tfidf_matrix).flatten()
            tfidf_scores_tensor = torch.from_numpy(tfidf_scores).float()
        else:
            tfidf_scores_tensor = torch.zeros(len(self.df))
        
        # Step 4: Combine scores
        final_scores = (alpha * sbert_scores) + ((1 - alpha) * tfidf_scores_tensor)
        top_results = torch.topk(final_scores, k=min(top_k, len(self.df)))
        
        # Step 5: Format results
        for score, idx in zip(top_results.values, top_results.indices):
            movie = self.df.iloc[idx.item()]
            results.append({
                'movie_title': movie['movie_title'],
                'genres': movie['genres'],
                'keywords': movie['keywords'],
                'plot': movie['movie_info'],
                'score': float(score.item()),
                'intent': intent_name,
                'alpha': alpha
            })
        
        elapsed_time = (time.time() - start_time) * 1000
        print(f"⏱️ Search completed in {elapsed_time:.2f}ms")
        
        return results





