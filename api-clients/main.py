import os
import pymysql
from app import app
from db_config import mysql
from flask import jsonify, request


import time

_last_db_check = 0.0
_last_db_status = False


@app.route('/', methods=['GET'])
def health():
	return jsonify({'status': 'ok', 'servicio': 'api-clientes'}), 200


@app.route('/health/live', methods=['GET'])
def health_live():
	return jsonify({'status': 'UP'}), 200


@app.route('/health/ready', methods=['GET'])
def health_ready():
	global _last_db_check, _last_db_status
	now = time.time()
	if now - _last_db_check < 3.0:
		if _last_db_status:
			return jsonify({'status': 'UP'}), 200
		return jsonify({'status': 'DOWN'}), 503

	conn = None
	try:
		conn = mysql.connect()
		with conn.cursor() as cursor:
			cursor.execute("SELECT 1")
		_last_db_status = True
		_last_db_check = now
		return jsonify({'status': 'UP'}), 200
	except Exception as e:
		print(f"[HealthCheck] Clients DB ping failed: {e}")
		_last_db_status = False
		_last_db_check = now
		return jsonify({'status': 'DOWN'}), 503
	finally:
		if conn:
			conn.close()


@app.route('/clientes', methods=['GET'])
def listar_clientes():
	conn = cursor = None
	try:
		conn = mysql.connect()
		cursor = conn.cursor(pymysql.cursors.DictCursor)
		cursor.execute("SELECT * FROM clientes")
		rows = cursor.fetchall()
		return jsonify(rows), 200
	except Exception as e:
		print(e)
		return jsonify({'error': 'Error al listar clientes'}), 500
	finally:
		if cursor: cursor.close()
		if conn: conn.close()


@app.route('/clientes/<int:id>', methods=['GET'])
def obtener_cliente(id):
	conn = cursor = None
	try:
		conn = mysql.connect()
		cursor = conn.cursor(pymysql.cursors.DictCursor)
		cursor.execute("SELECT * FROM clientes WHERE id = %s", (id,))
		row = cursor.fetchone()
		if not row:
			return jsonify({'error': 'Cliente no encontrado'}), 404
		return jsonify(row), 200
	except Exception as e:
		print(e)
		return jsonify({'error': 'Error al buscar el cliente'}), 500
	finally:
		if cursor: cursor.close()
		if conn: conn.close()


@app.route('/clientes', methods=['POST'])
def crear_cliente():
	conn = cursor = None
	try:
		data = request.get_json()
		nombre = data['nombre']
		email = data['email']
		dni = data.get('dni')
		conn = mysql.connect()
		cursor = conn.cursor()
		cursor.execute(
			"INSERT INTO clientes (nombre, email, dni) VALUES (%s, %s, %s)",
			(nombre, email, dni)
		)
		conn.commit()
		return jsonify({'id': cursor.lastrowid, 'nombre': nombre, 'email': email, 'dni': dni}), 201
	except Exception as e:
		print(e)
		return jsonify({'error': 'Error al crear el cliente'}), 500
	finally:
		if cursor: cursor.close()
		if conn: conn.close()


@app.route('/clientes/<int:id>', methods=['PUT'])
def actualizar_cliente(id):
	conn = cursor = None
	try:
		data = request.get_json()
		nombre = data['nombre']
		email = data['email']
		dni = data.get('dni')
		conn = mysql.connect()
		cursor = conn.cursor()
		cursor.execute(
			"UPDATE clientes SET nombre=%s, email=%s, dni=%s WHERE id=%s",
			(nombre, email, dni, id)
		)
		conn.commit()
		if cursor.rowcount == 0:
			return jsonify({'error': 'Cliente no encontrado'}), 404
		return jsonify({'id': id, 'nombre': nombre, 'email': email, 'dni': dni}), 200
	except Exception as e:
		print(e)
		return jsonify({'error': 'Error al actualizar el cliente'}), 500
	finally:
		if cursor: cursor.close()
		if conn: conn.close()


@app.route('/clientes/<int:id>', methods=['DELETE'])
def borrar_cliente(id):
	conn = cursor = None
	try:
		conn = mysql.connect()
		cursor = conn.cursor()
		cursor.execute("DELETE FROM clientes WHERE id=%s", (id,))
		conn.commit()
		if cursor.rowcount == 0:
			return jsonify({'error': 'Cliente no encontrado'}), 404
		return '', 204
	except Exception as e:
		print(e)
		return jsonify({'error': 'Error al borrar el cliente'}), 500
	finally:
		if cursor: cursor.close()
		if conn: conn.close()


if __name__ == "__main__":
	app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
