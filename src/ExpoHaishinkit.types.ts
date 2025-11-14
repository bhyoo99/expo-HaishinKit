import type { StyleProp, ViewStyle } from "react-native";

export type ConnectionStatusPayload = {
  code: string;
  level: string;
  description: string;
};

export type StreamStatusPayload = {
  code: string;
  level: string;
  description: string;
};

export type CameraPosition = "front" | "back";

// Flutter의 ProfileLevel enum과 동일
export const ProfileLevel = {
  // 공통 프로파일 (iOS & Android)
  H264_Baseline_3_1: "H264_Baseline_3_1",
  H264_Baseline_3_2: "H264_Baseline_3_2",
  H264_Baseline_4_0: "H264_Baseline_4_0",
  H264_Baseline_4_1: "H264_Baseline_4_1",
  H264_Baseline_4_2: "H264_Baseline_4_2",
  H264_Baseline_5_0: "H264_Baseline_5_0",
  H264_Baseline_5_1: "H264_Baseline_5_1",
  H264_Baseline_5_2: "H264_Baseline_5_2",
  H264_High_3_1: "H264_High_3_1",
  H264_High_3_2: "H264_High_3_2",
  H264_High_4_0: "H264_High_4_0",
  H264_High_4_1: "H264_High_4_1",
  H264_High_4_2: "H264_High_4_2",
  H264_High_5_0: "H264_High_5_0",
  H264_High_5_1: "H264_High_5_1",
  H264_High_5_2: "H264_High_5_2",
  H264_Main_3_1: "H264_Main_3_1",
  H264_Main_3_2: "H264_Main_3_2",
  H264_Main_4_0: "H264_Main_4_0",
  H264_Main_4_1: "H264_Main_4_1",
  H264_Main_4_2: "H264_Main_4_2",
  H264_Main_5_0: "H264_Main_5_0",
  H264_Main_5_1: "H264_Main_5_1",
  H264_Main_5_2: "H264_Main_5_2",

  // iOS 전용 (Flutter와 동일)
  H264_Baseline_1_3: "H264_Baseline_1_3",
  H264_Baseline_3_0: "H264_Baseline_3_0",
  H264_Extended_5_0: "H264_Extended_5_0",
  H264_Extended_AutoLevel: "H264_Extended_AutoLevel",
  H264_High_3_0: "H264_High_3_0",
  H264_Main_3_0: "H264_Main_3_0",
  H264_Baseline_AutoLevel: "H264_Baseline_AutoLevel",
  H264_Main_AutoLevel: "H264_Main_AutoLevel",
  H264_High_AutoLevel: "H264_High_AutoLevel",

  // iOS 15.0+ 전용
  H264_ConstrainedBaseline_AutoLevel: "H264_ConstrainedBaseline_AutoLevel",
  H264_ConstrainedHigh_AutoLevel: "H264_ConstrainedHigh_AutoLevel",
} as const;

export type ProfileLevelType = (typeof ProfileLevel)[keyof typeof ProfileLevel];

export type VideoSettings = {
  width?: number;
  height?: number;
  bitrate?: number;
  frameInterval?: number;
  profileLevel?: ProfileLevelType;
};

export type AudioSettings = {
  bitrate?: number;
};

export type ExpoHaishinkitViewProps = {
  url?: string;
  streamName?: string;
  camera?: CameraPosition; // 기본값: 'back'
  videoSettings?: VideoSettings;
  audioSettings?: AudioSettings;
  onConnectionStatusChange?: (event: {
    nativeEvent: ConnectionStatusPayload;
  }) => void;
  onStreamStatusChange?: (event: { nativeEvent: StreamStatusPayload }) => void;
  style?: StyleProp<ViewStyle>;
};
