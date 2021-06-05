#!/usr/bin/env python3

@app.route('/api/v1/insert_weight', methods=['GET'])
def insert_weight_v1():

    conn = None

    try:
        params = config()
        conn = psycopg2.connect(**params)
        cur = conn.cursor(cursor_factory = psycopg2.extras.DictCursor)
        cur.execute("""INSERT INTO weights (child_id, weight, weight_date) VALUES ({}, {}, {});""".format(request.args['id'], request.args['weight'], request.args['date']))
        conn.commit()
        return jsonify([{'code':201}])
    except (Exception, psycopg2.DatabaseError) as error:
        return str(error)
    finally:
        if conn is not None:
            conn.close()
