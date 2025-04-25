from app import db



class User(db.Model):
    __tablename__ = 'Users'

    id_user = db.Column(db.Integer, primary_key=True)
    nama = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password = db.Column(db.String(100), nullable=False)
    role = db.Column(db.String(20),nullable=False)

    diagnosas = db.relationship('diagnosa', backref='Users', lazy=True)

class User(db.Model):
    __tablename__ = 'diagnosa'
    id_diagnosa =db.Column(db.Integer, primary_key=True)
    id_user = db.Column(db.Integer, db.ForeignKey('Users.id_user'))
    tanggal = db.Column(db.DateTime, nullable=False)
    jenis_penyakit = db.Column(db.String(100), nullable=False)
    image_path = db.Column(db.String(200), nullable=False)
    hasil = db.Column(db.String(100), nullable=False)
    akurasi = db.Column(db.Float)
    rekomendasi = db.Column(db.Text)
    solusi = db.Column(db.Text)
  
class GrafikDiagnosa(db.Model):
    __tablename__ = 'grafikdiagnosa'

    id = db.Column(db.Integer, primary_key=True)
    id_user = db.Column(db.Integer, db.ForeignKey('Users.id_user'), nullable=False)
    total_scan = db.Column(db.Integer)
    jumlah_sehat = db.Column(db.Integer)
    jumlah_kuning = db.Column(db.Integer)
    jumlah_keriting = db.Column(db.Integer)
    rentang_waktu = db.Column(db.String(100))