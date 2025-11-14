import { ExpoHaishinkitView, ExpoHaishinkitViewRef } from "expo-haishinkit";
import React, { useRef, useState } from "react";
import {
  Button,
  ScrollView,
  Text,
  TextInput,
  View,
  Platform,
  Alert,
  StyleSheet,
} from "react-native";

export default function App() {
  const viewRef = useRef<ExpoHaishinkitViewRef>(null);
  const [url, setUrl] = useState("rtmp://a.rtmp.youtube.com/live2");
  const [streamName, setStreamName] = useState("test");
  const [isStreaming, setIsStreaming] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState("");
  const [camera, setCamera] = useState<"front" | "back">("back");

  const handleStartStreaming = () => {
    viewRef.current?.startPublishing();
    // ingesting state is now managed by native events
  };

  const handleStopStreaming = () => {
    viewRef.current?.stopPublishing();
    // ingesting state is now managed by native events
  };

  return (
    <View style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>RTMP Streaming Example</Text>

        <View style={styles.group}>
          <Text style={styles.groupHeader}>Stream Preview</Text>
          <ExpoHaishinkitView
            ref={viewRef}
            url={url}
            streamName={streamName}
            camera={camera}
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
    </View>
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
