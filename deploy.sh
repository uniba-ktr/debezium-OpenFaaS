#!/bin/bash
DEB_STACK=${DEB_STACK:-"DEB"}
DB_STACK=${DB_STACK:-"DB"}
FUN_STACK=${FUN_STACK:-"FUN"}
MON_STACK=${MON_STACK:-"MON"}
LB_STACK=${LB_STACK:-"LB"}

networks=(streaming monitoring functions databases frontend)

# Start all networks for a stack deployment
function start_network() {
  for i in ${networks[@]}; do
    [[ -z `docker network ls -q --filter name=\^$i$` ]] && docker network create --attachable -d overlay $i && sleep 1
  done
  [[ -z `docker service ls -q --filter name=${LB_STACK}` ]] && docker stack deploy -c traefik.yml ${LB_STACK}
}

# Start Debezium Stack
function debezium() {
  start_network
  docker stack deploy -c debezium.yml ${DEB_STACK}
}

# Start Databases
function databases() {
  start_network
  docker stack deploy -c databases.yml ${DB_STACK}
}

# Start FAAS Gateway
function functions() {
  start_network
  docker stack deploy -c functions.yml ${FUN_STACK}
}

# Start Monitoring Stack
function monitor() {
  start_network
  docker stack deploy -c monitor.yml ${MON_STACK}
}

# Create all Stacks
function all() {
  start_network
  debezium
  databases
  functions
  monitor
}

# Method to be called, if all stacks are up and running
function connect() {
  cd functions
  faas-cli deploy -f db-stack.yml
  cd ..

  mysql_id=$(docker ps -q --filter "name=mysql")
  docker cp ${PWD}/sql/permission.sql ${mysql_id}:/permission.sql
  docker exec -it ${mysql_id} sh -c 'exec mysql -h"localhost" -P"3306" -u"root" -p"debezium" < /permission.sql'

    # Get container IP
  con_id=$(docker ps -q --filter "name=connect")

  echo "Setup Container ${con_id}\n"
  docker exec -it ${con_id} /bin/bash -c "curl -i -X POST -H \"Accept:application/json\" -H   \"Content-Type:application/json\" http://connect:8083/connectors/ -d '{ \"name\":   \"faas-connector\", \"config\": { \"connector.class\":   \"io.debezium.connector.mysql.MySqlConnector\", \"tasks.max\": \"1\", \"database.hostname\":   \"mysql\", \"database.port\": \"3306\", \"database.user\": \"debezium\", \"database.password\":   \"dbz\", \"database.server.id\": \"4711\", \"database.server.name\": \"dbserver\",   \"database.whitelist\": \"faas\", \"database.history.kafka.bootstrap.servers\":   \"kafka:9092\", \"database.history.kafka.topic\": \"dbhistory.faas\" } }'"

  echo "Setup Example Table\n"
  docker run -it --rm --network databases --volume ${PWD}/sql/table.sql:/table.sql mysql:5.7 sh -c 'exec mysql -h"mysql" -P"3306" -u"fun" -p"fun" faas < /table.sql'
  docker run -it --rm --network databases --volume ${PWD}/sql/table.sql:/table.sql --env PGPASSWORD=fun postgres sh -c 'exec psql -d faas -U fun -h postgres -a -f /table.sql'
}

# Stop and cleanup everything
function clean() {
  cd functions
  faas-cli remove -f db-stack.yml
  cd ..
  docker stack rm ${DEB_STACK} ${FUN_STACK} ${MON_STACK} ${DB_STACK} ${LB_STACK}
  docker network rm ${networks[*]}
}

function usage(){
cat << EOM
  usage:
  all          initialize all stacks without connect
  connect      if all services are running, this method connects everything
  clean        clean up everything
  ---------- Methods to initizialize single stacks ------------------------
  debezium     initialize debezium stack
  databases    initialize databases
  functions    initialize functions stack
  monitor      initialize Pormetheus and Grafana
EOM
}

if [ $# -eq 1 ]; then
  case "$1" in
    "debezium")    debezium;;
    "databases")   databases;;
    "connect")     connect;;
    "functions")   functions;;
    "monitor")     monitor;;
    "all")         all;;
    "clean")       clean;;
    *) usage;;
  esac
else
  usage
fi
exit 0

# Function calls:
#echo '{"table": "person", "values": {"id": 3, "first_name": "test", "last_name": "test"}}' | faas-cli invoke db-insert --content-type application/json
