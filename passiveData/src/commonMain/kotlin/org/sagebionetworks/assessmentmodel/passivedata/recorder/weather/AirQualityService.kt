package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import io.ktor.client.*
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import org.sagebionetworks.assessmentmodel.passivedata.ResultData
import org.sagebionetworks.assessmentmodel.passivedata.internal.StringEnum

class AirQualityService(
    override val configuration: WeatherServiceConfiguration,
    val httpClient: HttpClient
) : WeatherService {
    override suspend fun getResult(location: Location): ResultData {

        val date = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date

        val url = "https://www.airnowapi.org/aq/forecast/latLong/?format=application/json" +
                "&latitude=${location.latitude}&longitude=${location.longitude}" +
                "&date=${date}&distance=25&&API_KEY=${configuration.apiKey}"

        val builder = HttpRequestBuilder()
        with(builder) {
            method = HttpMethod.Get
            url(url)
            header("Accept", "application/json")
        }
        TODO("Not yet implemented")
    }

    @Serializable
    data class Response(
        @SerialName("DateIssue")
        val dateIssue: String,
        @SerialName("DateForecast")
        val dateForecast: String,
        @SerialName("StateCode")
        val stateCode: String? = null,
        @SerialName("AQI")
        val aqi: Int? = null,
        @SerialName("Category")
        val category: Category? = null
    ) {
        @Serializable
        data class Category(
            @SerialName("Number")
            val number: Int,
            @SerialName("Name")
            val name: String
        )
    }
}