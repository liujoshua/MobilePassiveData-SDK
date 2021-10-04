package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import org.sagebionetworks.assessmentmodel.passivedata.ResultData

@Serializable
@SerialName("weather")
data class WeatherResult(
    override val identifier: String,
    override val startDate: Instant = Clock.System.now(),
    override val endDate: Instant = Clock.System.now(),
    val weather: WeatherServiceResult?,
    val airQuality: AirQualityServiceResult?
) : ResultData {
}