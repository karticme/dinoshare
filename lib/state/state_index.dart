import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show Clipboard, MethodChannel, PlatformException;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/transfer_service.dart';
export '../core/transfer_service.dart';

part 'app_state_store.dart';
part 'app_state_models.dart';
part 'app_state_favorites.dart';
part 'app_state_settings.dart';
part 'app_state_share.dart';
part 'app_state_history.dart';
