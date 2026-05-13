

#ifndef LIBRETRO_H__
#define LIBRETRO_H__

#include <stdint.h>
#include <stddef.h>
#include <limits.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __cplusplus
#if defined(_MSC_VER) && _MSC_VER < 1800 && !defined(SN_TARGET_PS3)

#define bool unsigned char
#define true 1
#define false 0
#else
#include <stdbool.h>
#endif
#endif

#ifndef RETRO_CALLCONV
#  if defined(__GNUC__) && defined(__i386__) && !defined(__x86_64__)
#    define RETRO_CALLCONV __attribute__((cdecl))
#  elif defined(_MSC_VER) && defined(_M_X86) && !defined(_M_X64)
#    define RETRO_CALLCONV __cdecl
#  else
#    define RETRO_CALLCONV 
#  endif
#endif

#ifndef RETRO_API
#  if defined(_WIN32) || defined(__CYGWIN__) || defined(__MINGW32__)
#    ifdef RETRO_IMPORT_SYMBOLS
#      ifdef __GNUC__
#        define RETRO_API RETRO_CALLCONV __attribute__((__dllimport__))
#      else
#        define RETRO_API RETRO_CALLCONV __declspec(dllimport)
#      endif
#    else
#      ifdef __GNUC__
#        define RETRO_API RETRO_CALLCONV __attribute__((__dllexport__))
#      else
#        define RETRO_API RETRO_CALLCONV __declspec(dllexport)
#      endif
#    endif
#  else
#      if defined(__GNUC__) && __GNUC__ >= 4
#        define RETRO_API RETRO_CALLCONV __attribute__((__visibility__("default")))
#      else
#        define RETRO_API RETRO_CALLCONV
#      endif
#  endif
#endif


#define RETRO_API_VERSION         1



#define RETRO_DEVICE_TYPE_SHIFT         8
#define RETRO_DEVICE_MASK               ((1 << RETRO_DEVICE_TYPE_SHIFT) - 1)


#define RETRO_DEVICE_SUBCLASS(base, id) (((id + 1) << RETRO_DEVICE_TYPE_SHIFT) | base)




#define RETRO_DEVICE_NONE         0


#define RETRO_DEVICE_JOYPAD       1


#define RETRO_DEVICE_MOUSE        2


#define RETRO_DEVICE_KEYBOARD     3


#define RETRO_DEVICE_LIGHTGUN     4


#define RETRO_DEVICE_ANALOG       5


#define RETRO_DEVICE_POINTER      6






#define RETRO_DEVICE_ID_JOYPAD_B        0


#define RETRO_DEVICE_ID_JOYPAD_Y        1


#define RETRO_DEVICE_ID_JOYPAD_SELECT   2


#define RETRO_DEVICE_ID_JOYPAD_START    3


#define RETRO_DEVICE_ID_JOYPAD_UP       4


#define RETRO_DEVICE_ID_JOYPAD_DOWN     5


#define RETRO_DEVICE_ID_JOYPAD_LEFT     6


#define RETRO_DEVICE_ID_JOYPAD_RIGHT    7


#define RETRO_DEVICE_ID_JOYPAD_A        8


#define RETRO_DEVICE_ID_JOYPAD_X        9


#define RETRO_DEVICE_ID_JOYPAD_L       10


#define RETRO_DEVICE_ID_JOYPAD_R       11


#define RETRO_DEVICE_ID_JOYPAD_L2      12


#define RETRO_DEVICE_ID_JOYPAD_R2      13


#define RETRO_DEVICE_ID_JOYPAD_L3      14


#define RETRO_DEVICE_ID_JOYPAD_R3      15


#define RETRO_DEVICE_ID_JOYPAD_MASK    256






#define RETRO_DEVICE_INDEX_ANALOG_LEFT       0
#define RETRO_DEVICE_INDEX_ANALOG_RIGHT      1
#define RETRO_DEVICE_INDEX_ANALOG_BUTTON     2
#define RETRO_DEVICE_ID_ANALOG_X             0
#define RETRO_DEVICE_ID_ANALOG_Y             1




#define RETRO_DEVICE_ID_MOUSE_X                0
#define RETRO_DEVICE_ID_MOUSE_Y                1
#define RETRO_DEVICE_ID_MOUSE_LEFT             2
#define RETRO_DEVICE_ID_MOUSE_RIGHT            3
#define RETRO_DEVICE_ID_MOUSE_WHEELUP          4
#define RETRO_DEVICE_ID_MOUSE_WHEELDOWN        5
#define RETRO_DEVICE_ID_MOUSE_MIDDLE           6
#define RETRO_DEVICE_ID_MOUSE_HORIZ_WHEELUP    7
#define RETRO_DEVICE_ID_MOUSE_HORIZ_WHEELDOWN  8
#define RETRO_DEVICE_ID_MOUSE_BUTTON_4         9
#define RETRO_DEVICE_ID_MOUSE_BUTTON_5         10


#define RETRO_DEVICE_ID_LIGHTGUN_SCREEN_X        13 
#define RETRO_DEVICE_ID_LIGHTGUN_SCREEN_Y        14 

#define RETRO_DEVICE_ID_LIGHTGUN_IS_OFFSCREEN    15 
#define RETRO_DEVICE_ID_LIGHTGUN_TRIGGER          2
#define RETRO_DEVICE_ID_LIGHTGUN_RELOAD          16 
#define RETRO_DEVICE_ID_LIGHTGUN_AUX_A            3
#define RETRO_DEVICE_ID_LIGHTGUN_AUX_B            4
#define RETRO_DEVICE_ID_LIGHTGUN_START            6
#define RETRO_DEVICE_ID_LIGHTGUN_SELECT           7
#define RETRO_DEVICE_ID_LIGHTGUN_AUX_C            8
#define RETRO_DEVICE_ID_LIGHTGUN_DPAD_UP          9
#define RETRO_DEVICE_ID_LIGHTGUN_DPAD_DOWN       10
#define RETRO_DEVICE_ID_LIGHTGUN_DPAD_LEFT       11
#define RETRO_DEVICE_ID_LIGHTGUN_DPAD_RIGHT      12

#define RETRO_DEVICE_ID_LIGHTGUN_X                0 
#define RETRO_DEVICE_ID_LIGHTGUN_Y                1 
#define RETRO_DEVICE_ID_LIGHTGUN_CURSOR           3 
#define RETRO_DEVICE_ID_LIGHTGUN_TURBO            4 
#define RETRO_DEVICE_ID_LIGHTGUN_PAUSE            5 


#define RETRO_DEVICE_ID_POINTER_X             0
#define RETRO_DEVICE_ID_POINTER_Y             1
#define RETRO_DEVICE_ID_POINTER_PRESSED       2
#define RETRO_DEVICE_ID_POINTER_COUNT         3

#define RETRO_DEVICE_ID_POINTER_IS_OFFSCREEN 15



#define RETRO_REGION_NTSC  0
#define RETRO_REGION_PAL   1


enum retro_language
{
   RETRO_LANGUAGE_ENGLISH             = 0,
   RETRO_LANGUAGE_JAPANESE            = 1,
   RETRO_LANGUAGE_FRENCH              = 2,
   RETRO_LANGUAGE_SPANISH             = 3,
   RETRO_LANGUAGE_GERMAN              = 4,
   RETRO_LANGUAGE_ITALIAN             = 5,
   RETRO_LANGUAGE_DUTCH               = 6,
   RETRO_LANGUAGE_PORTUGUESE_BRAZIL   = 7,
   RETRO_LANGUAGE_PORTUGUESE_PORTUGAL = 8,
   RETRO_LANGUAGE_RUSSIAN             = 9,
   RETRO_LANGUAGE_KOREAN              = 10,
   RETRO_LANGUAGE_CHINESE_TRADITIONAL = 11,
   RETRO_LANGUAGE_CHINESE_SIMPLIFIED  = 12,
   RETRO_LANGUAGE_ESPERANTO           = 13,
   RETRO_LANGUAGE_POLISH              = 14,
   RETRO_LANGUAGE_VIETNAMESE          = 15,
   RETRO_LANGUAGE_ARABIC              = 16,
   RETRO_LANGUAGE_GREEK               = 17,
   RETRO_LANGUAGE_TURKISH             = 18,
   RETRO_LANGUAGE_SLOVAK              = 19,
   RETRO_LANGUAGE_PERSIAN             = 20,
   RETRO_LANGUAGE_HEBREW              = 21,
   RETRO_LANGUAGE_ASTURIAN            = 22,
   RETRO_LANGUAGE_FINNISH             = 23,
   RETRO_LANGUAGE_INDONESIAN          = 24,
   RETRO_LANGUAGE_SWEDISH             = 25,
   RETRO_LANGUAGE_UKRAINIAN           = 26,
   RETRO_LANGUAGE_CZECH               = 27,
   RETRO_LANGUAGE_CATALAN_VALENCIA    = 28,
   RETRO_LANGUAGE_CATALAN             = 29,
   RETRO_LANGUAGE_BRITISH_ENGLISH     = 30,
   RETRO_LANGUAGE_HUNGARIAN           = 31,
   RETRO_LANGUAGE_BELARUSIAN          = 32,
   RETRO_LANGUAGE_GALICIAN            = 33,
   RETRO_LANGUAGE_NORWEGIAN           = 34,
   RETRO_LANGUAGE_IRISH               = 35,
   RETRO_LANGUAGE_THAI                = 36,
   RETRO_LANGUAGE_LAST,

   
   RETRO_LANGUAGE_DUMMY          = INT_MAX
};




#define RETRO_MEMORY_MASK        0xff


#define RETRO_MEMORY_SAVE_RAM    0


#define RETRO_MEMORY_RTC         1


#define RETRO_MEMORY_SYSTEM_RAM  2


#define RETRO_MEMORY_VIDEO_RAM   3


#define RETRO_MEMORY_ROM   4




enum retro_key
{
   RETROK_UNKNOWN        = 0,
   RETROK_FIRST          = 0,
   RETROK_BACKSPACE      = 8,
   RETROK_TAB            = 9,
   RETROK_CLEAR          = 12,
   RETROK_RETURN         = 13,
   RETROK_PAUSE          = 19,
   RETROK_ESCAPE         = 27,
   RETROK_SPACE          = 32,
   RETROK_EXCLAIM        = 33,
   RETROK_QUOTEDBL       = 34,
   RETROK_HASH           = 35,
   RETROK_DOLLAR         = 36,
   RETROK_AMPERSAND      = 38,
   RETROK_QUOTE          = 39,
   RETROK_LEFTPAREN      = 40,
   RETROK_RIGHTPAREN     = 41,
   RETROK_ASTERISK       = 42,
   RETROK_PLUS           = 43,
   RETROK_COMMA          = 44,
   RETROK_MINUS          = 45,
   RETROK_PERIOD         = 46,
   RETROK_SLASH          = 47,
   RETROK_0              = 48,
   RETROK_1              = 49,
   RETROK_2              = 50,
   RETROK_3              = 51,
   RETROK_4              = 52,
   RETROK_5              = 53,
   RETROK_6              = 54,
   RETROK_7              = 55,
   RETROK_8              = 56,
   RETROK_9              = 57,
   RETROK_COLON          = 58,
   RETROK_SEMICOLON      = 59,
   RETROK_LESS           = 60,
   RETROK_EQUALS         = 61,
   RETROK_GREATER        = 62,
   RETROK_QUESTION       = 63,
   RETROK_AT             = 64,
   RETROK_LEFTBRACKET    = 91,
   RETROK_BACKSLASH      = 92,
   RETROK_RIGHTBRACKET   = 93,
   RETROK_CARET          = 94,
   RETROK_UNDERSCORE     = 95,
   RETROK_BACKQUOTE      = 96,
   RETROK_a              = 97,
   RETROK_b              = 98,
   RETROK_c              = 99,
   RETROK_d              = 100,
   RETROK_e              = 101,
   RETROK_f              = 102,
   RETROK_g              = 103,
   RETROK_h              = 104,
   RETROK_i              = 105,
   RETROK_j              = 106,
   RETROK_k              = 107,
   RETROK_l              = 108,
   RETROK_m              = 109,
   RETROK_n              = 110,
   RETROK_o              = 111,
   RETROK_p              = 112,
   RETROK_q              = 113,
   RETROK_r              = 114,
   RETROK_s              = 115,
   RETROK_t              = 116,
   RETROK_u              = 117,
   RETROK_v              = 118,
   RETROK_w              = 119,
   RETROK_x              = 120,
   RETROK_y              = 121,
   RETROK_z              = 122,
   RETROK_LEFTBRACE      = 123,
   RETROK_BAR            = 124,
   RETROK_RIGHTBRACE     = 125,
   RETROK_TILDE          = 126,
   RETROK_DELETE         = 127,

   RETROK_KP0            = 256,
   RETROK_KP1            = 257,
   RETROK_KP2            = 258,
   RETROK_KP3            = 259,
   RETROK_KP4            = 260,
   RETROK_KP5            = 261,
   RETROK_KP6            = 262,
   RETROK_KP7            = 263,
   RETROK_KP8            = 264,
   RETROK_KP9            = 265,
   RETROK_KP_PERIOD      = 266,
   RETROK_KP_DIVIDE      = 267,
   RETROK_KP_MULTIPLY    = 268,
   RETROK_KP_MINUS       = 269,
   RETROK_KP_PLUS        = 270,
   RETROK_KP_ENTER       = 271,
   RETROK_KP_EQUALS      = 272,

   RETROK_UP             = 273,
   RETROK_DOWN           = 274,
   RETROK_RIGHT          = 275,
   RETROK_LEFT           = 276,
   RETROK_INSERT         = 277,
   RETROK_HOME           = 278,
   RETROK_END            = 279,
   RETROK_PAGEUP         = 280,
   RETROK_PAGEDOWN       = 281,

   RETROK_F1             = 282,
   RETROK_F2             = 283,
   RETROK_F3             = 284,
   RETROK_F4             = 285,
   RETROK_F5             = 286,
   RETROK_F6             = 287,
   RETROK_F7             = 288,
   RETROK_F8             = 289,
   RETROK_F9             = 290,
   RETROK_F10            = 291,
   RETROK_F11            = 292,
   RETROK_F12            = 293,
   RETROK_F13            = 294,
   RETROK_F14            = 295,
   RETROK_F15            = 296,

   RETROK_NUMLOCK        = 300,
   RETROK_CAPSLOCK       = 301,
   RETROK_SCROLLOCK      = 302,
   RETROK_RSHIFT         = 303,
   RETROK_LSHIFT         = 304,
   RETROK_RCTRL          = 305,
   RETROK_LCTRL          = 306,
   RETROK_RALT           = 307,
   RETROK_LALT           = 308,
   RETROK_RMETA          = 309,
   RETROK_LMETA          = 310,
   RETROK_LSUPER         = 311,
   RETROK_RSUPER         = 312,
   RETROK_MODE           = 313,
   RETROK_COMPOSE        = 314,

   RETROK_HELP           = 315,
   RETROK_PRINT          = 316,
   RETROK_SYSREQ         = 317,
   RETROK_BREAK          = 318,
   RETROK_MENU           = 319,
   RETROK_POWER          = 320,
   RETROK_EURO           = 321,
   RETROK_UNDO           = 322,
   RETROK_OEM_102        = 323,

   RETROK_BROWSER_BACK      = 324,
   RETROK_BROWSER_FORWARD   = 325,
   RETROK_BROWSER_REFRESH   = 326,
   RETROK_BROWSER_STOP      = 327,
   RETROK_BROWSER_SEARCH    = 328,
   RETROK_BROWSER_FAVORITES = 329,
   RETROK_BROWSER_HOME      = 330,
   RETROK_VOLUME_MUTE       = 331,
   RETROK_VOLUME_DOWN       = 332,
   RETROK_VOLUME_UP         = 333,
   RETROK_MEDIA_NEXT        = 334,
   RETROK_MEDIA_PREV        = 335,
   RETROK_MEDIA_STOP        = 336,
   RETROK_MEDIA_PLAY_PAUSE  = 337,
   RETROK_LAUNCH_MAIL       = 338,
   RETROK_LAUNCH_MEDIA      = 339,
   RETROK_LAUNCH_APP1       = 340,
   RETROK_LAUNCH_APP2       = 341,

   RETROK_LAST,

   RETROK_DUMMY          = INT_MAX 
};

enum retro_mod
{
   RETROKMOD_NONE       = 0x0000,

   RETROKMOD_SHIFT      = 0x01,
   RETROKMOD_CTRL       = 0x02,
   RETROKMOD_ALT        = 0x04,
   RETROKMOD_META       = 0x08,

   RETROKMOD_NUMLOCK    = 0x10,
   RETROKMOD_CAPSLOCK   = 0x20,
   RETROKMOD_SCROLLOCK  = 0x40,

   RETROKMOD_DUMMY = INT_MAX 
};




#define RETRO_ENVIRONMENT_EXPERIMENTAL 0x10000


#define RETRO_ENVIRONMENT_PRIVATE 0x20000



#define RETRO_ENVIRONMENT_SET_ROTATION  1


#define RETRO_ENVIRONMENT_GET_OVERSCAN  2


#define RETRO_ENVIRONMENT_GET_CAN_DUPE  3




#define RETRO_ENVIRONMENT_SET_MESSAGE   6


#define RETRO_ENVIRONMENT_SHUTDOWN      7


#define RETRO_ENVIRONMENT_SET_PERFORMANCE_LEVEL 8


#define RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY 9


#define RETRO_ENVIRONMENT_SET_PIXEL_FORMAT 10


#define RETRO_ENVIRONMENT_SET_INPUT_DESCRIPTORS 11


#define RETRO_ENVIRONMENT_SET_KEYBOARD_CALLBACK 12


#define RETRO_ENVIRONMENT_SET_DISK_CONTROL_INTERFACE 13


#define RETRO_ENVIRONMENT_SET_HW_RENDER 14


#define RETRO_ENVIRONMENT_GET_VARIABLE 15


#define RETRO_ENVIRONMENT_SET_VARIABLES 16


#define RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE 17


#define RETRO_ENVIRONMENT_SET_SUPPORT_NO_GAME 18


#define RETRO_ENVIRONMENT_GET_LIBRETRO_PATH 19




#define RETRO_ENVIRONMENT_SET_FRAME_TIME_CALLBACK 21


#define RETRO_ENVIRONMENT_SET_AUDIO_CALLBACK 22


#define RETRO_ENVIRONMENT_GET_RUMBLE_INTERFACE 23


#define RETRO_ENVIRONMENT_GET_INPUT_DEVICE_CAPABILITIES 24


#define RETRO_ENVIRONMENT_GET_SENSOR_INTERFACE (25 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_CAMERA_INTERFACE (26 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_LOG_INTERFACE 27


#define RETRO_ENVIRONMENT_GET_PERF_INTERFACE 28


#define RETRO_ENVIRONMENT_GET_LOCATION_INTERFACE 29


#define RETRO_ENVIRONMENT_GET_CONTENT_DIRECTORY 30


#define RETRO_ENVIRONMENT_GET_CORE_ASSETS_DIRECTORY 30


#define RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY 31


#define RETRO_ENVIRONMENT_SET_SYSTEM_AV_INFO 32


#define RETRO_ENVIRONMENT_SET_PROC_ADDRESS_CALLBACK 33


#define RETRO_ENVIRONMENT_SET_SUBSYSTEM_INFO 34


#define RETRO_ENVIRONMENT_SET_CONTROLLER_INFO 35


#define RETRO_ENVIRONMENT_SET_MEMORY_MAPS (36 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_SET_GEOMETRY 37


#define RETRO_ENVIRONMENT_GET_USERNAME 38


#define RETRO_ENVIRONMENT_GET_LANGUAGE 39


#define RETRO_ENVIRONMENT_GET_CURRENT_SOFTWARE_FRAMEBUFFER (40 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_HW_RENDER_INTERFACE (41 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_SET_SUPPORT_ACHIEVEMENTS (42 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_SET_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE (43 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_SET_SERIALIZATION_QUIRKS 44


#define RETRO_ENVIRONMENT_SET_HW_SHARED_CONTEXT (44 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_VFS_INTERFACE (45 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_LED_INTERFACE (46 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_AUDIO_VIDEO_ENABLE (47 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_MIDI_INTERFACE (48 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_FASTFORWARDING (49 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_TARGET_REFRESH_RATE (50 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_INPUT_BITMASKS (51 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_CORE_OPTIONS_VERSION 52


#define RETRO_ENVIRONMENT_SET_CORE_OPTIONS 53


#define RETRO_ENVIRONMENT_SET_CORE_OPTIONS_INTL 54


#define RETRO_ENVIRONMENT_SET_CORE_OPTIONS_DISPLAY 55


#define RETRO_ENVIRONMENT_GET_PREFERRED_HW_RENDER 56


#define RETRO_ENVIRONMENT_GET_DISK_CONTROL_INTERFACE_VERSION 57


#define RETRO_ENVIRONMENT_SET_DISK_CONTROL_EXT_INTERFACE 58


#define RETRO_ENVIRONMENT_GET_MESSAGE_INTERFACE_VERSION 59


#define RETRO_ENVIRONMENT_SET_MESSAGE_EXT 60


#define RETRO_ENVIRONMENT_GET_INPUT_MAX_USERS 61


#define RETRO_ENVIRONMENT_SET_AUDIO_BUFFER_STATUS_CALLBACK 62


#define RETRO_ENVIRONMENT_SET_MINIMUM_AUDIO_LATENCY 63


#define RETRO_ENVIRONMENT_SET_FASTFORWARDING_OVERRIDE 64

#define RETRO_ENVIRONMENT_SET_CONTENT_INFO_OVERRIDE 65
                                           

#define RETRO_ENVIRONMENT_GET_GAME_INFO_EXT 66
                                           


#define RETRO_ENVIRONMENT_SET_CORE_OPTIONS_V2 67


#define RETRO_ENVIRONMENT_SET_CORE_OPTIONS_V2_INTL 68


#define RETRO_ENVIRONMENT_SET_CORE_OPTIONS_UPDATE_DISPLAY_CALLBACK 69


#define RETRO_ENVIRONMENT_SET_VARIABLE 70

#define RETRO_ENVIRONMENT_GET_THROTTLE_STATE (71 | RETRO_ENVIRONMENT_EXPERIMENTAL)
                                           


#define RETRO_ENVIRONMENT_GET_SAVESTATE_CONTEXT (72 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE_SUPPORT (73 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_JIT_CAPABLE 74


#define RETRO_ENVIRONMENT_GET_MICROPHONE_INTERFACE (75 | RETRO_ENVIRONMENT_EXPERIMENTAL)




#define RETRO_ENVIRONMENT_GET_DEVICE_POWER (77 | RETRO_ENVIRONMENT_EXPERIMENTAL)

#define RETRO_ENVIRONMENT_SET_NETPACKET_INTERFACE 78
                                           


#define RETRO_ENVIRONMENT_GET_DEVICE_POWER (77 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_PLAYLIST_DIRECTORY 79


#define RETRO_ENVIRONMENT_GET_FILE_BROWSER_START_DIRECTORY 80


#define RETRO_ENVIRONMENT_GET_TARGET_SAMPLE_RATE (81 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_GET_NETPLAY_CLIENT_INDEX (82 | RETRO_ENVIRONMENT_EXPERIMENTAL)


#define RETRO_ENVIRONMENT_EXEC_MEM_ALLOC 83


#define RETRO_ENVIRONMENT_EXEC_MEM_FREE  84






struct retro_vfs_file_handle;


struct retro_vfs_dir_handle;




#define RETRO_VFS_FILE_ACCESS_READ            (1 << 0)


#define RETRO_VFS_FILE_ACCESS_WRITE           (1 << 1)


#define RETRO_VFS_FILE_ACCESS_READ_WRITE      (RETRO_VFS_FILE_ACCESS_READ | RETRO_VFS_FILE_ACCESS_WRITE)


#define RETRO_VFS_FILE_ACCESS_UPDATE_EXISTING (1 << 2) 






#define RETRO_VFS_FILE_ACCESS_HINT_NONE              (0)


#define RETRO_VFS_FILE_ACCESS_HINT_FREQUENT_ACCESS   (1 << 0)






#define RETRO_VFS_SEEK_POSITION_START    0


#define RETRO_VFS_SEEK_POSITION_CURRENT  1


#define RETRO_VFS_SEEK_POSITION_END      2






#define RETRO_VFS_STAT_IS_VALID               (1 << 0)


#define RETRO_VFS_STAT_IS_DIRECTORY           (1 << 1)


#define RETRO_VFS_STAT_IS_CHARACTER_SPECIAL   (1 << 2)




typedef const char *(RETRO_CALLCONV *retro_vfs_get_path_t)(struct retro_vfs_file_handle *stream);


typedef struct retro_vfs_file_handle *(RETRO_CALLCONV *retro_vfs_open_t)(const char *path, unsigned mode, unsigned hints);


typedef int (RETRO_CALLCONV *retro_vfs_close_t)(struct retro_vfs_file_handle *stream);


typedef int64_t (RETRO_CALLCONV *retro_vfs_size_t)(struct retro_vfs_file_handle *stream);


typedef int64_t (RETRO_CALLCONV *retro_vfs_truncate_t)(struct retro_vfs_file_handle *stream, int64_t length);


typedef int64_t (RETRO_CALLCONV *retro_vfs_tell_t)(struct retro_vfs_file_handle *stream);


typedef int64_t (RETRO_CALLCONV *retro_vfs_seek_t)(struct retro_vfs_file_handle *stream, int64_t offset, int seek_position);


typedef int64_t (RETRO_CALLCONV *retro_vfs_read_t)(struct retro_vfs_file_handle *stream, void *s, uint64_t len);


typedef int64_t (RETRO_CALLCONV *retro_vfs_write_t)(struct retro_vfs_file_handle *stream, const void *s, uint64_t len);


typedef int (RETRO_CALLCONV *retro_vfs_flush_t)(struct retro_vfs_file_handle *stream);


typedef int (RETRO_CALLCONV *retro_vfs_remove_t)(const char *path);


typedef int (RETRO_CALLCONV *retro_vfs_rename_t)(const char *old_path, const char *new_path);


typedef int (RETRO_CALLCONV *retro_vfs_stat_t)(const char *path, int32_t *size);


typedef int (RETRO_CALLCONV *retro_vfs_stat_64_t)(const char *path, int64_t *size);


typedef int (RETRO_CALLCONV *retro_vfs_mkdir_t)(const char *dir);


typedef struct retro_vfs_dir_handle *(RETRO_CALLCONV *retro_vfs_opendir_t)(const char *dir, bool include_hidden);


typedef bool (RETRO_CALLCONV *retro_vfs_readdir_t)(struct retro_vfs_dir_handle *dirstream);


typedef const char *(RETRO_CALLCONV *retro_vfs_dirent_get_name_t)(struct retro_vfs_dir_handle *dirstream);


typedef bool (RETRO_CALLCONV *retro_vfs_dirent_is_dir_t)(struct retro_vfs_dir_handle *dirstream);


typedef int (RETRO_CALLCONV *retro_vfs_closedir_t)(struct retro_vfs_dir_handle *dirstream);


struct retro_vfs_interface
{
   
   
	retro_vfs_get_path_t get_path;

   
	retro_vfs_open_t open;

   
	retro_vfs_close_t close;

   
	retro_vfs_size_t size;

   
	retro_vfs_tell_t tell;

   
	retro_vfs_seek_t seek;

   
	retro_vfs_read_t read;

   
	retro_vfs_write_t write;

   
	retro_vfs_flush_t flush;

   
	retro_vfs_remove_t remove;

   
	retro_vfs_rename_t rename;
   

   
   retro_vfs_truncate_t truncate;
   

   
   retro_vfs_stat_t stat;

   
   retro_vfs_mkdir_t mkdir;

   
   retro_vfs_opendir_t opendir;

   
   retro_vfs_readdir_t readdir;

   
   retro_vfs_dirent_get_name_t dirent_get_name;

   
   retro_vfs_dirent_is_dir_t dirent_is_dir;

   
   retro_vfs_closedir_t closedir;

   
   
   retro_vfs_stat_64_t stat_64;
};


struct retro_vfs_interface_info
{
   
   uint32_t required_interface_version;

   
   struct retro_vfs_interface *iface;
};






enum retro_hw_render_interface_type
{
   
   RETRO_HW_RENDER_INTERFACE_VULKAN     = 0,

   
   RETRO_HW_RENDER_INTERFACE_D3D9       = 1,

   
   RETRO_HW_RENDER_INTERFACE_D3D10      = 2,

   
   RETRO_HW_RENDER_INTERFACE_D3D11      = 3,

   
   RETRO_HW_RENDER_INTERFACE_D3D12      = 4,

   
   RETRO_HW_RENDER_INTERFACE_GSKIT_PS2  = 5,

   
   RETRO_HW_RENDER_INTERFACE_DUMMY      = INT_MAX
};


struct retro_hw_render_interface
{
   
   enum retro_hw_render_interface_type interface_type;

   
   unsigned interface_version;
};






typedef void (RETRO_CALLCONV *retro_set_led_state_t)(int led, int state);


struct retro_led_interface
{
   
   retro_set_led_state_t set_led_state;
};






enum retro_av_enable_flags
{
   
   RETRO_AV_ENABLE_VIDEO = (1 << 0),

   
   RETRO_AV_ENABLE_AUDIO = (1 << 1),

   
   RETRO_AV_ENABLE_FAST_SAVESTATES = (1 << 2),

   
   RETRO_AV_ENABLE_HARD_DISABLE_AUDIO = (1 << 3),

   
   RETRO_AV_ENABLE_DUMMY = INT_MAX
};






typedef bool (RETRO_CALLCONV *retro_midi_input_enabled_t)(void);


typedef bool (RETRO_CALLCONV *retro_midi_output_enabled_t)(void);


typedef bool (RETRO_CALLCONV *retro_midi_read_t)(uint8_t *byte);


typedef bool (RETRO_CALLCONV *retro_midi_write_t)(uint8_t byte, uint32_t delta_time);


typedef bool (RETRO_CALLCONV *retro_midi_flush_t)(void);


struct retro_midi_interface
{
   
   retro_midi_input_enabled_t input_enabled;

   
   retro_midi_output_enabled_t output_enabled;

   
   retro_midi_read_t read;

   
   retro_midi_write_t write;

   
   retro_midi_flush_t flush;
};






enum retro_hw_render_context_negotiation_interface_type
{
   
   RETRO_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE_VULKAN = 0,

   
   RETRO_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE_DUMMY = INT_MAX
};


struct retro_hw_render_context_negotiation_interface
{
   
   enum retro_hw_render_context_negotiation_interface_type interface_type;

   
   unsigned interface_version;
};






#define RETRO_SERIALIZATION_QUIRK_INCOMPLETE (1 << 0)


#define RETRO_SERIALIZATION_QUIRK_MUST_INITIALIZE (1 << 1)


#define RETRO_SERIALIZATION_QUIRK_CORE_VARIABLE_SIZE (1 << 2)


#define RETRO_SERIALIZATION_QUIRK_FRONT_VARIABLE_SIZE (1 << 3)


#define RETRO_SERIALIZATION_QUIRK_SINGLE_SESSION (1 << 4)


#define RETRO_SERIALIZATION_QUIRK_ENDIAN_DEPENDENT (1 << 5)


#define RETRO_SERIALIZATION_QUIRK_PLATFORM_DEPENDENT (1 << 6)








#define RETRO_MEMDESC_CONST      (1 << 0)


#define RETRO_MEMDESC_BIGENDIAN  (1 << 1)


#define RETRO_MEMDESC_SYSTEM_RAM (1 << 2)


#define RETRO_MEMDESC_SAVE_RAM   (1 << 3)


#define RETRO_MEMDESC_VIDEO_RAM  (1 << 4)


#define RETRO_MEMDESC_ALIGN_2    (1 << 16)


#define RETRO_MEMDESC_ALIGN_4    (2 << 16)


#define RETRO_MEMDESC_ALIGN_8    (3 << 16)


#define RETRO_MEMDESC_MINSIZE_2  (1 << 24)


#define RETRO_MEMDESC_MINSIZE_4  (2 << 24)


#define RETRO_MEMDESC_MINSIZE_8  (3 << 24)




struct retro_memory_descriptor
{
   
   uint64_t flags;

   
   void *ptr;

   
   size_t offset;

   
   size_t start;

   
   size_t select;

   
   size_t disconnect;

   
   size_t len;

   
   const char *addrspace;

   

   

   

   

   

   
};


struct retro_memory_map
{
   
   const struct retro_memory_descriptor *descriptors;

   
   unsigned num_descriptors;
};






struct retro_controller_description
{
   
   const char *desc;

   
   unsigned id;
};


struct retro_controller_info
{

   
   const struct retro_controller_description *types;

   
   unsigned num_types;
};






struct retro_subsystem_memory_info
{
   
   const char *extension;

   
   unsigned type;
};


struct retro_subsystem_rom_info
{
   
   const char *desc;

   
   const char *valid_extensions;

   
   bool need_fullpath;

   
   bool block_extract;

   
   bool required;

   
   const struct retro_subsystem_memory_info *memory;

   
   unsigned num_memory;
};


struct retro_subsystem_info
{
   
   const char *desc;

   
   const char *ident;

   
   const struct retro_subsystem_rom_info *roms;

   
   unsigned num_roms;

   
   unsigned id;
};






typedef void (RETRO_CALLCONV *retro_proc_address_t)(void);


typedef retro_proc_address_t (RETRO_CALLCONV *retro_get_proc_address_t)(const char *sym);


struct retro_get_proc_address_interface
{
   
   retro_get_proc_address_t get_proc_address;
};






enum retro_log_level
{
   
   RETRO_LOG_DEBUG = 0,

   
   RETRO_LOG_INFO,

   
   RETRO_LOG_WARN,

   
   RETRO_LOG_ERROR,

   
   RETRO_LOG_DUMMY = INT_MAX
};


typedef void (RETRO_CALLCONV *retro_log_printf_t)(enum retro_log_level level,
      const char *fmt, ...);


struct retro_log_callback
{
   
   retro_log_printf_t log;
};








#define RETRO_SIMD_SSE      (1 << 0)


#define RETRO_SIMD_SSE2     (1 << 1)


#define RETRO_SIMD_VMX      (1 << 2)


#define RETRO_SIMD_VMX128   (1 << 3)


#define RETRO_SIMD_AVX      (1 << 4)


#define RETRO_SIMD_NEON     (1 << 5)


#define RETRO_SIMD_SSE3     (1 << 6)


#define RETRO_SIMD_SSSE3    (1 << 7)


#define RETRO_SIMD_MMX      (1 << 8)


#define RETRO_SIMD_MMXEXT   (1 << 9)


#define RETRO_SIMD_SSE4     (1 << 10)


#define RETRO_SIMD_SSE42    (1 << 11)


#define RETRO_SIMD_AVX2     (1 << 12)


#define RETRO_SIMD_VFPU     (1 << 13)


#define RETRO_SIMD_PS       (1 << 14)


#define RETRO_SIMD_AES      (1 << 15)


#define RETRO_SIMD_VFPV3    (1 << 16)


#define RETRO_SIMD_VFPV4    (1 << 17)


#define RETRO_SIMD_POPCNT   (1 << 18)


#define RETRO_SIMD_MOVBE    (1 << 19)


#define RETRO_SIMD_CMOV     (1 << 20)


#define RETRO_SIMD_ASIMD    (1 << 21)


#define RETRO_SIMD_AVX512   (1 << 22)




typedef uint64_t retro_perf_tick_t;


typedef int64_t retro_time_t;


struct retro_perf_counter
{
   
   const char *ident;

   
   retro_perf_tick_t start;

   
   retro_perf_tick_t total;

   
   retro_perf_tick_t call_cnt;

   
   bool registered;
};


typedef retro_time_t (RETRO_CALLCONV *retro_perf_get_time_usec_t)(void);


typedef retro_perf_tick_t (RETRO_CALLCONV *retro_perf_get_counter_t)(void);


typedef uint64_t (RETRO_CALLCONV *retro_get_cpu_features_t)(void);


typedef void (RETRO_CALLCONV *retro_perf_log_t)(void);


typedef void (RETRO_CALLCONV *retro_perf_register_t)(struct retro_perf_counter *counter);


typedef void (RETRO_CALLCONV *retro_perf_start_t)(struct retro_perf_counter *counter);


typedef void (RETRO_CALLCONV *retro_perf_stop_t)(struct retro_perf_counter *counter);


struct retro_perf_callback
{
   
   retro_perf_get_time_usec_t    get_time_usec;

   
   retro_get_cpu_features_t      get_cpu_features;

   
   retro_perf_get_counter_t      get_perf_counter;

   
   retro_perf_register_t         perf_register;

   
   retro_perf_start_t            perf_start;

   
   retro_perf_stop_t             perf_stop;

   
   retro_perf_log_t              perf_log;
};






enum retro_sensor_action
{
   
   RETRO_SENSOR_ACCELEROMETER_ENABLE = 0,

   
   RETRO_SENSOR_ACCELEROMETER_DISABLE,

   
   RETRO_SENSOR_GYROSCOPE_ENABLE,

   
   RETRO_SENSOR_GYROSCOPE_DISABLE,

   
   RETRO_SENSOR_ILLUMINANCE_ENABLE,

   
   RETRO_SENSOR_ILLUMINANCE_DISABLE,

   
   RETRO_SENSOR_DUMMY = INT_MAX
};





#define RETRO_SENSOR_ACCELEROMETER_X 0


#define RETRO_SENSOR_ACCELEROMETER_Y 1


#define RETRO_SENSOR_ACCELEROMETER_Z 2


#define RETRO_SENSOR_GYROSCOPE_X 3


#define RETRO_SENSOR_GYROSCOPE_Y 4


#define RETRO_SENSOR_GYROSCOPE_Z 5


#define RETRO_SENSOR_ILLUMINANCE 6



typedef bool (RETRO_CALLCONV *retro_set_sensor_state_t)(unsigned port,
      enum retro_sensor_action action, unsigned rate);


typedef float (RETRO_CALLCONV *retro_sensor_get_input_t)(unsigned port, unsigned id);


struct retro_sensor_interface
{
   
   retro_set_sensor_state_t set_sensor_state;

   
   retro_sensor_get_input_t get_sensor_input;
};






enum retro_camera_buffer
{
   
   RETRO_CAMERA_BUFFER_OPENGL_TEXTURE = 0,

   
   RETRO_CAMERA_BUFFER_RAW_FRAMEBUFFER,

   
   RETRO_CAMERA_BUFFER_DUMMY = INT_MAX
};


typedef bool (RETRO_CALLCONV *retro_camera_start_t)(void);


typedef void (RETRO_CALLCONV *retro_camera_stop_t)(void);


typedef void (RETRO_CALLCONV *retro_camera_lifetime_status_t)(void);


typedef void (RETRO_CALLCONV *retro_camera_frame_raw_framebuffer_t)(const uint32_t *buffer,
      unsigned width, unsigned height, size_t pitch);


typedef void (RETRO_CALLCONV *retro_camera_frame_opengl_texture_t)(unsigned texture_id,
      unsigned texture_target, const float *affine);


struct retro_camera_callback
{
   
   uint64_t caps;

   
   unsigned width;

   
   unsigned height;

   
   retro_camera_start_t start;

   
   retro_camera_stop_t stop;

   
   retro_camera_frame_raw_framebuffer_t frame_raw_framebuffer;

   
   retro_camera_frame_opengl_texture_t frame_opengl_texture;

   
   retro_camera_lifetime_status_t initialized;

   
   retro_camera_lifetime_status_t deinitialized;
};






typedef void (RETRO_CALLCONV *retro_location_set_interval_t)(unsigned interval_ms,
      unsigned interval_distance);


typedef bool (RETRO_CALLCONV *retro_location_start_t)(void);


typedef void (RETRO_CALLCONV *retro_location_stop_t)(void);


typedef bool (RETRO_CALLCONV *retro_location_get_position_t)(double *lat, double *lon,
      double *horiz_accuracy, double *vert_accuracy);


typedef void (RETRO_CALLCONV *retro_location_lifetime_status_t)(void);


struct retro_location_callback
{
   
   retro_location_start_t         start;

   
   retro_location_stop_t          stop;

   
   retro_location_get_position_t  get_position;

   
   retro_location_set_interval_t  set_interval;

   
   retro_location_lifetime_status_t initialized;

   
   retro_location_lifetime_status_t deinitialized;
};






enum retro_rumble_effect
{
   RETRO_RUMBLE_STRONG = 0,
   RETRO_RUMBLE_WEAK = 1,

   
   RETRO_RUMBLE_DUMMY = INT_MAX
};


typedef bool (RETRO_CALLCONV *retro_set_rumble_state_t)(unsigned port,
      enum retro_rumble_effect effect, uint16_t strength);


struct retro_rumble_interface
{
   
   retro_set_rumble_state_t set_rumble_state;
};




typedef void (RETRO_CALLCONV *retro_audio_callback_t)(void);


typedef void (RETRO_CALLCONV *retro_audio_set_state_callback_t)(bool enabled);


struct retro_audio_callback
{
   
   retro_audio_callback_t callback;

   
   retro_audio_set_state_callback_t set_state;
};

typedef int64_t retro_usec_t;


typedef void (RETRO_CALLCONV *retro_frame_time_callback_t)(retro_usec_t usec);


struct retro_frame_time_callback
{
   
   retro_frame_time_callback_t callback;

   
   retro_usec_t reference;
};




typedef void (RETRO_CALLCONV *retro_audio_buffer_status_callback_t)(
      bool active, unsigned occupancy, bool underrun_likely);


struct retro_audio_buffer_status_callback
{
   
   retro_audio_buffer_status_callback_t callback;
};




#define RETRO_HW_FRAME_BUFFER_VALID ((void*)-1)


typedef void (RETRO_CALLCONV *retro_hw_context_reset_t)(void);


typedef uintptr_t (RETRO_CALLCONV *retro_hw_get_current_framebuffer_t)(void);


typedef retro_proc_address_t (RETRO_CALLCONV *retro_hw_get_proc_address_t)(const char *sym);

enum retro_hw_context_type
{
   RETRO_HW_CONTEXT_NONE             = 0,
   
   RETRO_HW_CONTEXT_OPENGL           = 1,
   
   RETRO_HW_CONTEXT_OPENGLES2        = 2,
   
   RETRO_HW_CONTEXT_OPENGL_CORE      = 3,
   
   RETRO_HW_CONTEXT_OPENGLES3        = 4,
   
   RETRO_HW_CONTEXT_OPENGLES_VERSION = 5,

   
   RETRO_HW_CONTEXT_VULKAN           = 6,

   
   RETRO_HW_CONTEXT_D3D11            = 7,

   
   RETRO_HW_CONTEXT_D3D10            = 8,

   
   RETRO_HW_CONTEXT_D3D12            = 9,

   
   RETRO_HW_CONTEXT_D3D9             = 10,

   
   RETRO_HW_CONTEXT_DUMMY = INT_MAX
};

struct retro_hw_render_callback
{
   
   enum retro_hw_context_type context_type;

   
   retro_hw_context_reset_t context_reset;

   
   retro_hw_get_current_framebuffer_t get_current_framebuffer;

   
   retro_hw_get_proc_address_t get_proc_address;

   
   bool depth;

   
   bool stencil;

   

   
   bool bottom_left_origin;

   
   unsigned version_major;

   
   unsigned version_minor;

   
   bool cache_context;

   

   
   retro_hw_context_reset_t context_destroy;

   

   
   bool debug_context;
};


typedef void (RETRO_CALLCONV *retro_keyboard_event_t)(bool down, unsigned keycode,
      uint32_t character, uint16_t key_modifiers);

struct retro_keyboard_callback
{
   retro_keyboard_event_t callback;
};




typedef bool (RETRO_CALLCONV *retro_set_eject_state_t)(bool ejected);


typedef bool (RETRO_CALLCONV *retro_get_eject_state_t)(void);


typedef unsigned (RETRO_CALLCONV *retro_get_image_index_t)(void);


typedef bool (RETRO_CALLCONV *retro_set_image_index_t)(unsigned index);


typedef unsigned (RETRO_CALLCONV *retro_get_num_images_t)(void);

struct retro_game_info;


typedef bool (RETRO_CALLCONV *retro_replace_image_index_t)(unsigned index,
      const struct retro_game_info *info);


typedef bool (RETRO_CALLCONV *retro_add_image_index_t)(void);


typedef bool (RETRO_CALLCONV *retro_set_initial_image_t)(unsigned index, const char *path);


typedef bool (RETRO_CALLCONV *retro_get_image_path_t)(unsigned index, char *s, size_t len);


typedef bool (RETRO_CALLCONV *retro_get_image_label_t)(unsigned index, char *s, size_t len);


struct retro_disk_control_callback
{
   
   retro_set_eject_state_t set_eject_state;

   
   retro_get_eject_state_t get_eject_state;

   
   retro_get_image_index_t get_image_index;

   
   retro_set_image_index_t set_image_index;

   
   retro_get_num_images_t  get_num_images;

   
   retro_replace_image_index_t replace_image_index;

   
   retro_add_image_index_t add_image_index;
};


struct retro_disk_control_ext_callback
{
   
   retro_set_eject_state_t set_eject_state;

   
   retro_get_eject_state_t get_eject_state;

   
   retro_get_image_index_t get_image_index;

   
   retro_set_image_index_t set_image_index;

   
   retro_get_num_images_t  get_num_images;

   
   retro_replace_image_index_t replace_image_index;

   
   retro_add_image_index_t add_image_index;

   
   retro_set_initial_image_t set_initial_image;

   
   retro_get_image_path_t get_image_path;

   
   retro_get_image_label_t get_image_label;
};






#define RETRO_NETPACKET_UNRELIABLE  0        
#define RETRO_NETPACKET_RELIABLE    (1 << 0) 
#define RETRO_NETPACKET_UNSEQUENCED (1 << 1) 
#define RETRO_NETPACKET_FLUSH_HINT  (1 << 2) 


#define RETRO_NETPACKET_BROADCAST 0xFFFF


typedef void (RETRO_CALLCONV *retro_netpacket_send_t)(int flags, const void* buf, size_t len, uint16_t client_id);


typedef void (RETRO_CALLCONV *retro_netpacket_poll_receive_t)(void);


typedef void (RETRO_CALLCONV *retro_netpacket_start_t)(uint16_t client_id, retro_netpacket_send_t send_fn, retro_netpacket_poll_receive_t poll_receive_fn);


typedef void (RETRO_CALLCONV *retro_netpacket_receive_t)(const void* buf, size_t len, uint16_t client_id);


typedef void (RETRO_CALLCONV *retro_netpacket_stop_t)(void);


typedef void (RETRO_CALLCONV *retro_netpacket_poll_t)(void);


typedef bool (RETRO_CALLCONV *retro_netpacket_connected_t)(uint16_t client_id);


typedef void (RETRO_CALLCONV *retro_netpacket_disconnected_t)(uint16_t client_id);


struct retro_netpacket_callback
{
   retro_netpacket_start_t        start;
   retro_netpacket_receive_t      receive;
   retro_netpacket_stop_t         stop;         
   retro_netpacket_poll_t         poll;         
   retro_netpacket_connected_t    connected;    
   retro_netpacket_disconnected_t disconnected; 
   const char* protocol_version; 
};


enum retro_pixel_format
{
   
   RETRO_PIXEL_FORMAT_0RGB1555 = 0,

   
   RETRO_PIXEL_FORMAT_XRGB8888 = 1,

   
   RETRO_PIXEL_FORMAT_RGB565   = 2,

   
   RETRO_PIXEL_FORMAT_UNKNOWN  = INT_MAX
};




enum retro_savestate_context
{
   
   RETRO_SAVESTATE_CONTEXT_NORMAL                 = 0,

   
   RETRO_SAVESTATE_CONTEXT_RUNAHEAD_SAME_INSTANCE = 1,

   
   RETRO_SAVESTATE_CONTEXT_RUNAHEAD_SAME_BINARY   = 2,

   
   RETRO_SAVESTATE_CONTEXT_ROLLBACK_NETPLAY       = 3,

   
   RETRO_SAVESTATE_CONTEXT_UNKNOWN                = INT_MAX
};






struct retro_message
{
   
   const char *msg;

   
   unsigned    frames;
};


enum retro_message_target
{
   
   RETRO_MESSAGE_TARGET_ALL = 0,

   
   RETRO_MESSAGE_TARGET_OSD,

   
   RETRO_MESSAGE_TARGET_LOG
};


enum retro_message_type
{
   
   RETRO_MESSAGE_TYPE_NOTIFICATION = 0,

   
   RETRO_MESSAGE_TYPE_NOTIFICATION_ALT,

   
   RETRO_MESSAGE_TYPE_STATUS,

   
   RETRO_MESSAGE_TYPE_PROGRESS
};


struct retro_message_ext
{
   
   const char *msg;

   
   unsigned duration;

   
   unsigned priority;

   
   enum retro_log_level level;

   
   enum retro_message_target target;

   
   enum retro_message_type type;

   
   int8_t progress;
};




struct retro_input_descriptor
{
   
   unsigned port;
   unsigned device;
   unsigned index;
   unsigned id;

   
   const char *description;
};


struct retro_system_info
{
   
   const char *library_name;

   
   const char *library_version;

   
   const char *valid_extensions;

   
   bool        need_fullpath;

   
   bool        block_extract;
};


struct retro_system_content_info_override
{
   
   const char *extensions;

   
   bool need_fullpath;

   
   bool persistent_data;
};


struct retro_game_info_ext
{
   
   const char *full_path;

   
   const char *archive_path;

   
   const char *archive_file;

   
   const char *dir;

   
   const char *name;

   
   const char *ext;

   
   const char *meta;

   
   const void *data;

   
   size_t size;

   
   bool file_in_archive;

   
   bool persistent_data;
};


struct retro_game_geometry
{
   
   unsigned base_width;

   
   unsigned base_height;

   
   unsigned max_width;

   
   unsigned max_height;    

   
   float    aspect_ratio;
};


struct retro_system_timing
{
   
   double fps;

   
   double sample_rate;
};


struct retro_system_av_info
{
   
   struct retro_game_geometry geometry;

   
   struct retro_system_timing timing;
};




struct retro_variable
{
   
   const char *key;

   
   const char *value;
};


struct retro_core_option_display
{
   
   const char *key;

   
   bool visible;
};


#define RETRO_NUM_CORE_OPTION_VALUES_MAX 128


struct retro_core_option_value
{
   
   const char *value;

   
   const char *label;
};


struct retro_core_option_definition
{
   
   const char *key;

   
   const char *desc;

   
   const char *info;

   
   struct retro_core_option_value values[RETRO_NUM_CORE_OPTION_VALUES_MAX];

   
   const char *default_value;
};

#ifdef __PS3__
#undef local
#endif


struct retro_core_options_intl
{
   
   struct retro_core_option_definition *us;

   
   struct retro_core_option_definition *local;
};


struct retro_core_option_v2_category
{
   
   const char *key;

   
   const char *desc;

   
   const char *info;
};


struct retro_core_option_v2_definition
{
   
   const char *key;

   
   const char *desc;

   
   const char *desc_categorized;

   
   const char *info;

   
   const char *info_categorized;

   
   const char *category_key;

   
   struct retro_core_option_value values[RETRO_NUM_CORE_OPTION_VALUES_MAX];

   
   const char *default_value;
};


struct retro_core_options_v2
{
   
   struct retro_core_option_v2_category *categories;

   
   struct retro_core_option_v2_definition *definitions;
};


struct retro_core_options_v2_intl
{
   
   struct retro_core_options_v2 *us;

   
   struct retro_core_options_v2 *local;
};


typedef bool (RETRO_CALLCONV *retro_core_options_update_display_callback_t)(void);


struct retro_core_options_update_display_callback
{
   
   retro_core_options_update_display_callback_t callback;
};



struct retro_game_info
{
   const char *path;       
   const void *data;       
   size_t      size;       
   const char *meta;       
};






#define RETRO_MEMORY_ACCESS_WRITE (1 << 0)


#define RETRO_MEMORY_ACCESS_READ (1 << 1)






#define RETRO_MEMORY_TYPE_CACHED (1 << 0)




struct retro_framebuffer
{
   
   void *data;

   
   unsigned width;

   
   unsigned height;

   
   size_t pitch;

   
   enum retro_pixel_format format;

   
   unsigned access_flags;

   
   unsigned memory_flags;
};






struct retro_fastforwarding_override
{
   
   float ratio;

   
   bool fastforward;

   
   bool notification;

   
   bool inhibit_toggle;
};




#define RETRO_THROTTLE_NONE              0


#define RETRO_THROTTLE_FRAME_STEPPING    1


#define RETRO_THROTTLE_FAST_FORWARD      2


#define RETRO_THROTTLE_SLOW_MOTION       3


#define RETRO_THROTTLE_REWINDING         4


#define RETRO_THROTTLE_VSYNC             5


#define RETRO_THROTTLE_UNBLOCKED         6


struct retro_throttle_state
{
   
   unsigned mode;

   
   float rate;
};




typedef struct retro_microphone retro_microphone_t;


typedef struct retro_microphone_params
{
   
   unsigned rate;
} retro_microphone_params_t;


typedef retro_microphone_t *(RETRO_CALLCONV *retro_open_mic_t)(const retro_microphone_params_t *params);


typedef void (RETRO_CALLCONV *retro_close_mic_t)(retro_microphone_t *microphone);


typedef bool (RETRO_CALLCONV *retro_get_mic_params_t)(const retro_microphone_t *microphone, retro_microphone_params_t *params);


typedef bool (RETRO_CALLCONV *retro_set_mic_state_t)(retro_microphone_t *microphone, bool state);


typedef bool (RETRO_CALLCONV *retro_get_mic_state_t)(const retro_microphone_t *microphone);


typedef int (RETRO_CALLCONV *retro_read_mic_t)(retro_microphone_t *microphone, int16_t* samples, size_t num_samples);


#define RETRO_MICROPHONE_INTERFACE_VERSION 1


struct retro_microphone_interface
{
   
   unsigned interface_version;

   
   retro_open_mic_t open_mic;

   
   retro_close_mic_t close_mic;

   
   retro_get_mic_params_t get_params;

   
   retro_set_mic_state_t set_mic_state;

   
   retro_get_mic_state_t get_mic_state;

   
   retro_read_mic_t read_mic;
};






enum retro_power_state
{
   
   RETRO_POWERSTATE_UNKNOWN = 0,

   
   RETRO_POWERSTATE_DISCHARGING,

   
   RETRO_POWERSTATE_CHARGING,

   
   RETRO_POWERSTATE_CHARGED,

   
   RETRO_POWERSTATE_PLUGGED_IN
};


#define RETRO_POWERSTATE_NO_ESTIMATE (-1)


struct retro_device_power
{
   
   enum retro_power_state state;

   
   int seconds;

   
   int8_t percent;
};





#define RETRO_EXEC_MEM_MODE_UNAVAILABLE  0 
#define RETRO_EXEC_MEM_MODE_UNRESTRICTED 1 
#define RETRO_EXEC_MEM_MODE_RWX          2 
#define RETRO_EXEC_MEM_MODE_WX_TOGGLE    3 
#define RETRO_EXEC_MEM_MODE_DUAL_MAP     4 


struct retro_exec_mem_alloc
{
   unsigned version;  
   size_t   size;     
   unsigned mode;     
   void    *rx;       
   void    *rw;       
};


struct retro_exec_mem_free
{
   void *rx;  
};






typedef bool (RETRO_CALLCONV *retro_environment_t)(unsigned cmd, void *data);


typedef void (RETRO_CALLCONV *retro_video_refresh_t)(const void *data, unsigned width,
      unsigned height, size_t pitch);


typedef void (RETRO_CALLCONV *retro_audio_sample_t)(int16_t left, int16_t right);


typedef size_t (RETRO_CALLCONV *retro_audio_sample_batch_t)(const int16_t *data,
      size_t frames);


typedef void (RETRO_CALLCONV *retro_input_poll_t)(void);


typedef int16_t (RETRO_CALLCONV *retro_input_state_t)(unsigned port, unsigned device,
      unsigned index, unsigned id);


RETRO_API void retro_set_environment(retro_environment_t cb);


RETRO_API void retro_set_video_refresh(retro_video_refresh_t cb);


RETRO_API void retro_set_audio_sample(retro_audio_sample_t cb);


RETRO_API void retro_set_audio_sample_batch(retro_audio_sample_batch_t cb);


RETRO_API void retro_set_input_poll(retro_input_poll_t cb);


RETRO_API void retro_set_input_state(retro_input_state_t cb);




RETRO_API void retro_init(void);


RETRO_API void retro_deinit(void);


RETRO_API unsigned retro_api_version(void);


RETRO_API void retro_get_system_info(struct retro_system_info *info);


RETRO_API void retro_get_system_av_info(struct retro_system_av_info *info);


RETRO_API void retro_set_controller_port_device(unsigned port, unsigned device);


RETRO_API void retro_reset(void);


RETRO_API void retro_run(void);


RETRO_API size_t retro_serialize_size(void);


RETRO_API bool retro_serialize(void *data, size_t len);


RETRO_API bool retro_unserialize(const void *data, size_t len);


RETRO_API void retro_cheat_reset(void);


RETRO_API void retro_cheat_set(unsigned index, bool enabled, const char *code);


RETRO_API bool retro_load_game(const struct retro_game_info *game);


RETRO_API bool retro_load_game_special(
  unsigned game_type,
  const struct retro_game_info *info, size_t num_info
);


RETRO_API void retro_unload_game(void);


RETRO_API unsigned retro_get_region(void);


RETRO_API void *retro_get_memory_data(unsigned id);


RETRO_API size_t retro_get_memory_size(unsigned id);

#ifdef __cplusplus
}
#endif

#endif

