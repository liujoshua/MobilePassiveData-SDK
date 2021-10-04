package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.datetime.Instant
import kotlinx.serialization.EncodeDefault
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import org.sagebionetworks.assessmentmodel.passivedata.ResultData

@Serializable
data class AirQualityServiceResult(
    override val identifier: String,
    @SerialName("provider")
    val providerName: WeatherServiceProviderName,
    override val startDate: Instant,
    val aqi: Int?,
    val category: Category?
) : ResultData {
    @EncodeDefault(EncodeDefault.Mode.ALWAYS)
    @SerialName("type")
    val serviceType = WeatherServiceType.AirQuality

    override val endDate: Instant
        get() = startDate

    @Serializable
    data class Category(
        val number: Int,
        val name: String
    )
}
