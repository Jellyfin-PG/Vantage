#include "emulator_plugin.h"

#include <windows.h>
#include <iostream>

void EmulatorPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.retrostream.vantage/emulator",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<EmulatorPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

EmulatorPlugin::EmulatorPlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar) {}

EmulatorPlugin::~EmulatorPlugin() {
  CleanupAudio();
  if (core_module_) {
    FreeLibrary(core_module_);
  }
}

void EmulatorPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("launch") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto corePathIt = arguments->find(flutter::EncodableValue("corePath"));
      auto romPathIt = arguments->find(flutter::EncodableValue("romPath"));
      
      if (corePathIt != arguments->end() && romPathIt != arguments->end()) {
        std::string core_path = std::get<std::string>(corePathIt->second);
        std::string rom_path = std::get<std::string>(romPathIt->second);

        
        libretro_core_.Unload();

        if (!libretro_core_.LoadCore(core_path)) {
          result->Error("CORE_LOAD_FAILED", "Could not load libretro core");
          return;
        }

        if (!libretro_core_.LoadGame(rom_path)) {
          result->Error("GAME_LOAD_FAILED", "Could not load game ROM");
          return;
        }

        
        {
          std::lock_guard<std::mutex> lock(texture_mutex_);
          if (texture_id_ != -1 && texture_) {
              registrar_->texture_registrar()->UnregisterTexture(texture_id_);
              texture_id_ = -1;
          }

          texture_ = std::make_unique<flutter::TextureVariant>(
              flutter::PixelBufferTexture([this](size_t width, size_t height) -> const FlutterDesktopPixelBuffer* {
                std::lock_guard<std::mutex> lock(libretro_core_.GetVideoMutex());
                
                static FlutterDesktopPixelBuffer flutter_buffer;
                flutter_buffer.width = libretro_core_.GetVideoWidth();
                flutter_buffer.height = libretro_core_.GetVideoHeight();
                flutter_buffer.buffer = libretro_core_.GetVideoBuffer();
                flutter_buffer.release_callback = nullptr;
                
                return &flutter_buffer;
              }));

          texture_id_ = registrar_->texture_registrar()->RegisterTexture(texture_.get());
        }

        
        libretro_core_.SetFrameAvailableCallback([this]() {
            std::lock_guard<std::mutex> lock(texture_mutex_);
            if (texture_id_ != -1) {
                registrar_->texture_registrar()->MarkTextureFrameAvailable(texture_id_);
            }
        });

        
        libretro_core_.StartThread();

        
        InitAudio(libretro_core_.GetSampleRate());

        
        result->Success(flutter::EncodableValue(texture_id_));
        return;
      }
    }
    result->Error("INVALID_ARGUMENTS", "Missing corePath or romPath");
  } else if (method_call.method_name().compare("stop") == 0) {
    CleanupAudio();
    libretro_core_.Unload();
    {
        std::lock_guard<std::mutex> lock(texture_mutex_);
        if (texture_id_ != -1 && texture_) {
            registrar_->texture_registrar()->UnregisterTexture(texture_id_);
            texture_id_ = -1;
        }
    }
    result->Success();
  } else if (method_call.method_name().compare("pause") == 0) {
    libretro_core_.Pause();
    result->Success();
  } else if (method_call.method_name().compare("resume") == 0) {
    libretro_core_.Resume();
    result->Success();
  } else if (method_call.method_name().compare("reset") == 0) {
    libretro_core_.Reset();
    result->Success();
  } else if (method_call.method_name().compare("saveState") == 0) {
    std::vector<uint8_t> state = libretro_core_.SaveState();
    if (!state.empty()) {
        result->Success(flutter::EncodableValue(state));
    } else {
        result->Error("SAVE_FAILED", "Failed to capture core state");
    }
  } else if (method_call.method_name().compare("loadState") == 0) {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
        auto state_it = args->find(flutter::EncodableValue("state"));
        if (state_it != args->end() && std::holds_alternative<std::vector<uint8_t>>(state_it->second)) {
            bool success = libretro_core_.LoadState(std::get<std::vector<uint8_t>>(state_it->second));
            if (success && source_voice_) {
                source_voice_->FlushSourceBuffers(); 
            }
            result->Success(flutter::EncodableValue(success));
            return;
        }
    }
    result->Error("INVALID_ARGS", "Missing state data");
  } else if (method_call.method_name().compare("setVolume") == 0) {
    const auto* volume = std::get_if<double>(method_call.arguments());
    if (volume && source_voice_) {
        source_voice_->SetVolume((float)*volume);
        result->Success();
    } else {
        result->Error("INVALID_ARGS", "Invalid volume level or audio not running");
    }
  } else if (method_call.method_name().compare("setFastForward") == 0) {
    const auto* enabled = std::get_if<bool>(method_call.arguments());
    if (enabled) {
        libretro_core_.SetFastForward(*enabled);
        libretro_core_.ClearAudioBuffer();
        if (source_voice_) {
            source_voice_->FlushSourceBuffers(); 
            source_voice_->SetFrequencyRatio(*enabled ? 3.0f : 1.0f);
        }
        result->Success();
    } else {
        result->Error("INVALID_ARGS", "Missing boolean argument");
    }
  } else if (method_call.method_name().compare("setSlowMotion") == 0) {
    const auto* enabled = std::get_if<bool>(method_call.arguments());
    if (enabled) {
        libretro_core_.SetSlowMotion(*enabled);
        libretro_core_.ClearAudioBuffer();
        if (source_voice_) {
            source_voice_->FlushSourceBuffers(); 
            source_voice_->SetFrequencyRatio(*enabled ? 0.5f : 1.0f);
        }
        result->Success();
    } else {
        result->Error("INVALID_ARGS", "Missing boolean argument");
    }
  } else if (method_call.method_name().compare("setAnalog") == 0) {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
        auto index_it = args->find(flutter::EncodableValue("index"));
        auto id_it = args->find(flutter::EncodableValue("id"));
        auto value_it = args->find(flutter::EncodableValue("value"));
        if (index_it != args->end() && id_it != args->end() && value_it != args->end()) {
            int index = std::get<int>(index_it->second);
            int id = std::get<int>(id_it->second);
            int value = std::get<int>(value_it->second);
            libretro_core_.UpdateAnalogState(0, (unsigned)index, (unsigned)id, (int16_t)value);
            result->Success();
            return;
        }
    }
    result->Error("INVALID_ARGS", "Missing analog arguments");
  } else if (method_call.method_name().compare("keyDown") == 0 || 
             method_call.method_name().compare("keyUp") == 0) {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto keyCodeIt = args->find(flutter::EncodableValue("keyCode"));
      if (keyCodeIt != args->end()) {
        int key_code = std::get<int>(keyCodeIt->second);
        bool pressed = method_call.method_name().compare("keyDown") == 0;
        
        libretro_core_.UpdateInputState(0, (unsigned)key_code, pressed);
      }
    }
    result->Success();
  } else if (method_call.method_name().compare("getAspectRatio") == 0) {
    result->Success(flutter::EncodableValue(libretro_core_.GetAspectRatio()));
  } else {
    result->NotImplemented();
  }
}

void EmulatorPlugin::InitAudio(double sample_rate) {
    CleanupAudio();

    if (sample_rate <= 0) return;

    
    HRESULT hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
    
    if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) return;

    if (FAILED(XAudio2Create(&xaudio2_, 0, XAUDIO2_DEFAULT_PROCESSOR))) return;
    if (FAILED(xaudio2_->CreateMasteringVoice(&mastering_voice_))) return;

    WAVEFORMATEX wfx = {0};
    wfx.wFormatTag = WAVE_FORMAT_PCM;
    wfx.nChannels = 2;
    wfx.nSamplesPerSec = (DWORD)sample_rate;
    wfx.wBitsPerSample = 16;
    wfx.nBlockAlign = (wfx.nChannels * wfx.wBitsPerSample) / 8;
    wfx.nAvgBytesPerSec = wfx.nSamplesPerSec * wfx.nBlockAlign;

    if (FAILED(xaudio2_->CreateSourceVoice(&source_voice_, &wfx, 0, 2.0f, &voice_callback_))) return;
    source_voice_->Start(0);

    audio_running_ = true;
    audio_thread_ = std::thread(&EmulatorPlugin::AudioThreadLoop, this);
}

void EmulatorPlugin::CleanupAudio() {
    audio_running_ = false;
    if (audio_thread_.joinable()) audio_thread_.join();

    if (source_voice_) {
        source_voice_->Stop(0);
        source_voice_->DestroyVoice();
        source_voice_ = nullptr;
    }
    if (mastering_voice_) {
        mastering_voice_->DestroyVoice();
        mastering_voice_ = nullptr;
    }
    xaudio2_.Reset();
}

void EmulatorPlugin::AudioThreadLoop() {
    CoInitializeEx(NULL, COINIT_MULTITHREADED);

    while (audio_running_) {
        if (!source_voice_) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
            continue;
        }

        XAUDIO2_VOICE_STATE state;
        source_voice_->GetState(&state);

        
        if (state.BuffersQueued < 4) {
            std::vector<int16_t> samples;
            {
                std::lock_guard<std::mutex> lock(libretro_core_.GetAudioMutex());
                
                if (libretro_core_.GetAudioBufferMutable().size() >= 1024) {
                    samples.swap(libretro_core_.GetAudioBufferMutable());
                }
            }

            if (!samples.empty()) {
                
                const size_t hard_limit = (size_t)(libretro_core_.GetSampleRate() * 1.0 * 2);
                size_t offset = 0;
                if (samples.size() > hard_limit) {
                    offset = samples.size() - hard_limit;
                    if (offset % 2 != 0) offset--;
                }

                size_t active_samples = samples.size() - offset;
                size_t byte_count = active_samples * sizeof(int16_t);
                
                BYTE* buffer_data = new BYTE[byte_count];
                memcpy(buffer_data, samples.data() + offset, byte_count);

                XAUDIO2_BUFFER buffer = {0};
                buffer.AudioBytes = (UINT32)byte_count;
                buffer.pAudioData = buffer_data;
                buffer.pContext = buffer_data;
                
                HRESULT hr = source_voice_->SubmitSourceBuffer(&buffer);
                if (FAILED(hr)) {
                    delete[] buffer_data;
                }
            }
        }
        
        std::this_thread::yield();
    }

    CoUninitialize();
}

