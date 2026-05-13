#include "libretro_core.h"
#include <iostream>
#include <fstream>
#include <vector>
#include <cstring>
#include <chrono>




#define CONVERT_RGB565_TO_RGBA8888(pixel) \
    (0xFF000000 | (((pixel) & 0x001F) << 19) | (((pixel) & 0x07E0) << 5) | (((pixel) & 0xF800) >> 8))

#define CONVERT_XRGB8888_TO_RGBA8888(pixel) \
    (0xFF000000 | (((pixel) & 0xFF) << 16) | ((pixel) & 0xFF00) | (((pixel) & 0xFF0000) >> 16))

#define CONVERT_0RGB1555_TO_RGBA8888(pixel) \
    (0xFF000000 | (((pixel) & 0x001F) << 19) | (((pixel) & 0x03E0) << 6) | (((pixel) & 0x7C00) >> 9))

LibretroCore* LibretroCore::instance_ = nullptr;

LibretroCore::LibretroCore() {
    instance_ = this;
}

LibretroCore::~LibretroCore() {
    Unload();
    instance_ = nullptr;
}

bool LibretroCore::LoadSymbol(const char* name, void** func) {
#ifdef _WIN32
    *func = (void*)GetProcAddress(dylib_, name);
#else
    *func = dlsym(dylib_, name);
#endif
    return *func != nullptr;
}

bool LibretroCore::LoadCore(const std::string& core_path) {
#ifdef _WIN32
    int len = MultiByteToWideChar(CP_UTF8, 0, core_path.c_str(), -1, NULL, 0);
    wchar_t* w_core_path = new wchar_t[len];
    MultiByteToWideChar(CP_UTF8, 0, core_path.c_str(), -1, w_core_path, len);
    dylib_ = LoadLibraryW(w_core_path);
    delete[] w_core_path;
#else
    dylib_ = dlopen(core_path.c_str(), RTLD_LAZY);
#endif

    if (!dylib_) {
        std::cerr << "Failed to load core: " << core_path << std::endl;
        return false;
    }

    #define LOAD_SYM(name) do { if (!LoadSymbol(#name, (void**)&name)) { std::cerr << "Failed to load symbol " #name << std::endl; return false; } } while(0)
    
    LOAD_SYM(retro_init);
    LOAD_SYM(retro_deinit);
    LOAD_SYM(retro_api_version);
    LOAD_SYM(retro_get_system_info);
    LOAD_SYM(retro_get_system_av_info);
    LOAD_SYM(retro_set_environment);
    LOAD_SYM(retro_set_video_refresh);
    LOAD_SYM(retro_set_audio_sample);
    LOAD_SYM(retro_set_audio_sample_batch);
    LOAD_SYM(retro_set_input_poll);
    LOAD_SYM(retro_set_input_state);
    LOAD_SYM(retro_load_game);
    LOAD_SYM(retro_unload_game);
    LOAD_SYM(retro_reset);
    LOAD_SYM(retro_run);
    LOAD_SYM(retro_serialize_size);
    LOAD_SYM(retro_serialize);
    LOAD_SYM(retro_unserialize);
    
    retro_set_environment(retro_environment_cb);
    retro_set_video_refresh(retro_video_refresh_cb);
    retro_set_audio_sample(retro_audio_sample_cb);
    retro_set_audio_sample_batch(retro_audio_sample_batch_cb);
    retro_set_input_poll(retro_input_poll_cb);
    retro_set_input_state(retro_input_state_cb);
    
    retro_init();
    
    return true;
}

bool LibretroCore::LoadGame(const std::string& rom_path) {
    std::ifstream file(rom_path, std::ios::binary | std::ios::ate);
    if (!file.is_open()) {
        std::cerr << "Failed to open ROM: " << rom_path << std::endl;
        return false;
    }

    std::streamsize size = file.tellg();
    file.seekg(0, std::ios::beg);

    std::vector<char> buffer(size);
    if (!file.read(buffer.data(), size)) {
        std::cerr << "Failed to read ROM: " << rom_path << std::endl;
        return false;
    }

    retro_game_info game_info = {0};
    game_info.path = rom_path.c_str();
    game_info.data = buffer.data();
    game_info.size = (size_t)size;
    game_info.meta = "";
    
    bool result = retro_load_game(&game_info);
    if (!result) {
        std::cerr << "retro_load_game failed for " << rom_path << std::endl;
        return false;
    }

    retro_system_av_info av_info;
    retro_get_system_av_info(&av_info);

    sample_rate_ = av_info.timing.sample_rate;
    video_width_ = av_info.geometry.base_width;
    video_height_ = av_info.geometry.base_height;
    
    video_pitch_ = video_width_ * 4; 
    
    if (av_info.geometry.aspect_ratio > 0.0) {
        aspect_ratio_ = av_info.geometry.aspect_ratio;
    } else {
        aspect_ratio_ = (double)video_width_ / video_height_;
    }

    video_buffer_.resize(video_pitch_ * video_height_);
    
    return true;
}

void LibretroCore::Unload() {
    StopThread();
    if (dylib_) {
        retro_unload_game();
        retro_deinit();
#ifdef _WIN32
        FreeLibrary(dylib_);
#else
        dlclose(dylib_);
#endif
        dylib_ = nullptr;
    }
}

void LibretroCore::Reset() {
    if (dylib_ && retro_reset) {
        retro_reset();
    }
}

std::vector<uint8_t> LibretroCore::SaveState() {
    if (!dylib_ || !retro_serialize_size || !retro_serialize) return {};
    
    size_t size = retro_serialize_size();
    if (size == 0) return {};
    
    std::vector<uint8_t> buffer(size);
    if (retro_serialize(buffer.data(), size)) {
        return buffer;
    }
    return {};
}

bool LibretroCore::LoadState(const std::vector<uint8_t>& state) {
    if (!dylib_ || !retro_unserialize || state.empty()) return false;
    bool success = retro_unserialize(state.data(), state.size());
    if (success) {
        ClearAudioBuffer(); 
    }
    return success;
}

void LibretroCore::RunFrame() {
    if (dylib_) {
        if (slow_motion_) {
            slow_motion_count_++;
            if (slow_motion_count_ % 2 != 0) return; 
        }

        retro_run();
        
        if (fast_forward_) {
            retro_run();
            retro_run();
        }
    }
}

void LibretroCore::ThreadLoop() {
    using namespace std::chrono;
    while (thread_running_) {
        auto start = high_resolution_clock::now();
        if (!is_paused_) {
            RunFrame();
        }
        auto elapsed = high_resolution_clock::now() - start;
        
        auto sleep_time = milliseconds(16) - duration_cast<milliseconds>(elapsed);
        if (sleep_time.count() > 0) {
            std::this_thread::sleep_for(sleep_time);
        } else {
            std::this_thread::yield();
        }
    }
}

void LibretroCore::StartThread() {
    if (!thread_running_) {
        thread_running_ = true;
        is_paused_ = false;
        run_thread_ = std::thread(&LibretroCore::ThreadLoop, this);
    }
}

void LibretroCore::StopThread() {
    if (thread_running_) {
        thread_running_ = false;
        if (run_thread_.joinable()) {
            run_thread_.join();
        }
    }
}

void LibretroCore::Pause() {
    is_paused_ = true;
}

void LibretroCore::Resume() {
    is_paused_ = false;
}

void LibretroCore::UpdateInputState(unsigned port, unsigned id, bool pressed) {
    if (port < 2 && id < 16) {
        input_state_[port][id] = pressed;
    }
}

void LibretroCore::UpdateAnalogState(unsigned port, unsigned index, unsigned id, int16_t value) {
    if (port < 2 && index < 2 && id < 2) {
        analog_state_[port][index][id] = value;
    }
}



bool LibretroCore::retro_environment_cb(unsigned cmd, void *data) {
    if (!instance_) return false;

    switch (cmd) {
        case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT: {
            if (!data) return false;
            const retro_pixel_format *fmt = (retro_pixel_format *)data;
            instance_->pixel_format_ = *fmt;
            return true;
        }
        case RETRO_ENVIRONMENT_GET_CAN_DUPE: {
            if (data) *(bool*)data = true;
            return true;
        }
        case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
        case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
        case RETRO_ENVIRONMENT_GET_CONTENT_DIRECTORY: {
            if (data) *(const char**)data = "."; 
            return true;
        }
        case RETRO_ENVIRONMENT_GET_VARIABLE: {
            
            
            return false;
        }
        default:
            return false;
    }
}

void LibretroCore::retro_video_refresh_cb(const void *data, unsigned width, unsigned height, size_t pitch) {
    if (!instance_ || !data) return;

    std::lock_guard<std::mutex> lock(instance_->video_mutex_);

    
    if (width != instance_->video_width_ || height != instance_->video_height_) {
        instance_->video_width_ = width;
        instance_->video_height_ = height;
        instance_->video_pitch_ = width * 4;
        instance_->video_buffer_.resize(instance_->video_pitch_ * height);
    }

    uint8_t* dest = instance_->video_buffer_.data();

    
    
    
    for (unsigned y = 0; y < height; y++) {
        const uint8_t* src_row = (const uint8_t*)data + (y * pitch);
        uint32_t* dest_row = (uint32_t*)(dest + (y * instance_->video_pitch_));
        
        for (unsigned x = 0; x < width; x++) {
            if (instance_->pixel_format_ == RETRO_PIXEL_FORMAT_RGB565) {
                uint16_t pixel = *((uint16_t*)(src_row + (x * 2)));
                dest_row[x] = CONVERT_RGB565_TO_RGBA8888(pixel);
            } else if (instance_->pixel_format_ == RETRO_PIXEL_FORMAT_XRGB8888) {
                uint32_t pixel = *((uint32_t*)(src_row + (x * 4)));
                dest_row[x] = CONVERT_XRGB8888_TO_RGBA8888(pixel);
            } else {
                uint16_t pixel = *((uint16_t*)(src_row + (x * 2)));
                dest_row[x] = CONVERT_0RGB1555_TO_RGBA8888(pixel);
            }
        }
    }
    
    if (instance_->frame_available_cb_) {
        instance_->frame_available_cb_();
    }
}

void LibretroCore::retro_audio_sample_cb(int16_t left, int16_t right) {
    if (!instance_) return;
    std::lock_guard<std::mutex> lock(instance_->audio_mutex_);
    instance_->audio_buffer_.push_back(left);
    instance_->audio_buffer_.push_back(right);
}

size_t LibretroCore::retro_audio_sample_batch_cb(const int16_t *data, size_t frames) {
    if (!instance_ || !data) return 0;
    std::lock_guard<std::mutex> lock(instance_->audio_mutex_);
    instance_->audio_buffer_.insert(instance_->audio_buffer_.end(), data, data + frames * 2);
    return frames;
}

void LibretroCore::retro_input_poll_cb() {}

int16_t LibretroCore::retro_input_state_cb(unsigned port, unsigned device, unsigned index, unsigned id) {
    if (!instance_) return 0;
    
    if (device == RETRO_DEVICE_JOYPAD && port < 2 && id < 16) {
        return instance_->input_state_[port][id] ? 1 : 0;
    }
    
    if (device == RETRO_DEVICE_ANALOG && port < 2 && index < 2 && id < 2) {
        return instance_->analog_state_[port][index][id];
    }
    
    return 0;
}

