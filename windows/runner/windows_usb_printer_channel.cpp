#include "windows_usb_printer_channel.h"

#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <winspool.h>

#include <string>
#include <utility>
#include <vector>

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

bool IsUsbPort(const wchar_t* port_name) {
  if (port_name == nullptr) {
    return false;
  }

  const std::wstring port(port_name);
  size_t start = 0;
  while (start < port.size()) {
    const size_t end = port.find(L',', start);
    const std::wstring candidate =
        port.substr(start, end == std::wstring::npos ? end : end - start);
    const size_t first = candidate.find_first_not_of(L" \t");
    if (first != std::wstring::npos && candidate.size() - first >= 3 &&
        _wcsnicmp(candidate.c_str() + first, L"USB", 3) == 0) {
      return true;
    }
    if (end == std::wstring::npos) {
      break;
    }
    start = end + 1;
  }

  return false;
}

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return {};
  }

  const int length = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
      static_cast<int>(value.size()), nullptr, 0);
  if (length == 0) {
    return {};
  }

  std::wstring result(length, L'\0');
  MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
                      static_cast<int>(value.size()), result.data(), length);
  return result;
}

std::string WideToUtf8(const wchar_t* value) {
  if (value == nullptr || *value == L'\0') {
    return {};
  }

  const int length =
      WideCharToMultiByte(CP_UTF8, 0, value, -1, nullptr, 0, nullptr, nullptr);
  if (length <= 1) {
    return {};
  }

  std::string result(length, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value, -1, result.data(), length, nullptr,
                      nullptr);
  result.resize(length - 1);
  return result;
}

std::string WindowsErrorMessage(DWORD error_code) {
  wchar_t* message = nullptr;
  const DWORD length = FormatMessageW(
      FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
          FORMAT_MESSAGE_IGNORE_INSERTS,
      nullptr, error_code, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      reinterpret_cast<LPWSTR>(&message), 0, nullptr);

  std::string result =
      length == 0 ? "Windows printer operation failed."
                  : WideToUtf8(message);
  if (message != nullptr) {
    LocalFree(message);
  }
  return result;
}

void ListPrinters(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  DWORD bytes_needed = 0;
  DWORD printers_returned = 0;
  const DWORD flags = PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS;

  EnumPrintersW(flags, nullptr, 2, nullptr, 0, &bytes_needed,
                &printers_returned);
  if (bytes_needed == 0) {
    result->Success(EncodableList{});
    return;
  }

  std::vector<BYTE> buffer(bytes_needed);
  if (!EnumPrintersW(flags, nullptr, 2, buffer.data(), bytes_needed,
                     &bytes_needed, &printers_returned)) {
    const DWORD error_code = GetLastError();
    result->Error("printer_discovery_failed",
                  WindowsErrorMessage(error_code));
    return;
  }

  const auto* printers =
      reinterpret_cast<const PRINTER_INFO_2W*>(buffer.data());
  EncodableList list;
  list.reserve(printers_returned);

  for (DWORD index = 0; index < printers_returned; ++index) {
    if (!IsUsbPort(printers[index].pPortName)) {
      continue;
    }

    EncodableMap printer;
    printer[EncodableValue("name")] =
        EncodableValue(WideToUtf8(printers[index].pPrinterName));
    printer[EncodableValue("model")] =
        EncodableValue(WideToUtf8(printers[index].pDriverName));
    printer[EncodableValue("port")] =
        EncodableValue(WideToUtf8(printers[index].pPortName));
    const DWORD unavailable_flags =
        PRINTER_STATUS_NOT_AVAILABLE | PRINTER_STATUS_ERROR |
        PRINTER_STATUS_OFFLINE | PRINTER_STATUS_PAUSED;
    printer[EncodableValue("available")] =
        EncodableValue((printers[index].Status & unavailable_flags) == 0);
    list.emplace_back(std::move(printer));
  }

  result->Success(EncodableValue(std::move(list)));
}

void PrintRaw(
    const EncodableMap& arguments,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto name_entry = arguments.find(EncodableValue("name"));
  const auto bytes_entry = arguments.find(EncodableValue("bytes"));
  if (name_entry == arguments.end() || bytes_entry == arguments.end()) {
    result->Error("invalid_arguments",
                  "Printer name and ticket data are required.");
    return;
  }

  const auto* printer_name = std::get_if<std::string>(&name_entry->second);
  const auto* bytes =
      std::get_if<std::vector<uint8_t>>(&bytes_entry->second);
  if (printer_name == nullptr || printer_name->empty() || bytes == nullptr ||
      bytes->empty() || bytes->size() > MAXDWORD) {
    result->Error("invalid_arguments",
                  "Printer name and non-empty ticket data are required.");
    return;
  }

  const std::wstring wide_printer_name = Utf8ToWide(*printer_name);
  if (wide_printer_name.empty()) {
    result->Error("invalid_printer_name", "The printer name is invalid.");
    return;
  }

  HANDLE printer_handle = nullptr;
  if (!OpenPrinterW(const_cast<LPWSTR>(wide_printer_name.c_str()),
                    &printer_handle, nullptr)) {
    const DWORD error_code = GetLastError();
    result->Error("printer_open_failed", WindowsErrorMessage(error_code));
    return;
  }

  DOC_INFO_1W document_info{};
  document_info.pDocName = const_cast<LPWSTR>(L"Admivida POS Ticket");
  document_info.pDatatype = const_cast<LPWSTR>(L"RAW");

  const DWORD job_id =
      StartDocPrinterW(printer_handle, 1,
                       reinterpret_cast<LPBYTE>(&document_info));
  if (job_id == 0) {
    const DWORD error_code = GetLastError();
    ClosePrinter(printer_handle);
    result->Error("printer_job_failed", WindowsErrorMessage(error_code));
    return;
  }

  bool success = StartPagePrinter(printer_handle) != 0;
  DWORD bytes_written = 0;
  DWORD print_error = success ? ERROR_SUCCESS : GetLastError();
  if (success) {
    const BOOL write_succeeded =
        WritePrinter(printer_handle, const_cast<uint8_t*>(bytes->data()),
                     static_cast<DWORD>(bytes->size()), &bytes_written);
    success = write_succeeded != 0 && bytes_written == bytes->size();
    if (!write_succeeded) {
      print_error = GetLastError();
    } else if (bytes_written != bytes->size()) {
      print_error = ERROR_WRITE_FAULT;
    }
    if (EndPagePrinter(printer_handle) == 0 && success) {
      success = false;
      print_error = GetLastError();
    }
  }
  if (!success && print_error == ERROR_SUCCESS) {
    print_error = ERROR_GEN_FAILURE;
  }

  const bool document_ended = EndDocPrinter(printer_handle) != 0;
  const DWORD end_error = document_ended ? ERROR_SUCCESS : GetLastError();
  ClosePrinter(printer_handle);

  if (!success) {
    result->Error("printer_write_failed", WindowsErrorMessage(print_error));
    return;
  }
  if (!document_ended) {
    result->Error("printer_job_finish_failed",
                  WindowsErrorMessage(end_error));
    return;
  }

  result->Success(EncodableValue(true));
}

}  // namespace

WindowsUsbPrinterChannel::WindowsUsbPrinterChannel(
    flutter::BinaryMessenger* messenger)
    : channel_(std::make_unique<flutter::MethodChannel<EncodableValue>>(
          messenger, "admivida/windows_usb_printer",
          &flutter::StandardMethodCodec::GetInstance())) {
  channel_->SetMethodCallHandler(
      [this](const auto& method_call, auto result) {
        HandleMethodCall(method_call, std::move(result));
      });
}

WindowsUsbPrinterChannel::~WindowsUsbPrinterChannel() {
  channel_->SetMethodCallHandler(nullptr);
}

void WindowsUsbPrinterChannel::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (method_call.method_name() == "listPrinters") {
    ListPrinters(std::move(result));
    return;
  }

  if (method_call.method_name() == "printRaw") {
    const auto* arguments = std::get_if<EncodableMap>(method_call.arguments());
    if (arguments == nullptr) {
      result->Error("invalid_arguments", "Printer arguments are required.");
      return;
    }
    PrintRaw(*arguments, std::move(result));
    return;
  }

  result->NotImplemented();
}
