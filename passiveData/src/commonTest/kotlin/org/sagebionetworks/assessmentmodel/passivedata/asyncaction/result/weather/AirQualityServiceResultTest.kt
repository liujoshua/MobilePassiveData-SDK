package org.sagebionetworks.assessmentmodel.passivedata.asyncaction.result.weather

import kotlinx.datetime.Clock
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.AirQualityServiceResult
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.WeatherServiceProviderName
import kotlin.test.Test
import kotlin.test.assertEquals

class AirQualityServiceResultTest {

    private val jsonCoder = Json

    @Test
    fun testSerializerRoundTrip() {
        val airQualityServiceResult = AirQualityServiceResult(
            "id",
            WeatherServiceProviderName.AIR_NOW,
            Clock.System.now(),
            110,
            AirQualityServiceResult.Category(1, "Stuff")
        )

        val jsonResult = jsonCoder.encodeToString(airQualityServiceResult)

        println(jsonResult)
        val deserializedresult = jsonCoder.decodeFromString<AirQualityServiceResult>(sampleJson)

        assertEquals(airQualityServiceResult, deserializedresult)
    }

    val sampleJson =
        """
   [{
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
}]
   """
}