package es.codeurjc.k8sdevtools.demoservice;

import org.springframework.data.jpa.repository.JpaRepository;

public interface AnunciosRepository extends JpaRepository<Anuncio, Long> {

}