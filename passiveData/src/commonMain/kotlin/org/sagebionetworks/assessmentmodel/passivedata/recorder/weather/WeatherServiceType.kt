package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import org.sagebionetworks.assessmentmodel.passivedata.internal.StringEnum

@Serializable
enum class WeatherServiceType : StringEnum {
    @SerialName("weather")
    Weather,

    @SerialName("airQuality")
    AirQuality
}