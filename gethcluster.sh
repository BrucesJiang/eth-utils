# !/bin/bash
# bash cluster <root> <network_id> <number_of_nodes>  <runid> <local_IP> [[params]...]
# https://github.com/ethereum/go-ethereum/wiki/Setting-up-monitoring-on-local-cluster

# sets up a local ethereum network cluster of nodes
# - <number_of_nodes> is the number of nodes in cluster
# - <root> is the root directory for the cluster, the nodes are set up
#   with datadir `<root>/<network_id>/00`, `<root>/ <network_id>/01`, ...
# - new accounts are created for each node
# - they launch on port 30300, 30301, ...
# - they star rpc on port 8100, 8101, ...
# - by collecting the nodes nodeUrl, they get connected to each other
# - if enode has no IP, `<local_IP>` is substituted
# - if `<network_id>` is not 0, they will not connect to a default client,
#   resulting in a private isolated network
# - the nodes log into `<root>/00.<runid>.log`, `<root>/01.<runid>.log`, ...
# - The nodes launch in mining mode
# - the cluster can be killed with `killall geth` (FIXME: should record PIDs)
#   and restarted from the same state
# - if you want to interact with the nodes, use rpc
# - you can supply additional params on the command line which will be passed
#   to each node, for instance `-mine`

ROOT=$1
echo "ROOT = $ROOT"
N=$2
echo "N = $N"
NETWORK_ID=$3
echo "NETWORK_ID = $NETWORK_ID"
DIR=$ROOT/$NETWORK_ID
RUNID=$4
echo "RUNID = $RUNID"
IP_ADDR=$5
echo "IP_ADDR = $IP_ADDR"
mkdir -p $DIR/data
mkdir -p $DIR/log
# GETH=geth

if [ ! -f "$DIR/nodes"  ]; then

  echo "[" >> $DIR/nodes
  for ((i=0;i<N;++i)); do
    id=`printf "%02d" $i`
    if [ ! $IP_ADDR="" ]; then
      ip_addr="[::]"
    fi

    echo "getting enode for instance $id ($i/$N)"
    eth="$GETH --datadir $DIR/data/$id --port 303$id --networkid $NETWORK_ID"
    cmd="$eth js <(echo 'console.log(admin.nodeInfo.enode); exit();') "
    echo $cmd
    bash -c "$cmd" 2>/dev/null |grep enode | perl -pe "s/\[\:\:\]/$IP_ADDR/g" | perl -pe "s/^/\"/; s/\s*$/\"/;" | tee >> $DIR/nodes
    if ((i<N-1)); then
      echo "," >> $DIR/nodes
    fi
  done
  echo "]" >> $DIR/nodes
fi

for ((i=0;i<N;++i)); do
  id=`printf "%02d" $i`
  #echo "copy $DIR/data/$id/static-nodes.json"
  mkdir -p $DIR/data/$id
  # cp $dir/nodes $dir/data/$id/static-nodes.json
  echo "launching node $i/$N ---> tail-f $DIR/log/$id.log"
  echo GETH=$GETH bash ./gethup.sh $dir $id --networkid $NETWORK_ID $*
  GETH=$GETH bash ./gethup.sh $DIR $id --networkid $NETWORK_ID $*
done
