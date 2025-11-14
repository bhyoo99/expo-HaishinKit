import * as React from 'react';

import { ExpoHaishinkitViewProps } from './ExpoHaishinkit.types';

export default function ExpoHaishinkitView(props: ExpoHaishinkitViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
