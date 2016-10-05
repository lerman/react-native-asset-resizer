import {
  NativeModules,
} from 'react-native';

export default {
  resizeAsset: (assetPath, maxWidth, maxHeight, outputPath) => {
    return NativeModules.RNAssetResizer.resizeAsset(assetPath, maxWidth, maxHeight, outputPath);
  },
};
