package es.codeurjc.mca.observability.metrics;

import java.util.concurrent.atomic.AtomicInteger;

import org.springframework.stereotype.Component;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.binder.MeterBinder;

@Component
public class ScrapingMetrics implements MeterBinder {

	private Counter timesWebGotScrapedCounter;
	private AtomicInteger timeSpentScrapingLastAttemptGauge;

	@Override
	public void bindTo(final MeterRegistry meterRegistry) {
		
		timesWebGotScrapedCounter = meterRegistry
			.counter("times_website_got_scraped_counter");

		timeSpentScrapingLastAttemptGauge = meterRegistry
			.gauge("time_spent_scraping_last_attempt", new AtomicInteger(0));
	}

	public void setTimeScrapingLastAttemptMetric(int seconds) {
		this.timeSpentScrapingLastAttemptGauge.set(seconds);		
	}

    public void incrementTimesWebGotScrapedCounter() {
		this.timesWebGotScrapedCounter.increment();
    }
}
