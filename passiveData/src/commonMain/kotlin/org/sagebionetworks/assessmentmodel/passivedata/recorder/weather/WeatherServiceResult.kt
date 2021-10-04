package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.datetime.Instant
import kotlinx.serialization.EncodeDefault
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import org.sagebionetworks.assessmentmodel.passivedata.ResultData

@Serializable
data class WeatherServiceResult(
    override val identifier: String,
    @SerialName("provider")
    val providerName: WeatherServiceProviderName,
    override val startDate: Instant,
    val temperature: Double? = null,
    val seaLevelPressure: Double? = null,
    val groundLevelPressure: Double? = null,
    val humidity: Double? = null,
    val clouds: Double? = null,
    val rain: Precipitation? = null,
    val snow: Precipitation? = null,
    val wind: Wind? = null
) : ResultData {
    @EncodeDefault(EncodeDefault.Mode.ALWAYS)
    @SerialName("type")
    val serviceType = WeatherServiceType.Weather

    override val endDate: Instant
        get() = startDate

    @Serializable
    data class Precipitation(val pastHour: Double?, val pastThreeHours: Double?)

    @Serializable
    data class Wind(val speed: Double, val degrees: Double?, val gust: Double?)
}

