import numpy as np
import io
from PIL import Image
import logging
import tensorflow as tf
import time 

from app.machine_learning import model_loader
from app.machine_learning.label_info import disease_info, category_mapping

logger = logging.getLogger(__name__)

label_mapping = ['keriting', 'kuning', 'sehat'] 


def preprocess_image(img_content: bytes, target_size=(128, 128)):
    """
    Memproses konten gambar (bytes) menjadi array NumPy yang siap untuk model ML.
    Melakukan konversi ke RGB, resize, dan normalisasi.
    """
    start_time_preprocess = time.time() # <<< MULAI WAKTU UNTUK PREPROCESSING
    try:
        logger.info(f"preprocess_image dipanggil. Ukuran konten: {len(img_content)} bytes.")
        
        img_open_start = time.time()
        img = Image.open(io.BytesIO(img_content))
        logger.info(f"Gambar dibuka (PIL.Image.open) dalam: {time.time() - img_open_start:.4f} detik. Mode awal: {img.mode}, Ukuran: {img.size}")
        
        if img.mode != 'RGB':
            img_convert_start = time.time()
            logger.info(f"Mengkonversi gambar dari mode {img.mode} ke RGB.")
            img = img.convert('RGB')
            logger.info(f"Konversi mode dalam: {time.time() - img_convert_start:.4f} detik. Mode setelah konversi: {img.mode}")
        
        img_resize_start = time.time()
        img = img.resize(target_size)
        logger.info(f"Resize gambar dalam: {time.time() - img_resize_start:.4f} detik.")
        
        img_array_start = time.time()
        img_array = np.array(img) / 255.0
        logger.info(f"Konversi ke array dan normalisasi dalam: {time.time() - img_array_start:.4f} detik.")
        
        img_expand_start = time.time()
        img_array = np.expand_dims(img_array, axis=0)
        logger.info(f"Menambah dimensi batch dalam: {time.time() - img_expand_start:.4f} detik.")
        
        logger.info(f"Preprocessing total memakan: {time.time() - start_time_preprocess:.4f} detik. Shape akhir: {img_array.shape}, Dtype: {img_array.dtype}") # <<< LOG TOTAL PREPROCESSING
        return img_array
        
    except Exception as e:
        logger.error(f"Error dalam preprocessing gambar: {str(e)}", exc_info=True)
        raise ValueError(f"Gagal memproses gambar: {str(e)}")


async def predict_image(file_bytes: bytes):
    """
    Melakukan prediksi penyakit daun dari konten gambar (bytes).
    Menggunakan CNN untuk ekstraksi fitur dan SVM untuk klasifikasi akhir.
    """
    total_predict_time_start = time.time() # <<< MULAI WAKTU UNTUK FUNGSI PREDICT_IMAGE TOTAL
    try:
        logger.info(f"predict_image dipanggil. Tipe file_bytes: {type(file_bytes)}, Ukuran: {len(file_bytes)} bytes.")
        
        cnn_model, feature_extractor, svm_model = model_loader.get_models()
        
        # Preprocess gambar
        img_array = preprocess_image(file_bytes)
        
        # Ekstrak fitur menggunakan CNN
        extract_features_start = time.time() # <<< MULAI WAKTU UNTUK EKSTRAKSI FITUR CNN
        logger.info("Mengekstrak fitur dengan CNN...")
        features = feature_extractor.predict(img_array, verbose=0)
        logger.info(f"Ekstraksi fitur CNN selesai dalam: {time.time() - extract_features_start:.4f} detik. Shape awal: {features.shape}") # <<< LOG EKSTRAKSI FITUR CNN
        
        if features.ndim > 2:
            features_flatten_start = time.time()
            features = features.reshape(features.shape[0], -1)
            logger.info(f"Fitur diratakan untuk SVM dalam: {time.time() - features_flatten_start:.4f} detik. Shape: {features.shape}")

        # Prediksi menggunakan SVM
        svm_predict_start = time.time() # <<< MULAI WAKTU UNTUK PREDIKSI SVM
        logger.info("Melakukan prediksi dengan SVM...")
        prediction = svm_model.predict(features)
        
        # Penting: Jika SVM dilatih tanpa probability=True, predict_proba akan gagal.
        # Atau jika tidak ingin probabilitas, gunakan hanya svm_model.predict(features).
        probabilities = svm_model.predict_proba(features) 
        
        logger.info(f"Prediksi SVM selesai dalam: {time.time() - svm_predict_start:.4f} detik.") # <<< LOG PREDIKSI SVM
        
        predicted_class_idx = prediction[0]
        confidence = float(np.max(probabilities)) * 100 
        
        logger.info(f"Indeks Prediksi SVM: {predicted_class_idx}, Confidence: {confidence:.2f}%")
        
        if predicted_class_idx < len(label_mapping):
            predicted_label = label_mapping[predicted_class_idx]
        else:
            raise ValueError(f"Indeks prediksi SVM tidak valid: {predicted_class_idx}. Diluar batas label_mapping.")
        
        if predicted_label not in disease_info:
            raise ValueError(f"Label '{predicted_label}' tidak dikenal dalam disease_info.")
            
        disease_name = disease_info[predicted_label]['nama_penyakit']
        recommendation = disease_info[predicted_label]['rekomendasi']
        category = category_mapping[predicted_label]
        
        result = {
            "prediksi": predicted_label,
            "nama_penyakit": disease_name,
            "rekomendasi": recommendation,
            "kategori": category,
            "akurasi": confidence
        }
        
        logger.info(f"Hasil prediksi akhir: {result}")
        logger.info(f"Total predict_image function took: {time.time() - total_predict_time_start:.4f} seconds") # <<< LOG TOTAL WAKTU FUNGSI
        return result
        
    except Exception as e:
        logger.error(f"Error dalam fungsi prediksi: {str(e)}", exc_info=True)
        raise ValueError(f"Gagal melakukan prediksi gambar: {str(e)}")