package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlin.test.Test

class WeatherResultTest {
    @Test
    fun testPolymorphicSerialization() {

        val weatherResult: org.sagebionetworks.assessmentmodel.passivedata.ResultData =
            WeatherResult("identifier", weather = null, airQuality = null)

        val jsonCoder = Json
        val json = jsonCoder.encodeToString(weatherResult)
        println(json)
    }
}