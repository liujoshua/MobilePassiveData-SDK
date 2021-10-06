package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.modules.plus
import org.sagebionetworks.assessmentmodel.passivedata.ResultData
import org.sagebionetworks.assessmentmodel.passivedata.resultDataSerializersModule
import kotlin.test.Test

class WeatherResultTest {
    @Serializable
    class ResultDataWrapper(val resultData:ResultData)
    @Test
    fun testPolymorphicSerialization() {

        val weatherResult: ResultData =
            WeatherResult("identifier", weather = null, airQuality = null)

        val jsonCoder = Json {
            serializersModule += resultDataSerializersModule
        }
        val json = jsonCoder.encodeToString(ResultDataWrapper(weatherResult))
        println(json)
    }
}