import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:simple_permissions/simple_permissions.dart';

/*

Used the camera and asks for permissions at startup
http://www.voidrealms.com

Notes
https://pub.dartlang.org/packages/simple_permissions
https://pub.dartlang.org/packages/camera
Be sure to add the permissions into the Manifest.xml and set the minSdkVersion 21 in build.gradle
Permissions:
Permission.RecordAudio
Permission.Camera
Permission.WriteExternalStorage
Permission.ReadExternalStorage
Permission.AccessCoarseLocation
Permission.AccessFineLocation
Permission.WhenInUseLocation
Permission.AlwaysLocation
Permission.ReadContacts
Permission.Vibrate
Permission.WriteContacts

 */

List<CameraDescription> cameras;
Permission permissionFromString(String value) {
  Permission permission;
  for(Permission item in Permission.values) {
    if(item.toString() == value) {
      permission = item;
      break;
    }
  }
  return permission;
}

void main() async {
  cameras = await availableCameras();


  await SimplePermissions.requestPermission(permissionFromString('Permission.WriteExternalStorage'));


  runApp(new MaterialApp(
    home: new MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _State createState() => new _State();
}

class _State extends State<MyApp> {

  CameraController controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Permission _permissionCamera;
  Permission _permissionStorage;

  @override
  void initState() {
    super.initState();
    controller = new CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });

    _permissionCamera = permissionFromString('Permission.Camera');
    _permissionStorage = permissionFromString('Permission.WriteExternalStorage');
    SimplePermissions.requestPermission(_permissionStorage).then((bool value) => print('Asked for Camera permission = ${value}'));
    SimplePermissions.requestPermission(_permissionCamera).then((bool value) => print('Asked for Storage permission = ${value}'));
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();

  }




  Future<String> saveImage() async {

    String timestamp = new DateTime.now().millisecondsSinceEpoch.toString();


    String filePath = '/storage/emulated/0/Pictures/${timestamp}.jpg';

    if (controller.value.isTakingPicture) return null;

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      showInSnackBar('Could not take picture:' + e.toString());
      print(e.toString());
      return null;
    }
    return filePath;
  }

  void takePicture() async {

    bool hasCamera = await SimplePermissions.checkPermission(_permissionCamera);
    bool hasStorage = await SimplePermissions.checkPermission(_permissionStorage);

    if(!hasCamera) {
      showInSnackBar('Lacking permissions to Camera!');
      //Should have this already but...
      bool req = await SimplePermissions.requestPermission(_permissionCamera);
      hasCamera = await SimplePermissions.checkPermission(_permissionCamera);
      if(!hasCamera) {
        showInSnackBar('This application wont work without permissions to the Camera!');
        return;
      }

    }

    if(!hasStorage) {
      showInSnackBar('Lacking permissions to Storage!');
      bool req = await SimplePermissions.requestPermission(_permissionStorage);
      hasStorage = await SimplePermissions.checkPermission(_permissionStorage);
      if(!hasStorage) {
        showInSnackBar('This application wont work without permissions to the Storage!');
        return;
      }
    }

    saveImage().then((String filePath) {
      if (mounted && filePath != null) showInSnackBar('Picture saved to $filePath');
    });
  }

  void showInSnackBar(String message) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(message)));
  }

  Permission permissionFromString(String value) {
    Permission permission;
    for(Permission item in Permission.values) {
      if(item.toString() == value) {
        permission = item;
        break;
      }
    }
    return permission;
  }

  @override
  Widget build(BuildContext context) {

    if (!controller.value.isInitialized) {
      return new Container();
    }

    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text('Name here'),
      ),
      body: new Container(
        padding: new EdgeInsets.all(32.0),
        child: new Center(
          child: new Column(
            children: <Widget>[
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new RaisedButton(onPressed: takePicture, child: new Text('Take Picture'),),
                  new RaisedButton(onPressed: SimplePermissions.openSettings, child: new Text('App Properties'),),
                ],
              ),
              new AspectRatio(
                  aspectRatio:
                  controller.value.aspectRatio,
                  child: new CameraPreview(controller)),
            ],
          ),
        ),
      ),
    );
  }
}
