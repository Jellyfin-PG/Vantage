












import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/core_entry.dart';

class CoreManager {
  CoreManager._();
  static final instance = CoreManager._();

  late String _coresDir;
  bool _initialized = false;

  

  
  static String get currentPlatform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isLinux)   return 'linux';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS)   return 'macos';
    return 'linux';
  }

  
  
  
  
  
  
  
  static String get currentArch {
    if (Platform.isAndroid) {
      
      return _androidAbi;
    }
    
    
    
    return _desktopArch;
  }

  static String _androidAbi  = 'arm64-v8a';
  static String _desktopArch = 'x86_64';

  
  
  static void setAndroidAbi(String abi) => _androidAbi = abi;

  
  static void setDesktopArch(String arch) => _desktopArch = arch;

  

  Future<void> init() async {
    if (_initialized) return;
    final appDir = await getApplicationSupportDirectory();
    _coresDir = '${appDir.path}/cores';
    await Directory(_coresDir).create(recursive: true);
    _initialized = true;
  }

  
  String _installedName(CoreEntry entry) =>
      entry.installedName(currentPlatform);

  String _corePath(CoreEntry entry) =>
      '$_coresDir/${_installedName(entry)}';

  bool isInstalled(CoreEntry entry) => File(_corePath(entry)).existsSync();

  String? pathForCore(CoreEntry entry) {
    final f = File(_corePath(entry));
    return f.existsSync() ? f.path : null;
  }

  
  String? corePathForExtension(String ext) {
    final lower = ext.toLowerCase();
    for (final entry in coreCatalog) {
      if (entry.extensions.contains(lower) && isInstalled(entry)) {
        return pathForCore(entry);
      }
    }
    return null;
  }

  

String? corePathForPlatformTag(String tag) {
  final lower = tag.toLowerCase();
  
  const tagToCores = <String, List<String>>{
    'nes':               ['fceumm', 'nestopia', 'mesen'],
    'snes':              ['snes9x', 'snes9x2010'],
    'n64':               ['mupen64plus_next_gles3', 'parallel_n64'],
    'game boy':          ['gambatte', 'sameboy', 'gearboy'],
    'game boy color':    ['gambatte', 'sameboy', 'gearboy'],
    'game boy advance':  ['mgba', 'vba_next'],
    'nintendo ds':       ['melondsds', 'melonds', 'desmume'],
    'nintendo 3ds':      ['citra'],
    'virtual boy':       ['mednafen_vb'],
    'master system':     ['genesis_plus_gx', 'picodrive'],
    'game gear':         ['genesis_plus_gx'],
    'sega genesis':      ['genesis_plus_gx', 'picodrive'],
    'sega cd':           ['genesis_plus_gx', 'picodrive'],
    'sega 32x':          ['picodrive'],
    'sega saturn':       ['mednafen_saturn', 'yabasanshiro'],
    'dreamcast':         ['flycast'],
    'playstation':       ['pcsx_rearmed', 'mednafen_psx'],
    'playstation 2':     [],
    'psp':               ['ppsspp'],
    'atari 2600':        ['stella'],
    'atari 7800':        ['prosystem'],
    'atari lynx':        ['handy'],
    'turbografx-16':     ['mednafen_pce_fast'],
    'neogeo pocket':     ['mednafen_ngp'],
    'wonderswan':        ['mednafen_wswan'],
    'arcade':            ['fbneo', 'mame2003_plus', 'mame2003'],
    'mame 2003':         ['mame2003_plus', 'mame2003'],
    'dos':               [],
    'commodore 64':      ['vice_x64sc'],
    'gamecube':          ['dolphin'],
    'wii':               ['dolphin'],
  };

  final coreIds = tagToCores[lower] ?? [];
  for (final id in coreIds) {
    final entry = coreCatalog.firstWhere(
      (e) => e.id == id,
      orElse: () => coreCatalog.first, 
    );
    if (entry.id == id && isInstalled(entry)) {
      return pathForCore(entry);
    }
  }
  return null;
}

  

  
  
  Future<void> downloadCore(
    CoreEntry entry, {
    void Function(int)? onProgress,
  }) async {
    await init();

    final url = entry.downloadUrl(
      platform: currentPlatform,
      arch: currentArch,
    );

    onProgress?.call(0);

    final request = http.Request('GET', Uri.parse(url));
    final streamed = await request.send();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('HTTP ${streamed.statusCode} downloading core from $url');
    }

    final total = streamed.contentLength ?? 0;
    var done = 0;
    final chunks = <int>[];
    await for (final chunk in streamed.stream) {
      chunks.addAll(chunk);
      done += chunk.length;
      if (total > 0) onProgress?.call((done * 100 ~/ total));
    }

    onProgress?.call(-1); 

    _extractZip(Uint8List.fromList(chunks), _coresDir, currentPlatform);
  }

  void _extractZip(Uint8List bytes, String destDir, String platform) {
    
    
    final files = _parseZip(bytes);
    for (final f in files) {
      final outPath = '$destDir/${f.name}';
      File(outPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(f.data);
      
      if (platform != 'windows') {
        Process.runSync('chmod', ['+x', outPath]);
      }
    }
  }

  
  List<({String name, Uint8List data})> _parseZip(Uint8List bytes) {
    final results = <({String name, Uint8List data})>[];
    
    int eocd = -1;
    for (int i = bytes.length - 22; i >= 0; i--) {
      if (bytes[i] == 0x50 && bytes[i+1] == 0x4b &&
          bytes[i+2] == 0x05 && bytes[i+3] == 0x06) {
        eocd = i; break;
      }
    }
    if (eocd == -1) throw Exception('Invalid ZIP: EOCD not found');

    final entryCount  = _u16(bytes, eocd + 10);
    final cdOffset    = _u32(bytes, eocd + 16);
    var pos = cdOffset;

    for (int e = 0; e < entryCount; e++) {
      if (_u32(bytes, pos) != 0x02014b50) break; 
      final nameLen    = _u16(bytes, pos + 28);
      final extraLen   = _u16(bytes, pos + 30);
      final commentLen = _u16(bytes, pos + 32);
      final localOffset = _u32(bytes, pos + 42);
      final name = String.fromCharCodes(bytes.sublist(pos + 46, pos + 46 + nameLen));
      pos += 46 + nameLen + extraLen + commentLen;

      
      if (name.endsWith('/')) continue;

      
      var lpos = localOffset;
      if (_u32(bytes, lpos) != 0x04034b50) continue; 
      final lNameLen  = _u16(bytes, lpos + 26);
      final lExtraLen = _u16(bytes, lpos + 28);
      final compSize  = _u32(bytes, lpos + 18);
      final compression = _u16(bytes, lpos + 8);
      lpos += 30 + lNameLen + lExtraLen;

      final compData = bytes.sublist(lpos, lpos + compSize);
      final Uint8List data;
      if (compression == 0) {
        data = compData;
      } else if (compression == 8) {
        data = _inflate(compData);
      } else {
        continue; 
      }
      results.add((name: name.split('/').last, data: data));
    }
    return results;
  }

  static int _u16(Uint8List b, int i) => b[i] | (b[i+1] << 8);
  static int _u32(Uint8List b, int i) =>
      b[i] | (b[i+1] << 8) | (b[i+2] << 16) | (b[i+3] << 24);

  
  static Uint8List _inflate(Uint8List compressed) {
    
    final filter = RawZLibFilter.inflateFilter(raw: true);
    filter.process(compressed, 0, compressed.length);
    final out = <int>[];
    List<int>? chunk;
    while ((chunk = filter.processed(flush: false)) != null) {
      out.addAll(chunk!);
    }
    final tail = filter.processed(flush: true);
    if (tail != null) out.addAll(tail);
    return Uint8List.fromList(out);
  }

  

  bool deleteCore(CoreEntry entry) {
    final f = File(_corePath(entry));
    if (f.existsSync()) { f.deleteSync(); return true; }
    return false;
  }

  Set<String> get installedCoreIds =>
      coreCatalog.where(isInstalled).map((e) => e.id).toSet();
}


