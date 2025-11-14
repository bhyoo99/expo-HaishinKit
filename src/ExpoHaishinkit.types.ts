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

export type ExpoHaishinkitViewProps = {
  url?: string;
  streamName?: string;
  onConnectionStatusChange?: (event: {
    nativeEvent: ConnectionStatusPayload;
  }) => void;
  onStreamStatusChange?: (event: { nativeEvent: StreamStatusPayload }) => void;
  style?: StyleProp<ViewStyle>;
};
