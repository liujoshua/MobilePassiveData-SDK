package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.datetime.*
import kotlinx.serialization.*
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.overwriteWith
import kotlinx.serialization.modules.plus
import org.sagebionetworks.assessmentmodel.passivedata.ResultData
import org.sagebionetworks.assessmentmodel.passivedata.recorder.FileResult
import org.sagebionetworks.assessmentmodel.passivedata.resultDataSerializersModule
import kotlin.test.Ignore
import kotlin.test.Test

class MiscTest {

    object OffsetZonedInstantSerializer : KSerializer<Instant> {
        override val descriptor: SerialDescriptor =
            PrimitiveSerialDescriptor("Instant", PrimitiveKind.STRING)

        private val json = Json

        override fun deserialize(decoder: Decoder): Instant {
            return Instant.parse(decoder.decodeString())
        }

        override fun serialize(encoder: Encoder, value: Instant) {
            val currentZone = TimeZone.currentSystemDefault()

            val offsetInstant = value.toLocalDateTime(currentZone)
            val offsetZone = currentZone.offsetAt(value)

            encoder.encodeString(
                json.encodeToString(offsetInstant).removeSurrounding("\"")
                        + json.encodeToString(offsetZone).removeSurrounding("\"")
            )
        }

    }

    @Test
    fun resultSer() {
        val json = Json {
            serializersModule += resultDataSerializersModule
        }
        val fresult =
            FileResult("id", Clock.System.now(), Clock.System.now(), "ftype", "fname") as ResultData
        println(json.encodeToString(fresult))
    }

    @Test
    fun dateTimeSer() {
        val json = Json {
            serializersModule = SerializersModule {
                OffsetZonedInstantSerializer
                contextual(Instant::class, OffsetZonedInstantSerializer)
            } + serializersModule
        }
        val currentMoment: Instant = Clock.System.now()
        val datetimeInUtc: LocalDateTime = currentMoment.toLocalDateTime(TimeZone.UTC)

        val currentZone = TimeZone.currentSystemDefault()

        println(
            json.encodeToString(currentMoment)
        )
        val datetimeInSystemZone: LocalDateTime =
            currentMoment.toLocalDateTime(currentZone)

        println(json.encodeToString(currentMoment))
        println(json.encodeToString(datetimeInUtc))
        println(currentZone)


        println("Zone")
        // this is good
        println(json.encodeToString(datetimeInSystemZone))
        println(json.encodeToString(currentZone.offsetAt(currentMoment)))
        println(json.encodeToString(currentZone))


        println("UTC")
        println(json.encodeToString(TimeZone.UTC))
//        println(json.encodeToString(TimeZone.UTC.offset))
        val jsonMomentZoned = json.encodeToString(OffsetZonedInstantSerializer, currentMoment)

        println(jsonMomentZoned)
        println(json.encodeToString(currentMoment))
        println(
            json.encodeToString(
                json.serializersModule.getContextual(Instant::class)!!,
                currentMoment
            )
        )

        val momSer: KSerializer<Instant> = serializer()
        println(momSer)
        println(json.serializersModule.getContextual(Instant::class))
        println(json.decodeFromString<Instant>(jsonMomentZoned))
    }

    fun simple(): Flow<Int> = flow {
        for (i in 1..10) {
            delay(100)
            println("emitting $i")
            emit(i)
        }
    }

    @Test
    @Ignore
    fun testSF() {
        var shared = simple().shareIn(
            CoroutineScope(Dispatchers.Default),
            SharingStarted.WhileSubscribed(0, 0)
        )
        runBlocking {
            var job = launch {
                shared.onCompletion {
                    println("=====Acompleted")
                }.collect {
                    println("Acollected $it")
                }
            }


            launch {
                shared.onCompletion {
                    println("======Bcompleted")
                }.collect {
                    println("Bcollected $it")
                }
            }

            delay(500)
            job.cancel()
        }
    }

    @Test
    fun test() {
        runBlocking {
            supervisorScope {
                val list = listOf(1, 2, 3)
                val res = list.map {
                    try {
                        getNum(it)
                    } catch (e: Exception) {
                        return@map null
                    }
                }.filterNotNull()

                res.map { println(it) }
            }
        }
    }

    suspend fun getNum(i: Int): Int {
        delay(10)
        if (i == 2) {
            throw NullPointerException()
        }
        return i * 5
    }
}

