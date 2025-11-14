import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

import { ExpoHaishinkitViewProps } from "./ExpoHaishinkit.types";

const NativeView: React.ComponentType<ExpoHaishinkitViewProps> =
  requireNativeViewManager("ExpoHaishinkit");

export interface ExpoHaishinkitViewRef {
  startPublishing: () => void;
  stopPublishing: () => void;
}

const ExpoHaishinkitView = React.forwardRef<
  ExpoHaishinkitViewRef,
  ExpoHaishinkitViewProps
>((props, ref) => {
  const nativeRef = React.useRef<any>(null);

  React.useImperativeHandle(ref, () => ({
    startPublishing: () => {
      nativeRef.current?.startPublishing();
    },
    stopPublishing: () => {
      nativeRef.current?.stopPublishing();
    },
  }));

  return <NativeView ref={nativeRef} {...props} />;
});

ExpoHaishinkitView.displayName = "ExpoHaishinkitView";

export default ExpoHaishinkitView;
