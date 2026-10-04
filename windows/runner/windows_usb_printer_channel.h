#ifndef RUNNER_WINDOWS_USB_PRINTER_CHANNEL_H_
#define RUNNER_WINDOWS_USB_PRINTER_CHANNEL_H_

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>

namespace flutter {
class BinaryMessenger;
}

class WindowsUsbPrinterChannel {
 public:
  explicit WindowsUsbPrinterChannel(flutter::BinaryMessenger* messenger);
  ~WindowsUsbPrinterChannel();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<
      flutter::MethodChannel<flutter::EncodableValue>>
      channel_;
};

#endif  // RUNNER_WINDOWS_USB_PRINTER_CHANNEL_H_
