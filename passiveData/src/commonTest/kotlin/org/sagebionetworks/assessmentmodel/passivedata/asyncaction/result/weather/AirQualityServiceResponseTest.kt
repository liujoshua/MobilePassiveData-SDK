package org.sagebionetworks.assessmentmodel.passivedata.asyncaction.result.weather

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDateTime
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.AirQualityService
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.AirQualityServiceResult
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.WeatherServiceConfiguration
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.WeatherServiceProviderName
import kotlin.test.Ignore
import kotlin.test.Test
import kotlin.test.assertEquals

@ExperimentalSerializationApi
class AirQualityServiceResponseTest {

    private val jsonCoder = Json {
        ignoreUnknownKeys = true
    }

    @Test
    fun testServiceResultHandling() {
        val deserializedresult =
            jsonCoder.decodeFromString<List<AirQualityService.Response>>(sampleJson)

        val startTime = Instant.parse("2021-10-03T12:01:25Z")
        val dateString = "2021-10-04"
        val response = AirQualityService.handleResponse(
            deserializedresult,
            WeatherServiceConfiguration("resultId", WeatherServiceProviderName.AIR_NOW, "apiKey"),
            dateString,
            startTime
        )
        with(response) {
            assertEquals("resultId", identifier)
            assertEquals(startTime, startDate)
            assertEquals(57, aqi)
            assertEquals(2, category?.number)
            assertEquals("Moderate", category?.name)
            assertEquals(WeatherServiceProviderName.AIR_NOW, providerName)
        }
    }

    val sampleJson =
        """
[
    {
        "DateIssue": "2021-10-03 ",
        "DateForecast": "2021-10-04 ",
        "ReportingArea": "Redwood City",
        "StateCode": "CA",
        "Latitude": 37.48,
        "Longitude": -122.22,
        "ParameterName": "PM2.5",
        "AQI": 57,
        "Category": {
            "Number": 2,
            "Name": "Moderate"
        },
        "ActionDay": false
    }, {
        "DateIssue": "2021-10-03 ",
        "DateForecast": "2021-10-05 ",
        "ReportingArea": "Redwood City",
        "StateCode": "CA",
        "Latitude": 37.48,
        "Longitude": -122.22,
        "ParameterName": "O3",
        "AQI": -1,
        "Category": {
            "Number": 1,
            "Name": "Good"
        },
        "ActionDay": false
    }, {
        "DateIssue": "2021-10-03 ",
        "DateForecast": "2021-10-06 ",
        "ReportingArea": "Redwood City",
        "StateCode": "CA",
        "Latitude": 37.48,
        "Longitude": -122.22,
        "ParameterName": "O3",
        "AQI": -1,
        "Category": {
            "Number": 1,
            "Name": "Good"
        },
        "ActionDay": false
    }, {
        "DateIssue": "2021-10-03 ",
        "DateForecast": "2021-10-07 ",
        "ReportingArea": "Redwood City",
        "StateCode": "CA",
        "Latitude": 37.48,
        "Longitude": -122.22,
        "ParameterName": "O3",
        "AQI": -1,
        "Category": {
            "Number": 1,
            "Name": "Good"
        },
        "ActionDay": false
    }, {
        "DateIssue": "2021-10-03 ",
        "DateForecast": "2021-10-08 ",
        "ReportingArea": "Redwood City",
        "StateCode": "CA",
        "Latitude": 37.48,
        "Longitude": -122.22,
        "ParameterName": "O3",
        "AQI": -1,
        "Category": {
            "Number": 1,
            "Name": "Good"
        },
        "ActionDay": false
    }
]
   """
}