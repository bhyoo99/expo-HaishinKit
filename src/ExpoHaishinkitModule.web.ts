import { registerWebModule, NativeModule } from 'expo';

import { ExpoHaishinkitModuleEvents } from './ExpoHaishinkit.types';

class ExpoHaishinkitModule extends NativeModule<ExpoHaishinkitModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoHaishinkitModule, 'ExpoHaishinkitModule');
