# app/machine_learning/model_loader.py (Tambahkan debugging GPU)
import os
import logging
from tensorflow.keras.models import load_model, Model
import joblib
import tensorflow as tf # PENTING: Pastikan ini diimpor jika menggunakan tf.config

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

cnn_model = None
feature_extractor = None
svm_model = None

def load_models():
    """Memuat model CNN dan SVM dari file."""
    global cnn_model, feature_extractor, svm_model
    
    try:
        # Debugging GPU
        gpus = tf.config.list_physical_devices('GPU')
        if gpus:
            logger.info(f"GPU terdeteksi: {gpus}")
            # Opsional: Atur alokasi memori GPU jika perlu
            # for gpu in gpus:
            #     tf.config.experimental.set_memory_growth(gpu, True)
        else:
            logger.info("Tidak ada GPU terdeteksi, TensorFlow akan menggunakan CPU.")

        # Path ke model
        base_dir = os.path.dirname(os.path.abspath(__file__))
        cnn_model_path = os.path.join(base_dir, "BestModel.h5")
        svm_model_path = os.path.join(base_dir, "svm_model.pkl")
        
        if not os.path.exists(cnn_model_path):
            logger.error(f"CNN model tidak ditemukan di: {cnn_model_path}")
            raise FileNotFoundError(f"CNN model tidak ditemukan di: {cnn_model_path}")
        if not os.path.exists(svm_model_path):
            logger.error(f"SVM model tidak ditemukan di: {svm_model_path}")
            raise FileNotFoundError(f"SVM model tidak ditemukan di: {svm_model_path}")
        
        # Load CNN model
        logger.info("Loading CNN model...")
        cnn_model = load_model(cnn_model_path, compile=False)
        logger.info(f"CNN model loaded. Input shape: {cnn_model.input_shape}")
        
        feature_layer_name = None
        for layer in reversed(cnn_model.layers):
            if 'dense' in layer.name.lower() and layer != cnn_model.layers[-1]:
                feature_layer_name = layer.name
                break
        
        if feature_layer_name is None:
            if len(cnn_model.layers) >= 2:
                feature_layer_name = cnn_model.layers[-2].name
            else:
                raise ValueError("Tidak dapat menemukan layer ekstraksi fitur yang cocok.")
            
        logger.info(f"Menggunakan layer fitur: {feature_layer_name}")
        
        feature_extractor = Model(
            inputs=cnn_model.inputs,
            outputs=cnn_model.get_layer(feature_layer_name).output
        )
        
        # Load SVM model
        logger.info("Loading SVM model...")
        svm_model = joblib.load(svm_model_path)
        logger.info(f"SVM model loaded. Classes: {svm_model.classes_}")
        
        logger.info("Semua model berhasil dimuat!")
        
    except Exception as e:
        logger.error(f"Error memuat model: {str(e)}", exc_info=True)
        raise

def get_models():
    """Mengembalikan model yang sudah dimuat. Memastikan model sudah dimuat terlebih dahulu."""
    if cnn_model is None or feature_extractor is None or svm_model is None:
        raise RuntimeError("Model belum dimuat. Panggil load_models() terlebih dahulu.")
    return cnn_model, feature_extractor, svm_model