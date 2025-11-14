package expo.modules.haishinkit

import android.media.MediaCodecInfo

// Flutter ProfileLevel.kt와 동일한 구조 (Android 지원 프로파일만)
object ProfileLevel {
    fun getProfileLevel(profileLevelStr: String): Pair<Int, Int>? {
        return when (profileLevelStr) {
            "H264_Baseline_3_1" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline,
                MediaCodecInfo.CodecProfileLevel.AVCLevel31
            )
            "H264_Baseline_3_2" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline,
                MediaCodecInfo.CodecProfileLevel.AVCLevel32
            )
            "H264_Baseline_4_0" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline,
                MediaCodecInfo.CodecProfileLevel.AVCLevel4
            )
            "H264_Baseline_4_1" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline,
                MediaCodecInfo.CodecProfileLevel.AVCLevel41
            )
            "H264_Baseline_4_2" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline,
                MediaCodecInfo.CodecProfileLevel.AVCLevel42
            )
            "H264_Baseline_5_0" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline,
                MediaCodecInfo.CodecProfileLevel.AVCLevel5
            )
            "H264_Baseline_5_1" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline,
                MediaCodecInfo.CodecProfileLevel.AVCLevel51
            )
            "H264_Baseline_5_2" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline,
                MediaCodecInfo.CodecProfileLevel.AVCLevel52
            )
            "H264_Main_3_1" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileMain,
                MediaCodecInfo.CodecProfileLevel.AVCLevel31
            )
            "H264_Main_3_2" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileMain,
                MediaCodecInfo.CodecProfileLevel.AVCLevel32
            )
            "H264_Main_4_0" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileMain,
                MediaCodecInfo.CodecProfileLevel.AVCLevel4
            )
            "H264_Main_4_1" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileMain,
                MediaCodecInfo.CodecProfileLevel.AVCLevel41
            )
            "H264_Main_4_2" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileMain,
                MediaCodecInfo.CodecProfileLevel.AVCLevel42
            )
            "H264_Main_5_0" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileMain,
                MediaCodecInfo.CodecProfileLevel.AVCLevel5
            )
            "H264_Main_5_1" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileMain,
                MediaCodecInfo.CodecProfileLevel.AVCLevel51
            )
            "H264_Main_5_2" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileMain,
                MediaCodecInfo.CodecProfileLevel.AVCLevel52
            )
            "H264_High_3_1" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileHigh,
                MediaCodecInfo.CodecProfileLevel.AVCLevel31
            )
            "H264_High_3_2" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileHigh,
                MediaCodecInfo.CodecProfileLevel.AVCLevel32
            )
            "H264_High_4_0" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileHigh,
                MediaCodecInfo.CodecProfileLevel.AVCLevel4
            )
            "H264_High_4_1" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileHigh,
                MediaCodecInfo.CodecProfileLevel.AVCLevel41
            )
            "H264_High_4_2" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileHigh,
                MediaCodecInfo.CodecProfileLevel.AVCLevel42
            )
            "H264_High_5_0" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileHigh,
                MediaCodecInfo.CodecProfileLevel.AVCLevel5
            )
            "H264_High_5_1" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileHigh,
                MediaCodecInfo.CodecProfileLevel.AVCLevel51
            )
            "H264_High_5_2" -> Pair(
                MediaCodecInfo.CodecProfileLevel.AVCProfileHigh,
                MediaCodecInfo.CodecProfileLevel.AVCLevel52
            )
            else -> null // iOS 전용 또는 지원하지 않는 프로파일
        }
    }
}
