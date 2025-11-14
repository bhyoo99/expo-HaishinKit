import { NativeModule, requireNativeModule } from 'expo';

import { ExpoHaishinkitModuleEvents } from './ExpoHaishinkit.types';

declare class ExpoHaishinkitModule extends NativeModule<ExpoHaishinkitModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoHaishinkitModule>('ExpoHaishinkit');
