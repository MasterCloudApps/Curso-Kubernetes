# Network Policy

## Aplicación de ejemplo

Usaremos una aplicación con dos microservicios sintéticos implementados en Python.

Los servicios son:
* ServiceA es el frontal y atiende peticiones del exterior
* ServiceB es un servicio interno y no debería aceptar peticiones del exterior. Es usado desde el serviceA.

### Construcción de contenedores

```
$ docker build -t=codeurjc/np-servicea servicea/.
$ docker build -t=codeurjc/np-serviceb serviceb/.
```

Se puede ejecutar el servicioA en local con el comando:

```
$ docker run -p 5000:5000 codeurjc/np-servicea
```

Y probar que funciona con

```
$ curl http://127.0.0.1:5000/info
```

Publicamos las imágenes en DockerHub
```
$ docker push codeurjc/np-servicea
$ docker push codeurjc/np-serviceb
```

### Despliegue Kubernetes

Y las podemos desplegar en minikube:

```
$ kubectl apply -f kubernetes/servicea.yaml
$ kubectl apply -f kubernetes/serviceb-deployment.yaml
$ kubectl apply -f kubernetes/serviceb-service-np.yaml
```

Obtenemos la URL pública de los servicios

``` 
$ HOST=$(minikube ip)
$ echo $HOST
$ SA_PORT=$(kubectl get service servicea-service --output='jsonpath={.spec.ports[0].nodePort}')
$ echo $SA_PORT
$ SB_PORT=$(kubectl get service serviceb-service --output='jsonpath={.spec.ports[0].nodePort}')
$ echo $SB_PORT

```

### Verificación comunicación de servicios

Usamos los servicios:

* ServiceA External Ingress
```
$ curl http://$HOST:$SA_PORT/internalvalue
{ value: 0 }
```

* ServiceB External Ingress
```
$ curl http://$HOST:$SB_PORT/internalvalue
{ value: 0 }
```

* ServiceA External Egress
```
$ curl http://$HOST:$SA_PORT/externalvalue
...0747532699...
```

* ServiceA to ServiceB
```
$ curl http://$HOST:$SA_PORT/servicebvalue-internal
{ value: 0 }
```

* ServiceB External Egress (direct)
```
$ curl http://$HOST:$SB_PORT/externalvalue
...0747532699...
```

* ServiceB External Egress (through ServiceA)
```
$ curl http://$HOST:$SA_PORT/servicebvalue-external
...0747532699...
```

## Test automático

Se ha creado un script de bash que realiza todas estas peticiones y verifica si el resultado demuestra que hay conectividad o no.

```
$ ./test.sh
ServiceA External Ingress: OK
ServiceB External Ingress: OK
ServiceA External Egress: OK
ServiceA to ServiceB: OK
ServiceB External Egress (direct): OK
ServiceB External Egress (through ServiceA): OK
```

## Restricción de conexiones de red

### Publicar ServiceB como ClusterIP 

```
$ kubectl delete -f kubernetes/serviceb-service-np.yaml 
service "serviceb-service" deleted
$ kubectl apply -f kubernetes/serviceb-service-cip.yaml 
service/serviceb-service created
$ ./test.sh
ServiceA External Ingress: OK
ServiceB External Ingress: FAIL
ServiceA External Egress: OK
ServiceA to ServiceB: OK
ServiceB External Egress (direct): FAIL
ServiceB External Egress (through ServiceA): OK
```

Los fallos de la conexión directa al servicio B son debidos a que el puerto usado antes ya no está accesible. No se expone al exterior el serviceB.

### Aplicar Network Policy

Creamos la regla de denegar todo:

np-deny-all.yaml
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

```
$ kubectl apply -f kubernetes/np-deny-all.yaml 
networkpolicy.networking.k8s.io/default-deny created
```

Probamos la comunicaciones:
```
$ ./test.sh
ServiceA External Ingress: OK
ServiceB External Ingress: FAIL
ServiceA External Egress: OK
ServiceA to ServiceB: OK
ServiceB External Egress (direct): FAIL
ServiceB External Egress (through ServiceA): OK
```

Las conexiones que funcionaban lo siguen haciendo. No se ha hecho honor a la network policy. Para que se haga honor, hay que instalar un Network plugin que soporte Network policy

### Instalar Network policy plugin en MiniKube

Instalaremos cilium en Minikube siguiendo estas instrucciones:

https://docs.cilium.io/en/v1.9/gettingstarted/minikube/

Iniciamos minikube con el network plugin de tipo cilium con VirtualBox (Yo no he conseguido hacerlo funcionar con docker, el driver por defecto)

```
minikube start --cni=cilium --memory=4096 --driver=virtualbox
```

Verificamos que se ha desplegado correctamente
```
$ kubectl get pods --namespace=kube-system
NAME                                        READY   STATUS            RESTARTS   AGE
cilium-nhwl7                                0/1     Running   0          31s
...
```

NOTA: Parece que no se puede instalar el network plugin con cilium en Docker Desktop. Aquí el issue en el que están haciendo el tracking:

https://github.com/cilium/cilium/issues/10516

### Volvemos a aplicar el Deny network policy

Si hemos borrado el cluster y lo hemos regenerado de nuevo, tenemos que volver a desplegar los servicios:

```
$ kubectl apply -f kubernetes/servicea.yaml
$ kubectl apply -f kubernetes/serviceb-deployment.yaml
$ kubectl apply -f kubernetes/serviceb-service-cip.yaml
```

Desplegamos el Deny all policy:

```
$ kubectl apply -f kubernetes/np-deny-all.yaml
$ ./test.sh
ServiceA External Ingress: FAIL
ServiceB External Ingress: FAIL
ServiceA External Egress: FAIL
ServiceA to ServiceB: FAIL
ServiceB External Egress (direct): FAIL
ServiceB External Egress (through ServiceA): FAIL
```

### Permitimos tráfico público al service A (SericeA External Ingress):

Permitimos conexión del service A con el exterior con `np-servicea-ingress.yaml`

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: servicea-external-ingress
spec:
  podSelector:
    matchLabels:
      app: servicea
  ingress:
    - from: []
```

```
$ kubectl apply -f kubernetes/np-servicea-ingress.yaml
```

```
$ ./test.sh                          
ServiceA External Ingress: OK
ServiceB External Ingress: FAIL
ServiceA External Egress: OK
ServiceA to ServiceB: FAIL
ServiceB External Egress (direct): FAIL
ServiceB External Egress (through ServiceA): FAIL
```

### Permitimos comunicación egress al service A (SericeA External Egress):

Permitimos conexión al service A con `np-servicea-egress.yaml`

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: servicea-external-egress
spec:
  podSelector:
    matchLabels:
      app: servicea
  egress:
  - ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
    - port: 443
      protocol: TCP

```

```
$ kubectl apply -f kubernetes/np-servicea-egress.yaml
```

```
$ ./test.sh                          
ServiceA External Ingress: OK
ServiceB External Ingress: FAIL
ServiceA External Egress: OK
ServiceA to ServiceB: FAIL
ServiceB External Egress (direct): FAIL
ServiceB External Egress (through ServiceA): FAIL
```

Pero esta regla permite la comunicación a cualquier IP y puertos 443 y 53.

Podemos ajustar más el egress.

`np-servicea-egress2.yaml`

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: servicea-external-egress2
spec:
  podSelector:
    matchLabels:
      app: servicea
  egress:
    # allow connection to www.googleapis.com > 216.58.201.170
    # Note that DNS IP can change. Egress can not be configured with host names
  - to:
    - ipBlock:
        cidr: 216.58.201.170/32
    ports:
    - port: 443
      protocol: TCP
  - ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
```

Con Cilium podemos tener egress con FQDN (https://docs.cilium.io/en/v1.9/gettingstarted/dns/)

`np-servicea-egress3.yaml`
```
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: servicea-external-egress3
spec:
  endpointSelector:
    matchLabels:
      app: servicea
  egress:
    # allow connection to www.googleapis.com > 2a00:1450:4003:801::200a
    # Note that DNS IP can change. Egress can not be configured with host names
  - toFQDNs:
    - matchName: "www.googleapis.com"
  - toEndpoints:
    - matchLabels:
        "k8s:io.kubernetes.pod.namespace": kube-system
        "k8s:k8s-app": kube-dns
    toPorts:
    - ports:
      - port: "53"
        protocol: ANY
      rules:
        dns:
        - matchPattern: "*"
```


### Permitimos comunicación Service A al Servicio B (ServiceA to ServiceB):

np-servicea-serviceb.yaml
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: servicea2serviceb
spec:
  podSelector:
    matchLabels:
      app: servicea
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: serviceb
    ports:
    - port: 5000
      protocol: TCP

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: serviceb2servicea
spec:
  podSelector:
    matchLabels:
      app: serviceb
  ingress:
    - from:
      - podSelector:
          matchLabels:
            app: servicea
      ports:
      - port: 5000
        protocol: TCP  
```

```
$ kubectl apply -f kubernetes/np-servicea-serviceb.yaml
```

```
$ ./test.sh
ServiceA External Ingress: OK
ServiceB External Ingress: FAIL
ServiceA External Egress: OK
ServiceA to ServiceB: OK
ServiceB External Egress (direct): FAIL
ServiceB External Egress (through ServiceA): FAIL
```

### Permitimos comunicación egress al service B (SericeA External Egress):

np-serviceb-egress.yaml
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: serviceb-external-egress
spec:
  podSelector:
    matchLabels:
      app: serviceb
  egress:
  - ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
    - port: 443
      protocol: TCP
```

```
$ kubectl apply -f kubernetes/np-serviceb-egress.yaml
```

```
$ ./test.sh
ServiceA External Ingress: OK
ServiceB External Ingress: FAIL
ServiceA External Egress: OK
ServiceA to ServiceB: OK
ServiceB External Egress (direct): FAIL
ServiceB External Egress (through ServiceA): OK
```

## Más información

* [Página oficial de Kubernetes sobre Network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
* [Otra página oficial sobre las Network policies](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)
* [Ejemplos de Network policies típicas](https://github.com/ahmetb/kubernetes-network-policy-recipes/)
* [Más ejemplos de Network policies](http://docs.galacticfog.com/security/network-policies/kube-network-policies/)
* [Instalación de cilium en Minikube](https://cilium.readthedocs.io/en/stable/gettingstarted/minikube/)
