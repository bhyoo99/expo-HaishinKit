import VideoToolbox

// Flutter ProfileLevel.swift와 동일한 구조
public struct ProfileLevel {
  public static func getProfileLevelConstant(from string: String) -> String? {
    switch string {
    case "H264_Baseline_1_3": return kVTProfileLevel_H264_Baseline_1_3 as String
    case "H264_Baseline_3_0": return kVTProfileLevel_H264_Baseline_3_0 as String
    case "H264_Baseline_3_1": return kVTProfileLevel_H264_Baseline_3_1 as String
    case "H264_Baseline_3_2": return kVTProfileLevel_H264_Baseline_3_2 as String
    case "H264_Baseline_4_0": return kVTProfileLevel_H264_Baseline_4_0 as String
    case "H264_Baseline_4_1": return kVTProfileLevel_H264_Baseline_4_1 as String
    case "H264_Baseline_4_2": return kVTProfileLevel_H264_Baseline_4_2 as String
    case "H264_Baseline_5_0": return kVTProfileLevel_H264_Baseline_5_0 as String
    case "H264_Baseline_5_1": return kVTProfileLevel_H264_Baseline_5_1 as String
    case "H264_Baseline_5_2": return kVTProfileLevel_H264_Baseline_5_2 as String
    case "H264_Baseline_AutoLevel": return kVTProfileLevel_H264_Baseline_AutoLevel as String
    case "H264_ConstrainedBaseline_AutoLevel":
      if #available(iOS 15.0, *) {
        return kVTProfileLevel_H264_ConstrainedBaseline_AutoLevel as String
      } else {
        return kVTProfileLevel_H264_Baseline_AutoLevel as String
      }
    case "H264_ConstrainedHigh_AutoLevel":
      if #available(iOS 15.0, *) {
        return kVTProfileLevel_H264_ConstrainedHigh_AutoLevel as String
      } else {
        return kVTProfileLevel_H264_High_AutoLevel as String
      }
    case "H264_Extended_5_0": return kVTProfileLevel_H264_Extended_5_0 as String
    case "H264_Extended_AutoLevel": return kVTProfileLevel_H264_Extended_AutoLevel as String
    case "H264_High_3_0": return kVTProfileLevel_H264_High_3_0 as String
    case "H264_High_3_1": return kVTProfileLevel_H264_High_3_1 as String
    case "H264_High_3_2": return kVTProfileLevel_H264_High_3_2 as String
    case "H264_High_4_0": return kVTProfileLevel_H264_High_4_0 as String
    case "H264_High_4_1": return kVTProfileLevel_H264_High_4_1 as String
    case "H264_High_4_2": return kVTProfileLevel_H264_High_4_2 as String
    case "H264_High_5_0": return kVTProfileLevel_H264_High_5_0 as String
    case "H264_High_5_1": return kVTProfileLevel_H264_High_5_1 as String
    case "H264_High_5_2": return kVTProfileLevel_H264_High_5_2 as String
    case "H264_High_AutoLevel": return kVTProfileLevel_H264_High_AutoLevel as String
    case "H264_Main_3_0": return kVTProfileLevel_H264_Main_3_0 as String
    case "H264_Main_3_1": return kVTProfileLevel_H264_Main_3_1 as String
    case "H264_Main_3_2": return kVTProfileLevel_H264_Main_3_2 as String
    case "H264_Main_4_0": return kVTProfileLevel_H264_Main_4_0 as String
    case "H264_Main_4_1": return kVTProfileLevel_H264_Main_4_1 as String
    case "H264_Main_4_2": return kVTProfileLevel_H264_Main_4_2 as String
    case "H264_Main_5_0": return kVTProfileLevel_H264_Main_5_0 as String
    case "H264_Main_5_1": return kVTProfileLevel_H264_Main_5_1 as String
    case "H264_Main_5_2": return kVTProfileLevel_H264_Main_5_2 as String
    case "H264_Main_AutoLevel": return kVTProfileLevel_H264_Main_AutoLevel as String
    default: return nil
    }
  }
}
