package es.codeurjc.test.tablonanuncios;

import java.util.Optional;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class TablonController {
	
	@Autowired
	private AnunciosRepository repository;

	@PostConstruct
	public void init() {

		if(repository.count() == 0){
			repository.save(new Anuncio("Pepe", "Vendo Moto", "Barata, barata"));
			repository.save(new Anuncio("Juan", "Compro coche", "Pago bien"));
		}		
	}

	@GetMapping("/")
	public String tablon(Model model) {

		model.addAttribute("anuncios", repository.findAll());

		return "tablon";
	}

	@GetMapping("/nuevoAnuncio") 
	public String nuevoAnuncioPage(){
		return "nuevo_anuncio";
	}

	@PostMapping("/anuncio/nuevo")
	public String nuevoAnuncio(Model model, Anuncio anuncio) {

		repository.save(anuncio);

		return "anuncio_guardado";
	}

	@GetMapping("/anuncio/{id}")
	public String verAnuncio(Model model, @PathVariable long id) {
		
		Optional<Anuncio> anuncio = repository.findById(id);

		if(anuncio.isPresent()){
			model.addAttribute("anuncio", anuncio.get());
		}

		return "ver_anuncio";
	}
}