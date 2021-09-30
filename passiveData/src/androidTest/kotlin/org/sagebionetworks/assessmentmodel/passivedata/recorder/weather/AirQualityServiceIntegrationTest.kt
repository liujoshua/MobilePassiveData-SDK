package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import io.ktor.client.*
import io.ktor.client.features.json.*
import io.ktor.client.features.json.serializer.*
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.encodeToString
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class AirQualityServiceIntegrationTest {
    @Test
    fun testRemoteCall() {
        val airQualityServiceApiKey = System.getProperty("airNowApiKey")

        val httpClient = HttpClient {
            install(JsonFeature) {
                serializer = KotlinxSerializer(kotlinx.serialization.json.Json {
                    ignoreUnknownKeys = true
                })
            }
        }

        val serviceConfiguration = WeatherServiceConfiguration(
            "weatherServiceConfig",
            WeatherServiceProviderName.AIR_NOW,
            airQualityServiceApiKey!!
        )

        val service = OpenWeatherService(
            serviceConfiguration,
            httpClient
        )

        val weatherServiceResult = runBlocking {
            service.getResult(
                Location(
                    166.0,
                    42.0
                )
            )
        } as WeatherServiceResult

        val json = kotlinx.serialization.json.Json {
            prettyPrint = true
        }
        println(json.encodeToString(weatherServiceResult))
        assertNotNull(weatherServiceResult)
        assertEquals(WeatherServiceProviderName.OPEN_WEATHER, weatherServiceResult.providerName)
    }
}