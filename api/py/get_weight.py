#!/usr/bin/env python3

@app.route('/api/v1/weight', methods=['GET'])
def weight_v1():

    conn = None

    try:
        params = config()
        conn = psycopg2.connect(**params)
        cur = conn.cursor(cursor_factory = psycopg2.extras.DictCursor)
        cur.execute("""SELECT * FROM weights WHERE child_id={};""".format(request.args['child_id']))
        ans = cur.fetchall()
        if (len(ans) == 0):
            return jsonify({'code':204, 'name':'No content', 'key':''})
        ans1 = []
        for row in ans:
            ans1.append(dict(row))
        return jsonify(ans1)
    except (Exception, psycopg2.DatabaseError) as error:
        return str(error)
    finally:
        if conn is not None:
            conn.close()
