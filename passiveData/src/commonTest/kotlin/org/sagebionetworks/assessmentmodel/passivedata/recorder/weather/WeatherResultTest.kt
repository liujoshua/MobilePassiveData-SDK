package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.modules.plus
import org.sagebionetworks.assessmentmodel.passivedata.resultDataSerializersModule
import kotlin.test.Test

class WeatherResultTest {
    @Test
    fun testPolymorphicSerialization() {

        val weatherResult: org.sagebionetworks.assessmentmodel.passivedata.ResultData =
            WeatherResult("identifier", weather = null, airQuality = null)

        val jsonCoder = Json {
            serializersModule += resultDataSerializersModule
        }
        val json = jsonCoder.encodeToString(weatherResult)
        println(json)
    }
}