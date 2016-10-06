# react-native-asset-resizer
Native module for resizing images with asset uri while attempting to keep metadata (IOS Only)

Caveats:
This is meant to be used on images to be uploaded to server, therefore we keep scale at 1.0
Will only accept a hardcoded width/height. In the future a maxWidth/maxHeight option may be available
Converts all images to jpegs with 75% quality. In the future the quality value will be configurable. 

## Installation

1. `npm install react-native-asset-resizer --save`
2. `react-native link react-native-asset-resizer`

## Usage

```javascript
import React, {Component} from 'react';
import RNAssetResizer from  'react-native-asset-resizer';
import RNFS from 'react-native-fs';

class MyComponent extends Component {
  ...
  ...
  ...

  _getUploadDir() {
    // create temp path as needed for resized images
    var path = RNFS.DocumentDirectoryPath + '/TravelCoTmp';

    // write the file
    // exclude this directory from icloud backup or apple will reject
    RNFS.mkdir(path, { NSURLIsExcludedFromBackupKey: true })
      .then((success) => {
        return path;
      })
      .catch((err) => {
        console.log(err.message);
        return null;
      });
      // already created
       return path;
  }

  someMethod() {
    const uploadDir = _getUploadDir();

    RNAssetResizer.resizeAsset(imageUri, 1080, 868, this._getUploadDir)
      .then ((filePath) => {
        console.log("File Path: " + filePath);
        return;
      })
      .catch ((err) => {
        return;
      });
  }

}
```