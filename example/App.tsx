import {
  ExpoHaishinkitView,
  ExpoHaishinkitViewRef,
  VideoSettings,
  AudioSettings,
  ProfileLevel,
} from "expo-haishinkit";
import React, { useRef, useState, useEffect } from "react";
import {
  Button,
  ScrollView,
  Text,
  TextInput,
  View,
  Platform,
  Alert,
  StyleSheet,
  SafeAreaView,
} from "react-native";
import { Camera } from "expo-camera";
import { Audio } from "expo-av";

export default function App() {
  const viewRef = useRef<ExpoHaishinkitViewRef>(null);
  const [url, setUrl] = useState("rtmp://a.rtmp.youtube.com/live2");
  const [streamName, setStreamName] = useState(
    process.env.EXPO_PUBLIC_RTMP_KEY
  );
  const [isStreaming, setIsStreaming] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState("");
  const [camera, setCamera] = useState<"front" | "back">("back");
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [videoSettings, setVideoSettings] = useState<VideoSettings | undefined>(
    undefined
  );
  const [audioSettings, setAudioSettings] = useState<AudioSettings | undefined>(
    undefined
  );
  const [isMuted, setIsMuted] = useState(false);

  useEffect(() => {
    (async () => {
      // 플랫폼별 권한 요청
      if (Platform.OS === "ios") {
        const cameraStatus = await Camera.requestCameraPermissionsAsync();
        const audioStatus = await Audio.requestPermissionsAsync();

        setHasPermission(
          cameraStatus.status === "granted" && audioStatus.status === "granted"
        );
      } else if (Platform.OS === "android") {
        // Android는 Camera와 Audio 권한을 함께 요청
        const cameraStatus = await Camera.requestCameraPermissionsAsync();
        const audioStatus = await Audio.requestPermissionsAsync();

        setHasPermission(
          cameraStatus.status === "granted" && audioStatus.status === "granted"
        );
      }
    })();
  }, []);

  const handleStartStreaming = () => {
    viewRef.current?.startPublishing();
    // ingesting state is now managed by native events
  };

  const handleStopStreaming = () => {
    viewRef.current?.stopPublishing();
    // ingesting state is now managed by native events
  };

  // 권한이 없을 때 표시할 화면
  if (hasPermission === null) {
    return (
      <SafeAreaView style={styles.container}>
        <Text style={styles.header}>Requesting permissions...</Text>
      </SafeAreaView>
    );
  }

  if (hasPermission === false) {
    return (
      <SafeAreaView style={styles.container}>
        <Text style={styles.header}>Camera & Microphone Access Required</Text>
        <Text style={styles.info}>
          Please grant camera and microphone permissions in your device settings
          to use this app.
        </Text>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>RTMP Streaming Example</Text>

        <View style={styles.group}>
          <Text style={styles.groupHeader}>Stream Preview</Text>
          <ExpoHaishinkitView
            ref={viewRef}
            url={url}
            streamName={streamName}
            camera={camera}
            videoSettings={videoSettings}
            audioSettings={audioSettings}
            muted={isMuted}
            onConnectionStatusChange={(event) => {
              const status = event.nativeEvent;
              console.log("Connection status:", status);
              setConnectionStatus(`${status.code}: ${status.description}`);

              if (status.code === "NetConnection.Connect.Success") {
                Alert.alert(
                  "Connected",
                  "Successfully connected to RTMP server"
                );
                setIsStreaming(true); // Update state based on native event
              } else if (
                status.code === "NetConnection.Connect.Closed" ||
                status.code === "NetConnection.Connect.Failed"
              ) {
                setIsStreaming(false); // Update state based on native event
              }
            }}
            onStreamStatusChange={(event) => {
              const status = event.nativeEvent;
              console.log("Stream status:", status);

              if (status.code === "NetStream.Publish.Start") {
                Alert.alert("Publishing", "Stream is now publishing");
              }
            }}
            style={styles.preview}
          />
        </View>

        <View style={styles.group}>
          <Text style={styles.groupHeader}>Connection Settings</Text>
          <TextInput
            style={styles.input}
            value={url}
            onChangeText={setUrl}
            placeholder="RTMP URL"
            autoCapitalize="none"
            autoCorrect={false}
          />
          <TextInput
            style={styles.input}
            value={streamName}
            onChangeText={setStreamName}
            placeholder="Stream Name"
            autoCapitalize="none"
            autoCorrect={false}
          />
        </View>

        <View style={styles.group}>
          <Text style={styles.groupHeader}>Controls</Text>
          <View style={styles.buttonRow}>
            <Button
              title={isStreaming ? "Stop Streaming" : "Start Streaming"}
              onPress={isStreaming ? handleStopStreaming : handleStartStreaming}
            />
            <Button
              title={camera === "front" ? "📷 Back" : "🤳 Front"}
              onPress={() =>
                setCamera((prev) => (prev === "front" ? "back" : "front"))
              }
            />
            <Button
              title={isMuted ? "🔇 Unmute" : "🔊 Mute"}
              onPress={() => setIsMuted((prev) => !prev)}
            />
          </View>
          <View style={styles.buttonRow}>
            <Button
              title="HD 720p"
              onPress={() => {
                // 720p 30fps 고화질 설정
                setVideoSettings({
                  width: 1280,
                  height: 720,
                  bitrate: 2000 * 1000, // 2Mbps
                  frameInterval: 2, // GOP duration
                  profileLevel: ProfileLevel.H264_High_AutoLevel,
                });
                setAudioSettings({
                  bitrate: 128 * 1000, // 128kbps
                });
                Alert.alert("Quality", "Set to HD 720p @ 2Mbps");
              }}
            />
            <Button
              title="SD 480p"
              onPress={() => {
                // 480p 30fps 표준 화질 설정
                setVideoSettings({
                  width: 854,
                  height: 480,
                  bitrate: 800 * 1000, // 800kbps
                  frameInterval: 2, // GOP duration
                  profileLevel: ProfileLevel.H264_Baseline_AutoLevel,
                });
                setAudioSettings({
                  bitrate: 80 * 1000, // 80kbps
                });
                Alert.alert("Quality", "Set to SD 480p @ 800kbps");
              }}
            />
          </View>
          {connectionStatus ? (
            <Text style={styles.status}>Status: {connectionStatus}</Text>
          ) : null}
        </View>

        <View style={styles.group}>
          <Text style={styles.info}>
            {Platform.OS === "ios"
              ? "Make sure to add camera and microphone permissions in Info.plist"
              : "Make sure to add camera and microphone permissions in AndroidManifest.xml"}
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  header: {
    fontSize: 30,
    margin: 20,
    textAlign: "center",
  },
  groupHeader: {
    fontSize: 20,
    marginBottom: 10,
    fontWeight: "bold",
  },
  group: {
    margin: 20,
    backgroundColor: "#fff",
    borderRadius: 10,
    padding: 20,
  },
  container: {
    flex: 1,
    backgroundColor: "#eee",
  },
  preview: {
    width: "100%",
    height: 300,
    backgroundColor: "#000",
    borderRadius: 10,
  },
  input: {
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 5,
    padding: 10,
    marginBottom: 10,
    fontSize: 16,
  },
  buttonRow: {
    flexDirection: "row",
    justifyContent: "space-around",
    marginTop: 10,
  },
  status: {
    marginTop: 10,
    fontSize: 14,
    color: "#666",
  },
  info: {
    fontSize: 12,
    color: "#666",
    textAlign: "center",
  },
});
