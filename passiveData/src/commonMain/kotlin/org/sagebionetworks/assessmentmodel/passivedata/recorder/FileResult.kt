package org.sagebionetworks.assessmentmodel.passivedata.recorder

import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import org.sagebionetworks.assessmentmodel.passivedata.ResultData

@Serializable
data class FileResult(
    override val identifier: String,
    override val startDate: Instant,
    override val endDate: Instant,
    val fileType: String,
    val relativePath: String
) : ResultData {
}