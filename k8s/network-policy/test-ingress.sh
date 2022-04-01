#!/bin/bash

function test() {

    output=$(curl --max-time 1 -s $2 )
    if [[ $output == *$3* ]]
    then
        echo $1": OK"
    else
        echo $1:" FAIL"
    fi
}


HOST=$(minikube ip)
PORT=$(kubectl get service ingress-nginx-controller -n ingress-nginx --output='jsonpath={.spec.ports[0].nodePort}')

echo Testing serviceA in http://$HOST:$PORT/servicea/

test "ServiceA External Ingress" "http://$HOST:$PORT/servicea/internalvalue" "{ value: 0 }"

test "ServiceA External Egress" "http://$HOST:$PORT/servicea/externalvalue" "0747532699"

test "ServiceA to ServiceB" "http://$HOST:$PORT/servicea/servicebvalue-internal" "{ value: 0 }"

test "ServiceB External Egress (through ServiceA)" "http://$HOST:$PORT/servicea/servicebvalue-external" "0747532699"




