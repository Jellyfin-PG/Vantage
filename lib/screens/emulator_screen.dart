











import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/jellyfin_api.dart';
import '../services/prefs.dart';
import 'package:gamepads/gamepads.dart';
import 'dart:async';
import 'dart:convert';



const _channel = MethodChannel('com.retrostream.vantage/emulator');

enum ScalingMode {
  stretch,
  fit,
  originalAspectRatio,
}

class EmulatorScreen extends StatefulWidget {
  final String romPath;
  final String corePath;
  final String title;
  final String? itemId;
  final String serverUrl;
  final String token;
  final String userId;

  const EmulatorScreen({
    super.key,
    required this.romPath,
    required this.corePath,
    required this.title,
    this.itemId,
    required this.serverUrl,
    required this.token,
    required this.userId,
  });

  @override
  State<EmulatorScreen> createState() => _EmulatorScreenState();
}

class _EmulatorScreenState extends State<EmulatorScreen>
    with WidgetsBindingObserver {
  bool _paused = false;
  bool _showVirtualPad = false; 
  int? _textureId;
  bool _showDock = false;
  bool _dockMinimized = true;
  bool _showInputMapping = false;
  double _volume = 1.0;
  bool _fastForward = false;
  bool _slowMotion = false;
  int? _bindingRetroId;
  bool _bindingIsGamepad = false;
  double _coreAspectRatio = 4.0 / 3.0;
  ScalingMode _scalingMode = ScalingMode.fit;
  final FocusNode _focusNode = FocusNode();
  Offset _bubblePos = const Offset(32, 100);
  final _api = JellyfinApi();
  StreamSubscription? _gamepadSub;
  final _prefs = Prefs();
  
  static final Map<String, int> _defaultGamepadMap = Platform.isAndroid ? {
    
    'button_0': 8, 
    'button_1': 0, 
    'button_2': 9, 
    'button_3': 1, 
    'button_4': 10, 
    'button_5': 11, 
    'button_6': 2, 
    'button_7': 3, 
    'button_8': 14, 
    'button_9': 15, 
    'dpad_up': 4,
    'dpad_down': 5,
    'dpad_left': 6,
    'dpad_right': 7,
  } : {
    
    'a': 8, 
    'b': 0, 
    'x': 9, 
    'y': 1, 
    'leftShoulder': 10, 
    'rightShoulder': 11, 
    'view': 2, 
    'menu': 3, 
    'leftThumbstickClick': 14, 
    'rightThumbstickClick': 15, 
    'dpadUp': 4,
    'dpadDown': 5,
    'dpadLeft': 6,
    'dpadRight': 7,
  };

  static final Map<LogicalKeyboardKey, int> _defaultKeyMap = {
    LogicalKeyboardKey.arrowUp: 4,
    LogicalKeyboardKey.arrowDown: 5,
    LogicalKeyboardKey.arrowLeft: 6,
    LogicalKeyboardKey.arrowRight: 7,
    LogicalKeyboardKey.keyX: 8, 
    LogicalKeyboardKey.keyZ: 0, 
    LogicalKeyboardKey.keyS: 9, 
    LogicalKeyboardKey.keyA: 1, 
    LogicalKeyboardKey.enter: 3, 
    LogicalKeyboardKey.shiftLeft: 2, 
    LogicalKeyboardKey.keyQ: 10, 
    LogicalKeyboardKey.keyW: 11, 
    LogicalKeyboardKey.keyE: 12, 
    LogicalKeyboardKey.keyR: 13, 

    
    LogicalKeyboardKey.gameButtonA: 8,
    LogicalKeyboardKey.gameButtonB: 0,
    LogicalKeyboardKey.gameButtonX: 9,
    LogicalKeyboardKey.gameButtonY: 1,
    LogicalKeyboardKey.gameButtonStart: 3,
    LogicalKeyboardKey.gameButtonSelect: 2,
    LogicalKeyboardKey.gameButtonLeft1: 10,
    LogicalKeyboardKey.gameButtonRight1: 11,
  };

  Map<String, int> _gamepadMap = Map.from(_defaultGamepadMap);
  Map<LogicalKeyboardKey, int> _keyMap = Map.from(_defaultKeyMap);

  void _resetKeyboardMapping() {
    setState(() {
      _keyMap = Map.from(_defaultKeyMap);
    });
    _saveKeyMap();
  }

  void _resetGamepadMapping() {
    setState(() {
      _gamepadMap = Map.from(_defaultGamepadMap);
    });
    _saveGamepadMap();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInputMap();
    _launch();
    _focusNode.requestFocus();
    _initGamepads();
  }

  Future<void> _loadInputMap() async {
    try {
      final keyMapStr = await _prefs.keyMapJson;
      if (keyMapStr != null && keyMapStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(keyMapStr);
        final Map<LogicalKeyboardKey, int> loadedMap = {};
        for (final entry in decoded.entries) {
          loadedMap[LogicalKeyboardKey(int.parse(entry.key))] = entry.value as int;
        }
        if (mounted) setState(() {
          
          final actionsInLoadedMap = loadedMap.values.toSet();
          _keyMap.removeWhere((k, v) => actionsInLoadedMap.contains(v));
          _keyMap.addAll(loadedMap);
        });
      }

      final gamepadMapStr = await _prefs.gamepadMapJson;
      if (gamepadMapStr != null && gamepadMapStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(gamepadMapStr);
        final Map<String, int> loadedMap = {};
        for (final entry in decoded.entries) {
          loadedMap[entry.key] = entry.value as int;
        }
        if (mounted) setState(() {
          
          final actionsInLoadedMap = loadedMap.values.toSet();
          _gamepadMap.removeWhere((k, v) => actionsInLoadedMap.contains(v));
          _gamepadMap.addAll(loadedMap);
        });
      }
    } catch (e) {
      debugPrint('Failed to load input map: $e');
    }
  }

  Future<void> _saveKeyMap() async {
    final Map<String, int> mapToSave = {};
    for (final entry in _keyMap.entries) {
      mapToSave[entry.key.keyId.toString()] = entry.value;
    }
    await _prefs.setKeyMapJson(jsonEncode(mapToSave));
  }

  Future<void> _saveGamepadMap() async {
    await _prefs.setGamepadMapJson(jsonEncode(_gamepadMap));
  }

  void _initGamepads() {
    _gamepadSub = Gamepads.events.listen((event) {
      if (!mounted) return;

      
      if (_bindingRetroId != null) {
        if (event.type == KeyType.button && event.value > 0) {
          setState(() {
            
            _gamepadMap.removeWhere((k, v) => k == event.key);
            
            _gamepadMap.removeWhere((k, v) => v == _bindingRetroId);
            
            _gamepadMap[event.key] = _bindingRetroId!;
          });
          _saveGamepadMap();
          return;
        } else if (event.type == KeyType.button && event.value == 0) {
          
          setState(() => _bindingRetroId = null);
          return;
        } else if (event.type == KeyType.analog && event.value.abs() > 0.5) {
          setState(() {
            
            final keyWithPolarity = '${event.key}${event.value > 0 ? '+' : '-'}';
            
            
            _gamepadMap.removeWhere((k, v) => k == keyWithPolarity);
            _gamepadMap.removeWhere((k, v) => v == _bindingRetroId);

            _gamepadMap[keyWithPolarity] = _bindingRetroId!;
            
            _gamepadMap[event.key] = _bindingRetroId!;
            _bindingRetroId = null;
          });
          _saveGamepadMap();
          return;
        }
      }

      
      
      if (event.type == KeyType.analog && event.value.abs() < 0.2) {
        final idPlus = _gamepadMap['${event.key}+'];
        if (idPlus != null && idPlus < 100) _channel.invokeMethod('keyUp', {'keyCode': _toPlatformKeyCode(idPlus)});
        
        final idMinus = _gamepadMap['${event.key}-'];
        if (idMinus != null && idMinus < 100) _channel.invokeMethod('keyUp', {'keyCode': _toPlatformKeyCode(idMinus)});
        
        final idBase = _gamepadMap[event.key];
        if (idBase != null && idBase >= 100) {
           _channel.invokeMethod('setAnalog', {
             'index': (idBase >= 104) ? 1 : 0, 
             'id': (idBase == 100 || idBase == 101 || idBase == 104 || idBase == 105) ? 0 : 1,
             'value': 0,
          });
        }
        return;
      }

      String lookupKey = event.key;
      if (event.type == KeyType.analog) {
        lookupKey = '${event.key}${event.value > 0 ? '+' : '-'}';
      }

      int? retroId = _gamepadMap[lookupKey];
      if (retroId == null && event.type == KeyType.analog) {
        retroId = _gamepadMap[event.key];
      }

      if (retroId != null) {
        if (retroId >= 100) {
          
          int value = 0;
          if (event.type == KeyType.analog) {
            value = (event.value * 32767).toInt();
          } else if (event.type == KeyType.button) {
            if (event.value > 0) {
              value = (retroId % 2 == 0) ? -32767 : 32767;
            } else {
              value = 0;
            }
          }
          
          _channel.invokeMethod('setAnalog', {
             'index': (retroId >= 104) ? 1 : 0, 
             'id': (retroId == 100 || retroId == 101 || retroId == 104 || retroId == 105) ? 0 : 1,
             'value': value,
          });
        } else {
          
          if (event.type == KeyType.button) {
            final method = event.value > 0 ? 'keyDown' : 'keyUp';
            _channel.invokeMethod(method, {'keyCode': _toPlatformKeyCode(retroId)});
          } else if (event.type == KeyType.analog) {
            final isPressed = event.value.abs() > 0.5;
            final method = isPressed ? 'keyDown' : 'keyUp';
            _channel.invokeMethod(method, {'keyCode': _toPlatformKeyCode(retroId)});
          }
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _channel.invokeMethod('resetMappingMode');
    _channel.invokeMethod('stop');
    _focusNode.dispose();
    _gamepadSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _channel.invokeMethod('pause');
    } else if (state == AppLifecycleState.resumed && !_paused) {
      _channel.invokeMethod('resume');
    }
  }

  int _toPlatformKeyCode(int retroId) {
    if (!Platform.isAndroid) return retroId;
    switch (retroId) {
      case 0: return 97; 
      case 1: return 100; 
      case 2: return 109; 
      case 3: return 108; 
      case 4: return 19; 
      case 5: return 20; 
      case 6: return 21; 
      case 7: return 22; 
      case 8: return 96; 
      case 9: return 99; 
      case 10: return 102; 
      case 11: return 103; 
      case 12: return 104; 
      case 13: return 105; 
      case 14: return 106; 
      case 15: return 107; 
      default: return retroId;
    }
  }

  Future<void> _launch() async {
    try {
      _channel.invokeMethod('resetMappingMode');
      final dynamic result = await _channel.invokeMethod('launch', {
        'romPath': widget.romPath,
        'corePath': widget.corePath,
      });
      if (mounted) {
        if (result is int) {
          _textureId = result;
        }
        
        final double? ar = await _channel.invokeMethod<double>('getAspectRatio');
        if (ar != null && ar > 0) {
          setState(() {
            _coreAspectRatio = ar;
          });
        }
      }

      
      if (widget.itemId != null) {
        _cloudLoad(silent: true);
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Emulator error: ${e.message}')));
        Navigator.pop(context);
      }
    }
  }

  void _pause() {
    _paused = true;
    _channel.invokeMethod('pause');
  }

  void _resume() {
    _paused = false;
    _channel.invokeMethod('resume');
  }

  void _showPauseMenu() {
    _pause();

    final hasCloud = widget.itemId != null;
    final options = [
      'Resume',
      'Save State',
      'Load State',
      if (hasCloud) 'Cloud Save',
      if (hasCloud) 'Cloud Load',
      'Reset',
      'Exit',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(widget.title,
            style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((opt) => ListTile(
                      title: Text(opt,
                          style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        _handleMenuOption(opt);
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    ).then((_) {
      if (_paused) _resume();
    });
  }

  Future<void> _handleMenuOption(String opt) async {
    switch (opt) {
      case 'Resume':
        _resume();
      case 'Save State':
        await _localSave();
        _resume();
      case 'Load State':
        await _localLoad();
        _resume();
      case 'Cloud Save':
        await _cloudSave();
        _resume();
      case 'Cloud Load':
        await _cloudLoad();
        _resume();
      case 'Reset':
        await _channel.invokeMethod('reset');
        _resume();
      case 'Exit':
        Navigator.pop(context);
    }
  }

  Future<void> _localSave() async {
    try {
      final id = widget.itemId ?? widget.title.hashCode.toString();
      final Uint8List? data = await _channel.invokeMethod<Uint8List>('saveState');
      if (data == null) return;
      
      final directory = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${directory.path}/Vantage/States');
      if (!await saveDir.exists()) await saveDir.create(recursive: true);
      
      final file = File('${saveDir.path}/$id.state');
      await file.writeAsBytes(data);
      
      _snack('State saved for ${widget.title}');
    } catch (e) {
      _snack('Save failed: $e');
    }
  }

  Future<void> _localLoad() async {
    try {
      final id = widget.itemId ?? widget.title.hashCode.toString();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/Vantage/States/$id.state');
      
      if (!await file.exists()) {
        _snack('No save state found for ${widget.title}');
        return;
      }
      
      final data = await file.readAsBytes();
      final bool? success = await _channel.invokeMethod<bool>('loadState', {'state': data});
      
      if (success == true) {
        _snack('State loaded for ${widget.title}');
      } else {
        _snack('Load failed');
      }
    } catch (e) {
      _snack('Load error: $e');
    }
  }

  Future<void> _setVolume(double value) async {
    setState(() => _volume = value);
    await _channel.invokeMethod('setVolume', value);
  }

  void _toggleFastForward() {
    setState(() {
      _fastForward = !_fastForward;
      if (_fastForward) _slowMotion = false; 
    });
    _channel.invokeMethod('setFastForward', _fastForward);
    _channel.invokeMethod('setSlowMotion', _slowMotion);
  }

  void _toggleSlowMotion() {
    setState(() {
      _slowMotion = !_slowMotion;
      if (_slowMotion) _fastForward = false; 
    });
    _channel.invokeMethod('setSlowMotion', _slowMotion);
    _channel.invokeMethod('setFastForward', _fastForward);
  }

  Future<void> _cloudSave() async {
    final id = widget.itemId;
    if (id == null) return;
    try {
      final data = await _channel.invokeMethod<Uint8List>('serializeState');
      if (data == null) return;

      await _api.uploadSave(
        widget.serverUrl,
        widget.token,
        widget.userId,
        id,
        data,
      );

      _snack('CLOUD: UPLINK_SUCCESS');
    } catch (e) {
      _snack('CLOUD: UPLINK_FAILURE [\$e]');
    }
  }

  Future<void> _cloudLoad({bool silent = false}) async {
    final id = widget.itemId;
    if (id == null) return;
    try {
      final data = await _api.downloadSave(
        widget.serverUrl,
        widget.token,
        widget.userId,
        id,
      );

      if (data == null) {
        if (!silent) _snack('CLOUD: NO_RECORD_FOUND');
        return;
      }
      
      await _channel.invokeMethod('unserializeState', {'data': data});
      _snack('CLOUD: DOWNLINK_SUCCESS');
    } catch (e) {
      if (!silent) _snack('CLOUD: DOWNLINK_FAILURE [\$e]');
    }
  }

  Future<bool> _upload(String url, Uint8List data, String contentType) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'MediaBrowser Token="${widget.token}"',
          'Content-Type': contentType,
        },
        body: data,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Upload error: $e');
      return false;
    }
  }

  Future<Uint8List?> _httpGet(Uri uri) async {
    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'MediaBrowser Token="${widget.token}"',
        },
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    
    
    final isNarrowPortrait =
        MediaQuery.of(context).size.aspectRatio < 1 &&
            MediaQuery.of(context).size.shortestSide < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            debugPrint('DEBUG: KeyDown: ${event.logicalKey.debugName} | Label: ${event.logicalKey.keyLabel} | ID: ${event.logicalKey.keyId}');
          }
          
          
          if (_bindingRetroId != null) {
            final keyLabel = event.logicalKey.keyLabel.toLowerCase();
            if (keyLabel.contains('volume') || keyLabel.contains('power') || keyLabel.contains('home')) {
              return KeyEventResult.ignored;
            }

            if (event is KeyDownEvent) {
              setState(() {
                _keyMap.removeWhere((k, v) => k == event.logicalKey);
                _keyMap.removeWhere((k, v) => v == _bindingRetroId);
                
                _keyMap[event.logicalKey] = _bindingRetroId!;
              });
              _saveKeyMap();
            } else if (event is KeyUpEvent) {
              
              setState(() => _bindingRetroId = null);
            }
            return KeyEventResult.handled; 
          }

          
          if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack) {
            if (event is KeyDownEvent) {
              setState(() {
                _showDock = !_showDock;
                if (!_showDock) _focusNode.requestFocus();
              });
            }
            return KeyEventResult.handled;
          }

          
          if (_showDock) {
            final label = event.logicalKey.keyLabel.toLowerCase();
            if (label.contains('arrow') || label.contains('dpad') || 
                event.logicalKey == LogicalKeyboardKey.enter || 
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA ||
                event.logicalKey == LogicalKeyboardKey.gameButtonB) {
              return KeyEventResult.ignored; 
            }
          }

          final libretroId = _keyMap[event.logicalKey];
          if (libretroId != null) {
            if (event is KeyEvent) {
              final method = (event is KeyDownEvent) ? 'keyDown' : 'keyUp';
              if (event is KeyDownEvent || event is KeyUpEvent) {
                if (libretroId < 100) {
                  _channel.invokeMethod(method, {'keyCode': _toPlatformKeyCode(libretroId)});
                } else {
                  
                  final isDown = event is KeyDownEvent;
                  final value = isDown ? 32767 : 0;
                  final negValue = isDown ? -32768 : 0;
                  
                  switch (libretroId) {
                    case 100: _channel.invokeMethod('setAnalog', {'index': 0, 'id': 0, 'value': negValue}); break; 
                    case 101: _channel.invokeMethod('setAnalog', {'index': 0, 'id': 0, 'value': value}); break;    
                    case 102: _channel.invokeMethod('setAnalog', {'index': 0, 'id': 1, 'value': negValue}); break; 
                    case 103: _channel.invokeMethod('setAnalog', {'index': 0, 'id': 1, 'value': value}); break;    
                    case 104: _channel.invokeMethod('setAnalog', {'index': 1, 'id': 0, 'value': negValue}); break; 
                    case 105: _channel.invokeMethod('setAnalog', {'index': 1, 'id': 0, 'value': value}); break;    
                    case 106: _channel.invokeMethod('setAnalog', {'index': 1, 'id': 1, 'value': negValue}); break; 
                    case 107: _channel.invokeMethod('setAnalog', {'index': 1, 'id': 1, 'value': value}); break;    
                  }
                }
              }
            }
            
            return KeyEventResult.handled;
          }
          
          
          
          final label = event.logicalKey.keyLabel.toLowerCase();
          if (label.contains('game button') || label.contains('arrow') || label.contains('dpad')) {
            return KeyEventResult.handled;
          }
          
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            
            Positioned.fill(
              child: _EmulatorSurface(
                textureId: _textureId,
                scalingMode: _scalingMode,
                coreAspectRatio: _coreAspectRatio,
              ),
            ),

            
            if (isNarrowPortrait)
              Positioned.fill(
                child: VirtualGamepad(
                  onButtonDown: (btn) => _channel
                      .invokeMethod('keyDown', {'keyCode': btn}),
                  onButtonUp: (btn) =>
                      _channel.invokeMethod('keyUp', {'keyCode': btn}),
                ),
              ),

            
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _dockMinimized ? -50 : (isNarrowPortrait ? 48 : 24),
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _PremiumDock(
                  onReset: () => _channel.invokeMethod('reset'),
                  onExit: () => Navigator.pop(context),
                  onSave: _localSave,
                  onLoad: _localLoad,
                  onTogglePause: () {
                    if (_paused) _resume(); else _pause();
                    setState(() {});
                  },
                  isPaused: _paused,
                  onMinimize: () => setState(() => _dockMinimized = true),
                  onOpenSettings: () {
                    setState(() => _showInputMapping = true);
                    _channel.invokeMethod('setMappingMode', {'mode': true});
                  },
                  volume: _volume,
                  onVolumeChanged: _setVolume,
                  isFastForward: _fastForward,
                  onToggleFastForward: _toggleFastForward,
                  isSlowMotion: _slowMotion,
                  onToggleSlowMotion: _toggleSlowMotion,
                  scalingMode: _scalingMode,
                  onCycleScaling: () {
                    setState(() {
                      _scalingMode = ScalingMode.values[(_scalingMode.index + 1) % ScalingMode.values.length];
                    });
                  },
                ),
              ),
            ),

            
            if (_dockMinimized)
              Platform.isAndroid 
                ? Positioned(
                    left: _bubblePos.dx,
                    top: _bubblePos.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _bubblePos += details.delta;
                          
                          final size = MediaQuery.of(context).size;
                          _bubblePos = Offset(
                            _bubblePos.dx.clamp(16, size.width - 76),
                            _bubblePos.dy.clamp(16, size.height - 76),
                          );
                        });
                      },
                      onTap: () => setState(() => _dockMinimized = false),
                      child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)
                          ],
                        ),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: const Center(
                              child: Icon(Icons.rocket_launch, color: Color(0xFFFF5C00), size: 28),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _dockMinimized = false),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

            
            if (_showInputMapping)
              _InputMappingOverlay(
                onClose: () {
                  setState(() => _showInputMapping = false);
                  _channel.invokeMethod('setMappingMode', {'mode': false});
                },
                keyMap: _keyMap,
                gamepadMap: _gamepadMap,
                bindingRetroId: _bindingRetroId,
                onStartBind: (id, isGamepad) => setState(() {
                  _bindingRetroId = id;
                  _bindingIsGamepad = isGamepad;
                }),
                onResetKeyboard: _resetKeyboardMapping,
                onResetGamepad: _resetGamepadMapping,
              ),
          ],
        ),
      ),
    );
  }
}

class _InputMappingOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final Map<LogicalKeyboardKey, int> keyMap;
  final Map<String, int> gamepadMap;
  final int? bindingRetroId;
  final Function(int, bool) onStartBind;
  final VoidCallback onResetKeyboard;
  final VoidCallback onResetGamepad;

  const _InputMappingOverlay({
    required this.onClose, 
    required this.keyMap,
    required this.gamepadMap,
    required this.bindingRetroId,
    required this.onStartBind,
    required this.onResetKeyboard,
    required this.onResetGamepad,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: isSmall ? size.width * 0.9 : 650,
            constraints: BoxConstraints(maxHeight: size.height * 0.8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: DefaultTabController(
              length: Platform.isAndroid ? 1 : 2,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Input Mapping", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: onClose),
                      ],
                    ),
                    if (!Platform.isAndroid)
                      const TabBar(
                        tabs: [
                          Tab(text: "Keyboard"),
                          Tab(text: "Gamepad"),
                        ],
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white54,
                        indicatorColor: Color(0xFF6C63FF),
                      ),
                    const SizedBox(height: 16),
                    const Text("Click a button then press a key to bind it", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 16),
                    Flexible(
                      child: Platform.isAndroid
                          ? SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _buildBindingButtons(true),
                              ),
                            )
                          : TabBarView(
                              children: [
                                
                                SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _buildBindingButtons(false),
                                  ),
                                ),
                                
                                SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _buildBindingButtons(true),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                      child: const Text("Done"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBindingButtons(bool isGamepad) {
    return [
      _BindBtn(label: "UP", retroId: 4, currentKey: _getKeyName(4, isGamepad), isBinding: bindingRetroId == 4, onBind: () => onStartBind(4, isGamepad)),
      _BindBtn(label: "DOWN", retroId: 5, currentKey: _getKeyName(5, isGamepad), isBinding: bindingRetroId == 5, onBind: () => onStartBind(5, isGamepad)),
      _BindBtn(label: "LEFT", retroId: 6, currentKey: _getKeyName(6, isGamepad), isBinding: bindingRetroId == 6, onBind: () => onStartBind(6, isGamepad)),
      _BindBtn(label: "RIGHT", retroId: 7, currentKey: _getKeyName(7, isGamepad), isBinding: bindingRetroId == 7, onBind: () => onStartBind(7, isGamepad)),
      const Divider(color: Colors.white12),
      _BindBtn(label: "A", retroId: 8, currentKey: _getKeyName(8, isGamepad), isBinding: bindingRetroId == 8, onBind: () => onStartBind(8, isGamepad)),
      _BindBtn(label: "B", retroId: 0, currentKey: _getKeyName(0, isGamepad), isBinding: bindingRetroId == 0, onBind: () => onStartBind(0, isGamepad)),
      _BindBtn(label: "X", retroId: 9, currentKey: _getKeyName(9, isGamepad), isBinding: bindingRetroId == 9, onBind: () => onStartBind(9, isGamepad)),
      _BindBtn(label: "Y", retroId: 1, currentKey: _getKeyName(1, isGamepad), isBinding: bindingRetroId == 1, onBind: () => onStartBind(1, isGamepad)),
      const Divider(color: Colors.white12),
      _BindBtn(label: "START", retroId: 3, currentKey: _getKeyName(3, isGamepad), isBinding: bindingRetroId == 3, onBind: () => onStartBind(3, isGamepad)),
      _BindBtn(label: "SELECT", retroId: 2, currentKey: _getKeyName(2, isGamepad), isBinding: bindingRetroId == 2, onBind: () => onStartBind(2, isGamepad)),
      const Divider(color: Colors.white12),
      _BindBtn(label: "L", retroId: 10, currentKey: _getKeyName(10, isGamepad), isBinding: bindingRetroId == 10, onBind: () => onStartBind(10, isGamepad)),
      _BindBtn(label: "R", retroId: 11, currentKey: _getKeyName(11, isGamepad), isBinding: bindingRetroId == 11, onBind: () => onStartBind(11, isGamepad)),
      _BindBtn(label: "L2", retroId: 12, currentKey: _getKeyName(12, isGamepad), isBinding: bindingRetroId == 12, onBind: () => onStartBind(12, isGamepad)),
      _BindBtn(label: "R2", retroId: 13, currentKey: _getKeyName(13, isGamepad), isBinding: bindingRetroId == 13, onBind: () => onStartBind(13, isGamepad)),
      _BindBtn(label: "L3", retroId: 14, currentKey: _getKeyName(14, isGamepad), isBinding: bindingRetroId == 14, onBind: () => onStartBind(14, isGamepad)),
      _BindBtn(label: "R3", retroId: 15, currentKey: _getKeyName(15, isGamepad), isBinding: bindingRetroId == 15, onBind: () => onStartBind(15, isGamepad)),
      const Divider(color: Colors.white12),
      const Text("Left Analog", style: TextStyle(color: Colors.white38, fontSize: 10)),
      const SizedBox(width: double.infinity),
      _BindBtn(label: "LX-", retroId: 100, currentKey: _getKeyName(100, isGamepad), isBinding: bindingRetroId == 100, onBind: () => onStartBind(100, isGamepad)),
      _BindBtn(label: "LX+", retroId: 101, currentKey: _getKeyName(101, isGamepad), isBinding: bindingRetroId == 101, onBind: () => onStartBind(101, isGamepad)),
      _BindBtn(label: "LY-", retroId: 102, currentKey: _getKeyName(102, isGamepad), isBinding: bindingRetroId == 102, onBind: () => onStartBind(102, isGamepad)),
      _BindBtn(label: "LY+", retroId: 103, currentKey: _getKeyName(103, isGamepad), isBinding: bindingRetroId == 103, onBind: () => onStartBind(103, isGamepad)),
      const Divider(color: Colors.white12),
      const Text("Right Analog", style: TextStyle(color: Colors.white38, fontSize: 10)),
      const SizedBox(width: double.infinity),
      _BindBtn(label: "RX-", retroId: 104, currentKey: _getKeyName(104, isGamepad), isBinding: bindingRetroId == 104, onBind: () => onStartBind(104, isGamepad)),
      _BindBtn(label: "RX+", retroId: 105, currentKey: _getKeyName(105, isGamepad), isBinding: bindingRetroId == 105, onBind: () => onStartBind(105, isGamepad)),
      _BindBtn(label: "RY-", retroId: 106, currentKey: _getKeyName(106, isGamepad), isBinding: bindingRetroId == 106, onBind: () => onStartBind(106, isGamepad)),
      _BindBtn(label: "RY+", retroId: 107, currentKey: _getKeyName(107, isGamepad), isBinding: bindingRetroId == 107, onBind: () => onStartBind(107, isGamepad)),
      const Divider(color: Colors.white12),
      const SizedBox(height: 8),
      Center(
        child: TextButton.icon(
          onPressed: isGamepad ? onResetGamepad : onResetKeyboard,
          icon: const Icon(Icons.restore, size: 18, color: Colors.redAccent),
          label: const Text("Reset to Defaults", style: TextStyle(color: Colors.redAccent)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  String _getKeyName(int retroId, bool isGamepad) {
    final names = <String>[];
    
    if (isGamepad) {
      
      for (final entry in gamepadMap.entries) {
        if (entry.value == retroId) {
          names.add(entry.key);
        }
      }
      
      
      
      final toRemove = <String>[];
      for (final name in names) {
        if (name.endsWith('+') || name.endsWith('-')) {
          final base = name.substring(0, name.length - 1);
          if (names.contains(base)) {
            toRemove.add(base);
          }
        }
      }
      names.removeWhere((n) => toRemove.contains(n));
      
      
      
      if (Platform.isAndroid) {
        for (final entry in keyMap.entries) {
          if (entry.value == retroId) {
            var label = entry.key.keyLabel;
            if (label.isEmpty) {
              label = entry.key.debugName ?? "Unknown";
              if (label.contains('#')) {
                label = label.split('#').last;
              }
            }
            if (!names.contains(label)) {
              names.add(label);
            }
          }
        }
      }
    } else {
      
      for (final entry in keyMap.entries) {
        if (entry.value == retroId) {
          var label = entry.key.keyLabel;
          if (label.isEmpty) {
            label = entry.key.debugName ?? "Unknown";
            if (label.contains('#')) {
              label = label.split('#').last;
            }
          }
          if (!label.toLowerCase().contains('game button')) {
            names.add(label);
          }
        }
      }
    }
    
    
    return names.isEmpty ? "None" : names.first;
  }
}

class _BindBtn extends StatelessWidget {
  final String label;
  final int retroId;
  final String currentKey;
  final bool isBinding;
  final VoidCallback onBind;

  const _BindBtn({
    required this.label,
    required this.retroId,
    required this.currentKey,
    required this.isBinding,
    required this.onBind,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onBind,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isBinding ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isBinding ? Colors.blue : Colors.white12),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 4),
            Text(isBinding ? "???" : currentKey, 
              style: TextStyle(color: isBinding ? Colors.blue : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PremiumDock extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onExit;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onTogglePause;
  final VoidCallback onMinimize;
  final VoidCallback onOpenSettings;
  final double volume;
  final Function(double) onVolumeChanged;
  final bool isFastForward;
  final VoidCallback onToggleFastForward;
  final bool isSlowMotion;
  final VoidCallback onToggleSlowMotion;
  final bool isPaused;
  final ScalingMode scalingMode;
  final VoidCallback onCycleScaling;

  const _PremiumDock({
    required this.onReset,
    required this.onExit,
    required this.onSave,
    required this.onLoad,
    required this.onTogglePause,
    required this.onMinimize,
    required this.onOpenSettings,
    required this.volume,
    required this.onVolumeChanged,
    required this.isFastForward,
    required this.onToggleFastForward,
    required this.isSlowMotion,
    required this.onToggleSlowMotion,
    required this.isPaused,
    required this.scalingMode,
    required this.onCycleScaling,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: isSmall ? 56 : 64,
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DockButton(icon: isPaused ? Icons.play_arrow : Icons.pause, onPressed: onTogglePause),
                const _VerticalDivider(),
                _DockButton(icon: Icons.save, onPressed: onSave),
                _DockButton(icon: Icons.upload_file, onPressed: onLoad),
                const _VerticalDivider(),
                _DockButton(icon: Icons.refresh, onPressed: onReset),
                _DockButton(icon: Icons.settings, onPressed: onOpenSettings),
                const _VerticalDivider(),
                _DockButton(
                  icon: Icons.bolt, 
                  onPressed: onToggleFastForward, 
                  color: isFastForward ? Colors.yellowAccent : Colors.white70
                ),
                if (!Platform.isAndroid)
                  _DockButton(
                    icon: Icons.slow_motion_video, 
                    onPressed: onToggleSlowMotion, 
                    color: isSlowMotion ? Colors.cyanAccent : Colors.white70
                  ),
                const _VerticalDivider(),
                if (!Platform.isAndroid) ...[
                  _DockButton(
                    icon: scalingMode == ScalingMode.stretch ? Icons.aspect_ratio : (scalingMode == ScalingMode.fit ? Icons.fit_screen : Icons.zoom_in),
                    onPressed: onCycleScaling,
                    color: Colors.white70,
                  ),
                  const _VerticalDivider(),
                ],
                
                Icon(volume == 0 ? Icons.volume_off : Icons.volume_up, color: Colors.white70, size: 18),
                SizedBox(
                  width: isSmall ? 60 : 80,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: volume,
                      onChanged: onVolumeChanged,
                    ),
                  ),
                ),
                const _VerticalDivider(),
                _DockButton(icon: Icons.keyboard_arrow_down, onPressed: onMinimize),
                _DockButton(icon: Icons.close, onPressed: onExit, color: Colors.redAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _DockButton({
    required this.icon,
    required this.onPressed,
    this.color = Colors.white70,
  });

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _isFocused ? widget.color : Colors.transparent,
            width: 2,
          ),
          color: _isFocused ? widget.color.withOpacity(0.2) : Colors.transparent,
        ),
        child: IconButton(
          icon: Icon(widget.icon, color: widget.color),
          onPressed: widget.onPressed,
          hoverColor: Colors.white.withOpacity(0.1),
          splashRadius: 24,
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withOpacity(0.1),
    );
  }
}




class _EmulatorSurface extends StatelessWidget {
  final int? textureId;
  final ScalingMode scalingMode;
  final double coreAspectRatio;

  const _EmulatorSurface({
    this.textureId,
    required this.scalingMode,
    required this.coreAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (Platform.isWindows) {
      if (textureId != null) {
        child = Texture(
          textureId: textureId!,
          filterQuality: FilterQuality.none, 
        );
      } else {
        child = const Center(child: Text("Loading Emulator...", style: TextStyle(color: Colors.white)));
      }
    } else {
      
      
      child = const AndroidView(
        viewType: 'com.retrostream.vantage/retro_view',
        creationParamsCodec: StandardMessageCodec(),
      );
    }

    final orientation = MediaQuery.of(context).orientation;
    final alignment = orientation == Orientation.portrait ? Alignment.topCenter : Alignment.center;

    
    
    if (Platform.isAndroid) {
      return Align(
        alignment: alignment,
        child: AspectRatio(
          aspectRatio: coreAspectRatio,
          child: child,
        ),
      );
    }

    switch (scalingMode) {
      case ScalingMode.stretch:
        return SizedBox.expand(child: child);
      case ScalingMode.fit:
      case ScalingMode.originalAspectRatio:
        return Center(
          child: AspectRatio(
            aspectRatio: coreAspectRatio,
            child: child,
          ),
        );
    }
  }
}





const int _kDpadUp    = 19; 
const int _kDpadDown  = 20;
const int _kDpadLeft  = 21;
const int _kDpadRight = 22;
const int _kA         = 96; 
const int _kB         = 97;
const int _kX         = 99;
const int _kY         = 100;
const int _kSelect    = 109; 
const int _kStart     = 108; 
const int _kL1        = 102;
const int _kR1        = 103;
const int _kL2        = 104;
const int _kR2        = 105;

class _Btn {
  final int keyCode;
  final String label;
  double cx = 0, cy = 0, r = 0;
  double rw = 0, rh = 0;
  final bool isRect;
  bool pressed = false;

  _Btn(this.keyCode, this.label, {this.isRect = false});

  bool hit(double x, double y) {
    if (isRect) {
      return x >= cx - rw && x <= cx + rw && y >= cy - rh && y <= cy + rh;
    }
    final dx = x - cx, dy = y - cy;
    return dx * dx + dy * dy <= r * r;
  }
}

class VirtualGamepad extends StatefulWidget {
  final void Function(int keyCode) onButtonDown;
  final void Function(int keyCode) onButtonUp;

  const VirtualGamepad({
    super.key,
    required this.onButtonDown,
    required this.onButtonUp,
  });

  @override
  State<VirtualGamepad> createState() => _VirtualGamepadState();
}

class _VirtualGamepadState extends State<VirtualGamepad> {
  final List<_Btn> _buttons = [];
  final Map<int, _Btn> _activePointers = {};
  Size _lastSize = Size.zero;

  List<_Btn> _buildButtons(Size s) {
    final w = s.width, h = s.height;
    final sideMargin = w * 0.25;
    final bottomMargin = h * 0.20; 
    final btnR = w * 0.075;
    final dpad = w * 0.08;

    final dcx = sideMargin;
    final dcy = h - bottomMargin - dpad * 3.0;
    final gap = dpad * 1.45;

    final fcx = w - sideMargin;
    final fcy = h - bottomMargin - btnR * 3.0;
    final fg = btnR * 1.55;

    final mcy = h - (bottomMargin * 0.9); 
    final mw = btnR * 1.3, mh = btnR * 0.5;
    final mcx = w / 2;

    final sy = dcy - dpad * 3.5;
    final sw = btnR * 2.0, sh = btnR * 0.7;

    final s2y = sy - sh * 2.2;

    return [
      _Btn(_kDpadUp,    String.fromCharCode(Icons.keyboard_arrow_up.codePoint))..cx=dcx..cy=dcy-gap..r=dpad,
      _Btn(_kDpadDown,  String.fromCharCode(Icons.keyboard_arrow_down.codePoint))..cx=dcx..cy=dcy+gap..r=dpad,
      _Btn(_kDpadLeft,  String.fromCharCode(Icons.keyboard_arrow_left.codePoint))..cx=dcx-gap..cy=dcy..r=dpad,
      _Btn(_kDpadRight, String.fromCharCode(Icons.keyboard_arrow_right.codePoint))..cx=dcx+gap..cy=dcy..r=dpad,
      _Btn(_kA, 'A')..cx=fcx+fg..cy=fcy..r=btnR,
      _Btn(_kB, 'B')..cx=fcx..cy=fcy+fg..r=btnR,
      _Btn(_kX, 'X')..cx=fcx..cy=fcy-fg..r=btnR,
      _Btn(_kY, 'Y')..cx=fcx-fg..cy=fcy..r=btnR,
      _Btn(_kSelect, 'SEL', isRect: true)..cx=mcx-mw*1.2..cy=mcy..rw=mw..rh=mh,
      _Btn(_kStart,  'STA', isRect: true)..cx=mcx+mw*1.2..cy=mcy..rw=mw..rh=mh,
      _Btn(_kL1, 'L',  isRect: true)..cx=sideMargin..cy=sy..rw=sw..rh=sh,
      _Btn(_kR1, 'R',  isRect: true)..cx=w-sideMargin..cy=sy..rw=sw..rh=sh,
      _Btn(_kL2, 'L2', isRect: true)..cx=sideMargin..cy=s2y..rw=sw*0.8..rh=sh*0.8,
      _Btn(_kR2, 'R2', isRect: true)..cx=w-sideMargin..cy=s2y..rw=sw*0.8..rh=sh*0.8,
    ];
  }

  void _press(int ptr, _Btn btn) {
    _activePointers[ptr] = btn;
    btn.pressed = true;
    widget.onButtonDown(btn.keyCode);
    setState(() {});
  }

  void _release(int ptr) {
    final btn = _activePointers.remove(ptr);
    if (btn == null) return;
    if (_activePointers.values.every((b) => b != btn)) {
      btn.pressed = false;
      widget.onButtonUp(btn.keyCode);
    }
    setState(() {});
  }

  _Btn? _hitTest(double x, double y) {
    for (final b in _buttons) {
      if (b.hit(x, y)) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (size != _lastSize) {
        _lastSize = size;
        _buttons
          ..clear()
          ..addAll(_buildButtons(size));
      }
      return GestureDetector(
        onTapDown: (d) {
          final btn = _hitTest(d.localPosition.dx, d.localPosition.dy);
          if (btn != null) _press(0, btn);
        },
        onTapUp: (_) => _release(0),
        child: CustomPaint(
          painter: _GamepadPainter(_buttons),
          size: Size.infinite,
        ),
      );
    });
  }
}

class _GamepadPainter extends CustomPainter {
  final List<_Btn> buttons;

  _GamepadPainter(this.buttons);

  static final _fill = Paint()
    ..color = const Color(0x96B4B4D2)
    ..style = PaintingStyle.fill;
  static final _pressed = Paint()
    ..color = const Color(0xD27C5CBF)
    ..style = PaintingStyle.fill;
  static final _stroke = Paint()
    ..color = const Color(0x64FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final labelStyle = TextStyle(
      color: Colors.white,
      fontSize: size.width * 0.035,
      fontWeight: FontWeight.bold,
    );

    for (final btn in buttons) {
      final paint = btn.pressed ? _pressed : _fill;
      if (btn.isRect) {
        final rect = RRect.fromLTRBR(
          btn.cx - btn.rw, btn.cy - btn.rh,
          btn.cx + btn.rw, btn.cy + btn.rh,
          Radius.circular(btn.rh),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawRRect(rect, _stroke);
      } else {
        canvas.drawCircle(Offset(btn.cx, btn.cy), btn.r, paint);
        canvas.drawCircle(Offset(btn.cx, btn.cy), btn.r, _stroke);
      }

      
      final isIcon = btn.label.length == 1 && btn.label.codeUnitAt(0) > 0xE000;
      final tp = TextPainter(
        text: TextSpan(
          text: btn.label, 
          style: labelStyle.copyWith(
            fontFamily: isIcon ? 'MaterialIcons' : null,
            fontSize: isIcon ? size.width * 0.05 : labelStyle.fontSize,
          )
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(btn.cx - tp.width / 2, btn.cy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_GamepadPainter oldDelegate) => true;
}

