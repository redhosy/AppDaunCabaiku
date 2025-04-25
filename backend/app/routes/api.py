from flask import Blueprint, jsonify
from app.models import Users
from app import db

main = Blueprint('main', __name__)

@main.route('/users')
def get_users():
    users = User.query.all()
    return jsonify([
        {
            'id_user': user.id_user,
            'nama': user.nama,
            'email': user.email,
            'password': user.password,
            'role': user.role
        }
    for user in users])