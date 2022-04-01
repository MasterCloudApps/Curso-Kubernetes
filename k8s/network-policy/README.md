# Network Policy

## Aplicación de ejemplo

Usaremos una aplicación con dos microservicios sintéticos implementados en Python. Esta aplicación nos permitirá ver cómo el tráfico se va restringiendo.

Los servicios son:
* ServiceA:
  * Es el frontal
  * Atiende peticiones del exterior en el puerto 5000
  * Hace peticiones a google (https://www.googleapis.com)
  * Hace peticiones al ServiceB
* ServiceB:
  * Es un servicio interno
  * No debería aceptar peticiones del exterior.
  * Hace peticiones a google (https://www.googleapis.com)
  * Es usado desde el serviceA.

### Construcción de contenedores (opcional)

Los contenedores de la aplicación están publicados en DockerHub, pero también se proporciona el código fuente por si se quieren modificar para hacer pruebas.

Si se va a desplegar en minikube, se puede configurar la shell para construir las imágenes directamente en el clúster:

```
eval $(minikube -p minikube docker-env)
```
Construcción de las imágenes:
```
$ docker build -t=codeurjc/np-servicea:v1 servicea/.
$ docker build -t=codeurjc/np-serviceb:v1 serviceb/.
```

Se puede ejecutar el servicioA para probar que funciona.

Si hemos conectado la shell a minikube tenemos que ejecutar el contenedor en minikube:

```
$ minikube ssh
```

Ejecutamos el contenedor:
```
$ docker run --name servicea -d -p 5000:5000 codeurjc/np-servicea:v1
```
Y probar que funciona con

```
$ curl http://127.0.0.1:5000/info
{ status: "ok"}
```
Lo borramos:
```
$ docker rm -f servicea
```

Si estamos en el nodo minikube, nos salimos:

```
$ exit
```

Si no tenemos acceso a minikube, tenemos que publicar las imágenes en un registry (por ejemplo DockerHub) para poder desplegarlas en Kubernetes. Si publicamos en DockerHub necesitamos permisos para la organización codeurjc. Si las desplegamos en otra organización, hay que cambiar el nombre de la imagen en los comandos de despliegue y los manifiestos.

```
$ docker push codeurjc/np-servicea:v1
$ docker push codeurjc/np-serviceb:v1
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

Se ha creado un script de bash que realiza todas estas operaciones y verifica si el resultado demuestra que hay conectividad o no.

```
$ ./test.sh
Host: 192.168.49.2
ServiceA port: 31698
ServiceB port: 32755
ServiceA External Ingress: OK
ServiceB External Ingress: OK
ServiceA External Egress: OK
ServiceA to ServiceB: OK
ServiceB External Egress (direct): OK
ServiceB External Egress (through ServiceA): OK
```

Se ha implementado otro test específico para microk8s (por sus particularidades para obtener la IP y por la ejecución del comando `microk8s kubectl`)

```
$ ./test-microk8s.sh
...
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

Las conexiones que funcionaban lo siguen haciendo. No se ha hecho honor a la network policy. Para que se haga honor, hay que instalar Cilium, un Network plugin que soporta network policies.

### Instalar Cilium en MiniKube

Instalaremos cilium en Minikube siguiendo estas instrucciones:

hhttps://docs.cilium.io/en/v1.11/gettingstarted/k8s-install-default/

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

### Instalar Cilium en Microk8s

```
$ microk8s enable cilium
```

### Instalar Cilium en Docker Desktop

Parece que no se puede instalar el network plugin con cilium en Docker Desktop. Aquí el issue en el que están haciendo el tracking:

https://github.com/cilium/cilium/issues/10516

### Instalar cilium en k3s 

Instalamos k3s en un linux con opciones para no instalar driver de red ni ingress Traefik.

```
$ curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy --no-deploy traefik ' sh -
```

Damos permisos a '/etc/rancher/k3s/k3s.yaml':
```
$ sudo chmod 777 /etc/rancher/k3s/k3s.yaml
```

Exportamos config del cluster:
```
$ export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

Instalamos cilium en k3s:

```
$ cilium install
```

Comprobamos que todo va bien

```
$ cilium status --wait
```

Instalar nginx-controller:

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.47.0/deploy/static/provider/baremetal/deploy.yaml
```

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

Permitimos conexión del service A con el exterior al puerto 5000 con `np-servicea-ingress.yaml`

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
      ports:
      - protocol: TCP
        port: 5000
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

**NOTA:** Todos los servicios que tengan que conectarse con otros servicios necesitan acceso al puerto 53 para poder resolver el nombre.

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

## ServiceA accesible con Ingress Controller

Podemos usar Ingress Controller para publicar el serviceA. 

Para ello, activamos el addon de Ingress en minikube

```
$ minikube addons enable ingress
```

`ingress.yaml`
```
apiVersion: networking.k8s.io/v1
kind: Ingress  
metadata:  
  name: servicea-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:  
  rules:
   - http:
      paths:
      - path: /servicea(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: servicea-service
            port:
              number: 5000
```

```
$ kubectl apply -f kubernetes/ingress.yaml
```

Ahora actualizamos el Service del ServicioA a ClusterIP:

`servicea-service-cpi.yaml`
```
---
apiVersion: v1
kind: Service
metadata:
  name: servicea-service
  labels:
    app: servicea
spec:
  ports:
    - port: 5000
      protocol: TCP
      name: servicea-port
  selector:
    app: servicea
  type: ClusterIP
```

```
$ kubectl apply -f kubernetes/servicea-service-cip.yaml
```

Ahora podemos acceder al ServicioA desde el puerto 80 (usando el ingress controller) y la ruta `http://minikube-ip/servicea/`

```
$ ./test-ingress.sh
Testing serviceA from http://192.168.99.102/servicea/
ServiceA External Ingress: OK
ServiceA External Egress: OK
ServiceA to ServiceB: OK
ServiceB External Egress (through ServiceA): OK
```

En el caso de usar el ingress podemos afinar todavía más la network-policy del servicea para que sólo permita el acceso desde el Ingress (y no desde cualquier sitio):

Para ello, un kubernetes previos a la versión 1.21 primero tenemos que poner una etiqueta en el namespace kube-system:

```
$ kubectl label namespace kube-system kubernetes.io/metadata.name=kube-system
```

`np-servicea-ingress-ingress.yaml`
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
    - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: kube-system
        podSelector:
          matchLabels:
            app.kubernetes.io/name: ingress-nginx
      ports:
        - protocol: TCP
          port: 5000
```

```
$ kubectl apply -f kubernetes/np-servicea-ingress-ingress.yaml
```
**NOTA:** Esta Network Policy es bastante frágil porque sólo funciona si el nginx-controller está en el namespace `kube-system` y tiene una label `app.kubernetes.io/name:ingress-nginx`. Por ejemplo, en minikube 1.18 si es así, pero en minikube 1.19 el nginx-controller está en otro namespace y por tanto esta política fallará.

## Más información

* [Página oficial de Kubernetes sobre Network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
* [Otra página oficial sobre las Network policies](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)
* [Ejemplos de Network policies típicas](https://github.com/ahmetb/kubernetes-network-policy-recipes/)
* [Más ejemplos de Network policies](http://docs.galacticfog.com/security/network-policies/kube-network-policies/)
* [Instalación de cilium en Minikube](https://cilium.readthedocs.io/en/stable/gettingstarted/minikube/)
