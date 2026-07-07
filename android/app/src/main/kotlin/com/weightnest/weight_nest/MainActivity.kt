package com.weightnest.weight_nest

import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        const val CHANNEL = "com.weightnest/file_helper"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readContentUri" -> readContentUri(call, result)
                    "extractMotionVideo" -> extractMotionVideo(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    // ── readContentUri ──

    private fun readContentUri(
        call: io.flutter.plugin.common.MethodCall,
        result: io.flutter.plugin.common.MethodChannel.Result
    ) {
        val uriStr = call.argument<String>("uri") ?: run {
            result.error("ARG_ERROR", "uri is null", null)
            return
        }
        try {
            val uri = Uri.parse(uriStr)
            val inputStream = contentResolver.openInputStream(uri)
                ?: run {
                    result.error("IO_ERROR", "Cannot open content URI", null)
                    return
                }
            val bytes = inputStream.readBytes()
            inputStream.close()

            // 写入临时文件
            val extension = uriStr.substringAfterLast('.', "")
            val ext = if (extension.isNotEmpty() && extension.length <= 10) ".$extension" else ".tmp"
            val tmpDir = File(cacheDir, "wn_import")
            tmpDir.mkdirs()
            val tmpFile = File(tmpDir, "imported_${System.currentTimeMillis()}$ext")
            tmpFile.writeBytes(bytes)

            result.success(tmpFile.absolutePath)
        } catch (e: Exception) {
            result.error("READ_ERROR", e.message, null)
        }
    }

    // ── extractMotionVideo ──

    /**
     * Extracts embedded MP4 video from Android motion photos.
     *
     * Android motion photos (Samsung Motion Photo, Google Pixel Motion Photo)
     * are JPEG files with an MP4 video segment embedded. The XMP metadata in
     * the JPEG APP1 segment contains markers like:
     *   - Google: GCamera:MotionPhoto, GCamera:MotionPhotoVersion
     *   - Samsung: MotionPhoto_Data, MotionPhoto
     *
     * This method locates the MP4 segment by scanning for a *valid* ftyp box —
     * not just the ASCII bytes "ftyp" which can appear randomly in JPEG pixel
     * data. Every candidate is validated:
     *   1. box size ≥ 16 bytes and fits within the remaining file
     *   2. major brand field is 4 printable ASCII characters
     *
     * If no valid ftyp box is found the method returns null so the Dart side
     * gracefully falls back to displaying the static JPEG still image.
     */
    private fun extractMotionVideo(
        call: io.flutter.plugin.common.MethodCall,
        result: io.flutter.plugin.common.MethodChannel.Result
    ) {
        val jpegPath = call.arguments as? String ?: run {
            result.error("ARG_ERROR", "path argument is required", null)
            return
        }

        try {
            val file = File(jpegPath)
            if (!file.exists()) {
                result.success(null)
                return
            }

            val bytes = file.readBytes()

            // Check for motion photo XMP markers
            val content = String(bytes, Charsets.ISO_8859_1)
            val isMotionPhoto = content.contains("GCamera:MotionPhoto") ||
                    content.contains("MotionPhoto_Data") ||
                    content.contains("motion_photo") ||
                    content.contains("MotionPhoto")

            if (!isMotionPhoto) {
                result.success(null)
                return
            }

            // Find a *valid* MP4 ftyp box (not just the ASCII bytes).
            // MP4 structure: [4B box size] [4B "ftyp"] [4B major brand] [4B minor version] ...
            val ftypPattern = byteArrayOf(0x66, 0x74, 0x79, 0x70) // "ftyp"
            val mp4Offset = findValidMp4Start(bytes, ftypPattern)

            if (mp4Offset < 0) {
                // No valid MP4 header found — treat as still photo
                result.success(null)
                return
            }

            // Extract MP4 segment from the computed offset to end of file
            val mp4Bytes = bytes.copyOfRange(mp4Offset, bytes.size)
            if (mp4Bytes.size < 1024) {
                result.success(null)
                return
            }

            // Write extracted MP4 to temp file
            val tmpDir = File(cacheDir, "motion_photo")
            tmpDir.mkdirs()
            val mp4File = File(tmpDir, "motion_${System.currentTimeMillis()}.mp4")
            mp4File.writeBytes(mp4Bytes)

            result.success(mp4File.absolutePath)
        } catch (e: Exception) {
            result.error("EXTRACT_ERROR", e.message, null)
        }
    }

    /**
     * Search for a *valid* MP4 ftyp box in [data].
     *
     * Returns the byte offset of the ftyp box size field (i.e. the start of
     * the MP4 segment), or -1 if no structurally-valid ftyp box is found.
     *
     * Validation rules for each "ftyp" candidate:
     *   1. boxSize ≥ 16 (minimum: size + "ftyp" + 4-char major brand + 4B minor version)
     *   2. boxStart + boxSize ≤ data.size (box must fit within the file)
     *   3. major brand at boxStart+8 is 4 printable ASCII characters
     */
    private fun findValidMp4Start(data: ByteArray, ftypPattern: ByteArray): Int {
        var searchFrom = 0
        while (searchFrom <= data.size - ftypPattern.size - 8) {
            val matchAt = findPatternFrom(data, ftypPattern, searchFrom)
            if (matchAt < 0) return -1

            val boxStart = matchAt - 4  // box size field is 4 bytes before "ftyp"
            if (boxStart < 0) {
                searchFrom = matchAt + 1
                continue
            }

            // Read box size (big-endian uint32)
            val boxSize = ((data[boxStart].toInt() and 0xFF) shl 24) or
                    ((data[boxStart + 1].toInt() and 0xFF) shl 16) or
                    ((data[boxStart + 2].toInt() and 0xFF) shl 8) or
                    (data[boxStart + 3].toInt() and 0xFF)

            // Validation 1: box size is reasonable and fits within remaining data
            if (boxSize < 16 || boxStart + boxSize > data.size) {
                searchFrom = matchAt + 1
                continue
            }

            // Validation 2: major brand at boxStart+8 is 4 printable ASCII chars
            if (!isPrintableAscii4(data, boxStart + 8)) {
                searchFrom = matchAt + 1
                continue
            }

            // Valid ftyp box found
            return boxStart
        }
        return -1
    }

    /** True when the 4 bytes at [offset] are all printable ASCII (0x20–0x7E). */
    private fun isPrintableAscii4(data: ByteArray, offset: Int): Boolean {
        if (offset + 4 > data.size) return false
        for (i in 0 until 4) {
            val b = data[offset + i].toInt() and 0xFF
            if (b < 0x20 || b > 0x7E) return false
        }
        return true
    }

    /** Find [pattern] in [data] starting from [startFrom]. Returns index or -1. */
    private fun findPatternFrom(data: ByteArray, pattern: ByteArray, startFrom: Int): Int {
        outer@ for (i in startFrom..(data.size - pattern.size)) {
            for (j in pattern.indices) {
                if (data[i + j] != pattern[j]) continue@outer
            }
            return i
        }
        return -1
    }
}
