import os, sys, json, requests

database=os.getenv('DB', 'postgres')
gateway_hostname=os.getenv("gateway_hostname", "gateway")
prest_hostname=os.getenv("prest_hostname", "prest")
default_db=os.getenv("default_db", "faas")

def handle(req):
    """handle a request to the function
    Args:
        req (str): request body
    """

    json_req = json.loads(req)
    table = json_req['table']
    values = json_req['values']

    print ("Deleting %s values %s" % (table, str(values)))
    entries = delete_db(table, values)

    return entries


def delete_db(table, values):
    db_url = "http://" + prest_hostname + ":3000/" + default_db + "/public/" + table +"?id=" + str(values['id'])
    print (db_url)
    r = requests.delete(db_url)

    if r.status_code != 200:
        sys.exit("Error with update-db, expected: %d, got: %d\n content: %s" % (201, r.status_code, r.content))
    return r.content.decode('utf-8')
