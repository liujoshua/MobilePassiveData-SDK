package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.coroutines.*
import kotlin.test.Test

class MiscTest {

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

                res.map{println(it)}
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