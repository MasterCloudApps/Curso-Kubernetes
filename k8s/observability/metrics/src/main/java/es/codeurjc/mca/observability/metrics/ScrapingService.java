package es.codeurjc.mca.observability.metrics;

import java.util.Random;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
public class ScrapingService {

	private static final Logger LOG = LoggerFactory.getLogger(ScrapingService.class);

	private Random random = new Random();

	@Autowired
	private ScrapingMetrics metrics;

	@Scheduled(fixedRate = 1000)
	public void scrapWebsite() throws InterruptedException {

		LOG.info("Start scraping website...");

		int seconds = random.nextInt(9) + 1;
		Thread.sleep(1000L * seconds);

		metrics.setTimeScrapingLastAttemptMetric(seconds);

		metrics.incrementTimesWebGotScrapedCounter();

		LOG.info("Scraping finished");
	}

}