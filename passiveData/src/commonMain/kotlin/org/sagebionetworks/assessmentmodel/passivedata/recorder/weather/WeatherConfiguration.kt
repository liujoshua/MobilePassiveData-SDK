package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import org.sagebionetworks.assessmentmodel.passivedata.asyncaction.AsyncActionConfiguration
import org.sagebionetworks.assessmentmodel.passivedata.internal.StringEnum
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.WeatherServiceProviders.TYPE_AIR_NOW
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.WeatherServiceProviders.TYPE_OPEN_WEATHER

@Serializable
data class WeatherConfiguration(
    override val identifier: String,
    override val typeName: String,
    override val startStepIdentifier: String?,
    val services: List<WeatherServiceConfiguration>
) : AsyncActionConfiguration {
}

@Serializable
data class WeatherServiceConfiguration(
    val identifier: String,
    val providerName: WeatherServiceProviderName,
    val apiKey: String
)

@Serializable
enum class WeatherServiceProviderName(override val serialName: String) : StringEnum {
    @SerialName(TYPE_AIR_NOW)
    AIR_NOW(TYPE_AIR_NOW),

    @SerialName(TYPE_OPEN_WEATHER)
    OPEN_WEATHER(TYPE_OPEN_WEATHER);

    companion object {
        fun findForSerializedName(serializedName: String): WeatherServiceProviderName? {
            return WeatherServiceProviderName.values().find {
                it.serialName == serializedName
            }
        }
    }
}

object WeatherServiceProviders {
    const val TYPE_AIR_NOW = "airNow"
    const val TYPE_OPEN_WEATHER = "openWeather"
}
