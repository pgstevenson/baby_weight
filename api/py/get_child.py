#!/usr/bin/env python3

@app.route('/api/v1/child', methods=['GET'])
def child_v1():

    conn = None

    try:
        params = config()
        conn = psycopg2.connect(**params)
        cur = conn.cursor(cursor_factory = psycopg2.extras.DictCursor)
        cur.execute("""SELECT * FROM children WHERE id={};""".format(request.args['id']))
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
