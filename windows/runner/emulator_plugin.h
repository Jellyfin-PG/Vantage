#ifndef EMULATOR_PLUGIN_H_
#define EMULATOR_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>

#include <memory>
#include <string>
#include <windows.h>
#include <xaudio2.h>
#include <wrl/client.h>

#include "libretro_core.h"

using Microsoft::WRL::ComPtr;

class VoiceCallback : public IXAudio2VoiceCallback {
 public:
  void STDMETHODCALLTYPE OnStreamEnd() override {}
  void STDMETHODCALLTYPE OnVoiceProcessingPassEnd() override {}
  void STDMETHODCALLTYPE OnVoiceProcessingPassStart(UINT32) override {}
  void STDMETHODCALLTYPE OnBufferEnd(void* pBufferContext) override {
    delete[] (BYTE*)pBufferContext;
  }
  void STDMETHODCALLTYPE OnBufferStart(void*) override {}
  void STDMETHODCALLTYPE OnLoopEnd(void*) override {}
  void STDMETHODCALLTYPE OnVoiceError(void*, HRESULT) override {}
};

class EmulatorPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  EmulatorPlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~EmulatorPlugin();

  
  EmulatorPlugin(const EmulatorPlugin&) = delete;
  EmulatorPlugin& operator=(const EmulatorPlugin&) = delete;

 private:
  
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::PluginRegistrarWindows *registrar_;
  std::unique_ptr<flutter::TextureVariant> texture_;
  int64_t texture_id_ = -1;
  std::mutex texture_mutex_;
  LibretroCore libretro_core_;
  HMODULE core_module_ = nullptr;

  
  ComPtr<IXAudio2> xaudio2_;
  IXAudio2MasteringVoice* mastering_voice_ = nullptr;
  IXAudio2SourceVoice* source_voice_ = nullptr;
  VoiceCallback voice_callback_;

  void InitAudio(double sample_rate);
  void CleanupAudio();
  void AudioThreadLoop();
  
  std::thread audio_thread_;
  std::atomic<bool> audio_running_{false};
};

#endif  

