package org.sagebionetworks.assessmentmodel.passivedata.internal

/**
 * A string enum is an enum that uses a string as its raw value.
 */
expect interface StringEnum {
    val name: String

    abstract val serialName: String?
}