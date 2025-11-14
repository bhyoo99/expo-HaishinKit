import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoHaishinkitViewProps } from './ExpoHaishinkit.types';

const NativeView: React.ComponentType<ExpoHaishinkitViewProps> =
  requireNativeView('ExpoHaishinkit');

export default function ExpoHaishinkitView(props: ExpoHaishinkitViewProps) {
  return <NativeView {...props} />;
}
