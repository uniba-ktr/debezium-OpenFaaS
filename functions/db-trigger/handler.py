import os, sys, json, requests

gateway_hostname=os.getenv("gateway_hostname", "gateway")

def handle(req):
    """handle a request to the function
    Args:
        req (str): request body
    """
    jsonreq=json.loads(req)

    if jsonreq['value']['payload'] is None:
        return

    if 'before' in jsonreq['value']['payload']:
        before=jsonreq['value']['payload']['before']

    if 'after' in jsonreq['value']['payload']:
        after=jsonreq['value']['payload']['after']

    source=jsonreq['value']['payload']['source']

    if before is not None and after is not None:
        result = db_update({'table': source['table'], 'values': after})
    elif after is not None:
        result = db_insert({'table': source['table'], 'values': after})
    elif before is not None:
        result = db_delete({'table': source['table'], 'values': before})

    return result

def db_insert(json_req):
    print ("Inserting %s\n" % str(json_req))
    r = requests.get("http://" + gateway_hostname + ":8080/function/db-insert", data=json.dumps(json_req))

    if r.status_code != 200:
        sys.exit("Error with db-insert, expected: %d, got: %d\n" % (200, r.status_code))
    return r.content.decode(r.encoding).rstrip("\n")

def db_update(json_req):
    print ("Updating %s\n" % str(json_req))
    r = requests.get("http://" + gateway_hostname + ":8080/function/db-update", data=json.dumps(json_req))

    if r.status_code != 200:
        sys.exit("Error with db-update, expected: %d, got: %d\n" % (200, r.status_code))
    return r.content.decode(r.encoding).rstrip("\n")

def db_delete(json_req):
    print ("Deleting %s\n" % str(json_req))
    r = requests.get("http://" + gateway_hostname + ":8080/function/db-delete", data=json.dumps(json_req))

    if r.status_code != 200:
        sys.exit("Error with db-delete, expected: %d, got: %d\n" % (200, r.status_code))
    return r.content.decode(r.encoding).rstrip("\n")
