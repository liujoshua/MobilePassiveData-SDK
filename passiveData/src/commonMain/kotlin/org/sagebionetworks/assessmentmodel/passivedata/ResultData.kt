package org.sagebionetworks.assessmentmodel.passivedata

import kotlinx.datetime.Instant
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import kotlinx.serialization.modules.subclass
import org.sagebionetworks.assessmentmodel.passivedata.recorder.FileResult
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.WeatherResult

interface ResultData {
    val identifier: String
    val startDate: Instant
    val endDate: Instant
}

val resultDataSerializersModule = SerializersModule {
    polymorphic(ResultData::class) {
        subclass(WeatherResult::class)
        subclass(FileResult::class)
    }
}