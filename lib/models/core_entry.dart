


class CoreEntry {
  final String id;
  final String displayName;
  final List<String> extensions;
  final String fileName;

  const CoreEntry({
    required this.id,
    required this.displayName,
    required this.extensions,
    required this.fileName,
  });

  
  static const _root = 'https://buildbot.libretro.com/nightly';

  
  
  
  String androidUrl(String abi) =>
      '$_root/android/latest/$abi/$fileName';

  
  
  
  String linuxUrl(String arch) {
    final file = _desktopFileName('.so');
    return '$_root/linux/$arch/latest/$file';
  }

  
  
  
  String windowsUrl(String arch) {
    final file = _desktopFileName('.dll');
    return '$_root/windows/$arch/latest/$file';
  }

  
  
  String macosUrl() {
    final file = _desktopFileName('.dylib');
    return '$_root/apple/osx/latest/$file';
  }

  
  
  
  String _desktopFileName(String ext) {
    
    
    final base = fileName
        .replaceAll('_android.so.zip', '')  
        .replaceAll('.so.zip', '')           
        .replaceAll('.dll.zip', '')
        .replaceAll('.dylib.zip', '');
    
    return '$base$ext.zip';
  }

  
  String downloadUrl({
    required String platform, 
    String arch = 'x86_64',   
  }) {
    return switch (platform) {
      'android' => androidUrl(arch),
      'linux'   => linuxUrl(arch),
      'windows' => windowsUrl(arch),
      'macos'   => macosUrl(),
      _         => androidUrl('arm64-v8a'),
    };
  }

  
  String installedName(String platform) => switch (platform) {
    'android' => fileName.replaceAll('.zip', ''),  
    'windows' => _desktopFileName('.dll').replaceAll('.zip', ''),
    'macos'   => _desktopFileName('.dylib').replaceAll('.zip', ''),
    _         => _desktopFileName('.so').replaceAll('.zip', ''),
  };
}

const coreCatalog = <CoreEntry>[
  CoreEntry(id: 'fceumm',     displayName: 'FCEUmm (NES)',           extensions: ['nes','fds','unf','unif'],          fileName: 'fceumm_libretro_android.so.zip'),
  CoreEntry(id: 'nestopia',   displayName: 'Nestopia UE (NES)',       extensions: ['nes','fds','unf','unif'],          fileName: 'nestopia_libretro_android.so.zip'),
  CoreEntry(id: 'mesen',      displayName: 'Mesen (NES)',             extensions: ['nes','fds','unf','unif','nsf'],    fileName: 'mesen_libretro_android.so.zip'),
  CoreEntry(id: 'snes9x',     displayName: 'Snes9x (SNES)',           extensions: ['sfc','smc','fig','bs','st','swc'], fileName: 'snes9x_libretro_android.so.zip'),
  CoreEntry(id: 'snes9x2010', displayName: 'Snes9x 2010 (SNES)',      extensions: ['sfc','smc','fig','bs','st','swc'], fileName: 'snes9x2010_libretro_android.so.zip'),
  CoreEntry(id: 'gambatte',   displayName: 'Gambatte (GB/GBC)',        extensions: ['gb','gbc','dmg'],                 fileName: 'gambatte_libretro_android.so.zip'),
  CoreEntry(id: 'sameboy',    displayName: 'SameBoy (GB/GBC)',         extensions: ['gb','gbc','dmg'],                 fileName: 'sameboy_libretro_android.so.zip'),
  CoreEntry(id: 'mgba',       displayName: 'mGBA (GBA)',               extensions: ['gba','agb','mb'],                 fileName: 'mgba_libretro_android.so.zip'),
  CoreEntry(id: 'vba_next',   displayName: 'VBA Next (GBA)',           extensions: ['gba','agb','mb'],                 fileName: 'vba_next_libretro_android.so.zip'),
  CoreEntry(id: 'mupen64plus_next_gles3', displayName: 'Mupen64Plus Next GLES3 (N64)', extensions: ['n64','v64','z64','u1','ndd'], fileName: 'mupen64plus_next_gles3_libretro_android.so.zip'),
  CoreEntry(id: 'parallel_n64', displayName: 'ParaLLEl N64',           extensions: ['n64','v64','z64','u1','ndd'],     fileName: 'parallel_n64_libretro_android.so.zip'),
  CoreEntry(id: 'desmume',    displayName: 'DeSmuME (NDS)',             extensions: ['nds','bin'],                      fileName: 'desmume_libretro_android.so.zip'),
  CoreEntry(id: 'melonds',    displayName: 'melonDS (NDS)',             extensions: ['nds','bin'],                      fileName: 'melonds_libretro_android.so.zip'),
  CoreEntry(id: 'melondsds',  displayName: 'melonDS DS (NDS/DSi)',      extensions: ['nds','bin'],                      fileName: 'melondsds_libretro_android.so.zip'),
  CoreEntry(id: 'dolphin',    displayName: 'Dolphin (GameCube/Wii)',    extensions: ['gcm','iso','wbfs','ciso','gcz','elf','dol','rvz'], fileName: 'dolphin_libretro_android.so.zip'),
  CoreEntry(id: 'pcsx_rearmed', displayName: 'PCSX ReARMed (PS1)',     extensions: ['bin','cue','img','mdf','pbp','toc','cbn','m3u','ccd','chd','iso'], fileName: 'pcsx_rearmed_libretro_android.so.zip'),
  CoreEntry(id: 'mednafen_psx', displayName: 'Mednafen PSX (PS1)',     extensions: ['bin','cue','img','mdf','pbp','toc','cbn','m3u','ccd','chd'], fileName: 'mednafen_psx_libretro_android.so.zip'),
  CoreEntry(id: 'ppsspp',     displayName: 'PPSSPP (PSP)',              extensions: ['iso','cso','pbp','elf','prx'],    fileName: 'ppsspp_libretro_android.so.zip'),
  CoreEntry(id: 'genesis_plus_gx', displayName: 'Genesis Plus GX (MD/SMS/GG/CD)', extensions: ['md','gen','smd','sg','sms','gg','68k','chd','cue','iso','scd','32x'], fileName: 'genesis_plus_gx_libretro_android.so.zip'),
  CoreEntry(id: 'picodrive',  displayName: 'PicoDrive (MD/32X/CD/SMS)', extensions: ['bin','gen','smd','md','32x','cue','iso','sms','68k'], fileName: 'picodrive_libretro_android.so.zip'),
  CoreEntry(id: 'mednafen_pce_fast', displayName: 'Mednafen PCE Fast (PC Engine/TG-16)', extensions: ['pce','tg16','cue','ccd','chd','sgx'], fileName: 'mednafen_pce_fast_libretro_android.so.zip'),
  CoreEntry(id: 'fbneo',      displayName: 'FinalBurn Neo (Arcade/Neo Geo/CPS)', extensions: ['zip','7z'], fileName: 'fbneo_libretro_android.so.zip'),
  CoreEntry(id: 'mame2003',   displayName: 'MAME 2003 (Arcade)',        extensions: ['zip'],                            fileName: 'mame2003_libretro_android.so.zip'),
  CoreEntry(id: 'mame2003_plus', displayName: 'MAME 2003-Plus (Arcade)', extensions: ['zip'],                          fileName: 'mame2003_plus_libretro_android.so.zip'),
  CoreEntry(id: 'stella',     displayName: 'Stella (Atari 2600)',        extensions: ['a26','bin','rom'],                fileName: 'stella_libretro_android.so.zip'),
  CoreEntry(id: 'prosystem',  displayName: 'ProSystem (Atari 7800)',     extensions: ['a78','bin'],                      fileName: 'prosystem_libretro_android.so.zip'),
  CoreEntry(id: 'handy',      displayName: 'Handy (Atari Lynx)',         extensions: ['lnx','o'],                        fileName: 'handy_libretro_android.so.zip'),
  CoreEntry(id: 'mednafen_ngp', displayName: 'Mednafen NGP (Neo Geo Pocket)', extensions: ['ngp','ngc','ngpc','npc'],   fileName: 'mednafen_ngp_libretro_android.so.zip'),
  CoreEntry(id: 'mednafen_wswan', displayName: 'Mednafen WonderSwan',   extensions: ['ws','wsc','pc2'],                 fileName: 'mednafen_wswan_libretro_android.so.zip'),
  CoreEntry(id: 'flycast',    displayName: 'Flycast (Dreamcast/NAOMI)', extensions: ['chd','cdi','iso','elf','cue','gdi','lst','bin','dat','zip','7z'], fileName: 'flycast_libretro_android.so.zip'),
  CoreEntry(id: 'vice_x64sc', displayName: 'VICE x64sc (C64)',          extensions: ['d64','d71','d80','d81','g64','t64','tap','prg','p00','crt','bin','zip'], fileName: 'vice_x64sc_libretro_android.so.zip'),
  CoreEntry(id: 'gearboy',    displayName: 'Gearboy (GB/GBC)',           extensions: ['gb','gbc','dmg','sgb'],           fileName: 'gearboy_libretro_android.so.zip'),
  CoreEntry(id: 'citra',      displayName: 'Citra (3DS)',                extensions: ['3ds','3dsx','cci','cxi','elf'],   fileName: 'citra_libretro_android.so.zip'),
  CoreEntry(id: 'yabasanshiro', displayName: 'YabaSanshiro (Saturn)',   extensions: ['bin','cue','iso','mdf','chd'],    fileName: 'yabasanshiro_libretro_android.so.zip'),
  CoreEntry(id: 'mednafen_saturn', displayName: 'Mednafen Saturn',      extensions: ['bin','cue','iso','mdf','chd','toc','m3u'], fileName: 'mednafen_saturn_libretro_android.so.zip'),
];



String? resolveCore(String romPath, Set<String> installedCores) {
  final ext = romPath.split('.').last.toLowerCase();
  for (final entry in coreCatalog) {
    if (entry.extensions.contains(ext) && installedCores.contains(entry.id)) {
      return entry.id;
    }
  }
  return null;
}

