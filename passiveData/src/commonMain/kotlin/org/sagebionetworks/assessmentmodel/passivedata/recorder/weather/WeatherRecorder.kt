package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import io.github.aakira.napier.Napier
import io.ktor.client.*
import io.ktor.client.features.json.*
import io.ktor.client.features.json.serializer.*
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.delay
import kotlinx.coroutines.supervisorScope
import kotlinx.serialization.json.Json
import org.sagebionetworks.assessmentmodel.passivedata.recorder.Recorder

abstract class WeatherRecorder(override val configuration: WeatherConfiguration) :
    Recorder<WeatherResult> {

    // TODO joliu inject
    val httpClient = HttpClient {
        install(JsonFeature) {
            serializer = KotlinxSerializer(kotlinx.serialization.json.Json {
                ignoreUnknownKeys = true
            })
        }
    }
    lateinit var weatherServices: List<WeatherService>
    override val result = CompletableDeferred<WeatherResult>()

    suspend fun launchWeatherServices(location: Location?) {
        Napier.d("Launching weather services")
        Napier.d("Location: $location")
        if (location == null) {
            Napier.w("No location available, unable to start recorder")
            return
        }
        // TODO joliu remove
        weatherServices = configuration.services.map { weatherServiceFactory(it) }
        supervisorScope {
            val res = weatherServices.map { service ->
                try {
                    service.getResult(location)
                } catch (e: Exception) {
                    Napier.w(
                        "Encountered exception in ${service.configuration.identifier} service",
                        e
                    )
                    return@map null
                }
            }.filterNotNull()

            val airQualityServiceResult = res.find {
                it is AirQualityServiceResult
            } as AirQualityServiceResult?

            val weatherServiceResult = res.find { it is WeatherServiceResult }
                    as WeatherServiceResult?

            val weatherResult = WeatherResult(
                configuration.identifier,
                weather = weatherServiceResult,
                airQuality = airQualityServiceResult
            )

            result.complete(value = weatherResult)
        }
    }

    fun weatherServiceFactory(configuration: WeatherServiceConfiguration): WeatherService {
        return when (configuration.providerName) {
            WeatherServiceProviderName.AIR_NOW -> {
                AirQualityService(
                    configuration,
                    httpClient
                )
            }
            WeatherServiceProviderName.OPEN_WEATHER -> {
                OpenWeatherService(
                    configuration,
                    httpClient
                )
            }
        }
    }

    abstract suspend fun getLocation(): Location?

    override fun pause() {
        // ignored
    }

    override fun resume() {
        // ignored
    }

    override fun isPaused(): Boolean {
        return false
    }

}