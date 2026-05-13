



const Map<String, String> _platformAliases = {
  'nes': 'NES', 'famicom': 'NES', 'nintendo': 'NES',
  'nintendo entertainment system': 'NES',

  'snes': 'SNES', 'super nintendo': 'SNES', 'super famicom': 'SNES',
  'supernintendo': 'SNES', 'super nintendo entertainment system': 'SNES',

  'n64': 'N64', 'nintendo 64': 'N64', 'nintendo64': 'N64',

  'gb': 'Game Boy', 'game boy': 'Game Boy', 'gameboy': 'Game Boy',
  'gbc': 'Game Boy Color', 'game boy color': 'Game Boy Color',
  'gameboy color': 'Game Boy Color', 'gameboycolor': 'Game Boy Color',

  'gba': 'Game Boy Advance', 'game boy advance': 'Game Boy Advance',
  'gameboy advance': 'Game Boy Advance', 'gameboyadvance': 'Game Boy Advance',

  'nds': 'Nintendo DS', 'nintendo ds': 'Nintendo DS',
  'ds': 'Nintendo DS', 'nintendods': 'Nintendo DS',

  'vb': 'Virtual Boy', 'virtual boy': 'Virtual Boy', 'virtualboy': 'Virtual Boy',

  'sms': 'Master System', 'master system': 'Master System',
  'sega master system': 'Master System', 'mastersystem': 'Master System',

  'gg': 'Game Gear', 'game gear': 'Game Gear',
  'sega game gear': 'Game Gear', 'gamegear': 'Game Gear',

  'genesis': 'Sega Genesis', 'sega genesis': 'Sega Genesis',
  'megadrive': 'Sega Genesis', 'mega drive': 'Sega Genesis',
  'sega mega drive': 'Sega Genesis', 'md': 'Sega Genesis',

  'sega cd': 'Sega CD', 'segacd': 'Sega CD',
  'mega cd': 'Sega CD', 'sega-cd': 'Sega CD',

  '32x': 'Sega 32X', 'sega 32x': 'Sega 32X',

  'ss': 'Sega Saturn', 'saturn': 'Sega Saturn',
  'sega saturn': 'Sega Saturn', 'segasaturn': 'Sega Saturn',

  'psx': 'PlayStation', 'ps1': 'PlayStation', 'playstation': 'PlayStation',
  'playstation 1': 'PlayStation', 'ps one': 'PlayStation',

  'atari 2600': 'Atari 2600', '2600': 'Atari 2600',
  'atari 7800': 'Atari 7800', '7800': 'Atari 7800',
  'lynx': 'Atari Lynx', 'atari lynx': 'Atari Lynx',
  'jaguar': 'Atari Jaguar', 'atari jaguar': 'Atari Jaguar',

  'ws': 'WonderSwan', 'wonderswan': 'WonderSwan', 'wonder swan': 'WonderSwan',

  'pce': 'TurboGrafx-16', 'turbografx': 'TurboGrafx-16',
  'turbografx-16': 'TurboGrafx-16', 'turbografx 16': 'TurboGrafx-16',
  'pc engine': 'TurboGrafx-16', 'pcengine': 'TurboGrafx-16',

  'coleco': 'ColecoVision', 'colecovision': 'ColecoVision',

  'ngp': 'NeoGeo Pocket', 'neogeo pocket': 'NeoGeo Pocket',
  'neo geo pocket': 'NeoGeo Pocket', 'ngpc': 'NeoGeo Pocket',

  'dos': 'DOS', 'ms-dos': 'DOS', 'msdos': 'DOS', 'pc dos': 'DOS',

  'arcade': 'Arcade', 'fbneo': 'Arcade', 'finalburn neo': 'Arcade',
  'neogeo': 'Arcade', 'neo geo': 'Arcade',
  'mame': 'MAME 2003', 'mame 2003': 'MAME 2003', 'mame2003': 'MAME 2003',

  'psp': 'PSP', 'playstation portable': 'PSP',

  '3do': '3DO', '3do interactive multiplayer': '3DO', 'panasonic 3do': '3DO',

  'atari 5200': 'Atari 5200', '5200': 'Atari 5200',

  'amiga': 'Commodore Amiga', 'commodore amiga': 'Commodore Amiga',
  'c64': 'Commodore 64', 'commodore 64': 'Commodore 64',

  'pc-fx': 'PC-FX', 'pcfx': 'PC-FX', 'nec pc-fx': 'PC-FX',

  'pico-8': 'PICO-8', 'pico8': 'PICO-8', 'pico 8': 'PICO-8', 'pico': 'PICO-8',

  'dreamcast': 'Dreamcast', 'dc': 'Dreamcast', 'sega dreamcast': 'Dreamcast',
  'ps2': 'PlayStation 2', 'playstation 2': 'PlayStation 2',
  'ps3': 'PlayStation 3', 'playstation 3': 'PlayStation 3',
  'xbox': 'Xbox', 'xbox 360': 'Xbox 360', 'x360': 'Xbox 360',
  'gamecube': 'GameCube', 'nintendo gamecube': 'GameCube', 'gc': 'GameCube',
  'wii': 'Wii', 'nintendo wii': 'Wii', 'wii u': 'Wii U', 'wiiu': 'Wii U',
  'switch': 'Nintendo Switch', 'nintendo switch': 'Nintendo Switch',
  '3ds': 'Nintendo 3DS', 'nintendo 3ds': 'Nintendo 3DS',
  'psvita': 'PlayStation Vita', 'ps vita': 'PlayStation Vita',
};

String? resolvePlatformTag(List<String>? tags) {
  if (tags == null || tags.isEmpty) return null;
  for (final tag in tags) {
    final exact = _platformAliases[tag];
    if (exact != null) return exact;
    final lower = tag.toLowerCase();
    final ci = _platformAliases[lower];
    if (ci != null) return ci;
  }
  return null;
}

class AuthResult {
  final String accessToken;
  final JfUser user;

  AuthResult({required this.accessToken, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        accessToken: j['AccessToken'] as String,
        user: JfUser.fromJson(j['User'] as Map<String, dynamic>),
      );
}

class JfUser {
  final String id;
  final String name;

  JfUser({required this.id, required this.name});

  factory JfUser.fromJson(Map<String, dynamic> j) =>
      JfUser(id: j['Id'] as String, name: j['Name'] as String);
}

class ItemsResult {
  final List<JfItem> items;
  final int total;

  ItemsResult({required this.items, required this.total});

  factory ItemsResult.fromJson(Map<String, dynamic> j) => ItemsResult(
        items: (j['Items'] as List<dynamic>)
            .map((e) => JfItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: j['TotalRecordCount'] as int? ?? 0,
      );
}

class JfItem {
  final String id;
  final String name;
  final String? path;
  final String? mediaType;
  final String type;
  final String? collectionType;
  final String? overview;
  final int? year;
  final double? rating;
  final Map<String, String>? imageTags;
  final List<String>? backdropTags;
  final List<String>? tags;

  JfItem({
    required this.id,
    required this.name,
    this.path,
    this.mediaType,
    required this.type,
    this.collectionType,
    this.overview,
    this.year,
    this.rating,
    this.imageTags,
    this.backdropTags,
    this.tags,
  });

  factory JfItem.fromJson(Map<String, dynamic> j) => JfItem(
        id: j['Id'] as String,
        name: j['Name'] as String,
        path: j['Path'] as String?,
        mediaType: j['MediaType'] as String?,
        type: j['Type'] as String,
        collectionType: j['CollectionType'] as String?,
        overview: j['Overview'] as String?,
        year: j['ProductionYear'] as int?,
        rating: (j['CommunityRating'] as num?)?.toDouble(),
        imageTags: (j['ImageTags'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as String)),
        backdropTags: (j['BackdropImageTags'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        tags: (j['Tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      );

  String? get platformTag => resolvePlatformTag(tags);

  bool get isGame =>
      tags?.any((t) => t.toLowerCase() == 'game') == true ||
      type.toLowerCase() == 'game' ||
      (mediaType?.toLowerCase() == 'game');

  String? get discTag =>
      tags?.firstWhere((t) => t.toLowerCase().startsWith('disc '),
          orElse: () => '');

  String posterUrl(String server, String token) =>
      '$server/Items/$id/Images/Primary?api_key=$token';

  String downloadUrl(String server) {
    final fileName =
        path != null ? path!.split('/').last : '$id.rom';
    final encoded = Uri.encodeComponent(fileName);
    return '$server/jellyemu/rom/$id/$encoded';
  }
}

