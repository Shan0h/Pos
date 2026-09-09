import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pos/controller/selling_controller.dart';
import 'package:pos/service/get_it.dart';
import 'package:pos/utils/extension.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:usb_esc_printer_windows/usb_esc_printer_windows.dart' as usb_esc_printer_windows;
import 'package:esc_pos_utils/esc_pos_utils.dart';

class ModernPrintSetting extends StatefulWidget {
  const ModernPrintSetting({super.key});

  @override
  State<ModernPrintSetting> createState() => _ModernPrintSettingState();
}

class _ModernPrintSettingState extends State<ModernPrintSetting> {
  late TextEditingController _printNameController;
  List<BluetoothInfo> _printers = [];
  bool _isSearching = false;
  String _statusMessage = '';
  bool _isConnected = false;
  
  @override
  void initState() {
    super.initState();
    final currentPrintName = getIt.get<SellingController>().selectedPrint.value;
    _printNameController = TextEditingController(text: currentPrintName);
  }

  Future<void> _searchPrinters() async {
    setState(() {
      _isSearching = true;
      _statusMessage = 'Searching for printers...';
      _printers.clear();
    });

    try {
      if (Platform.isWindows) {
        setState(() {
          _statusMessage = 'On Windows, please type your USB Printer Name above and click Save Settings.';
        });
      } else {
        bool hasPermission = await PrintBluetoothThermal.isPermissionBluetoothGranted;
        if (!hasPermission) {
          setState(() {
            _statusMessage = 'Bluetooth permission not granted.';
          });
        } else {
          final list = await PrintBluetoothThermal.pairedBluetooths;
          setState(() {
            _printers = list;
            _statusMessage = 'Found ${list.length} paired Bluetooth printers.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error searching printers: $e';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _connectToPrinter(String macAddress) async {
    setState(() {
      _statusMessage = 'Connecting...';
    });
    
    try {
      bool result = false;
      if (Platform.isWindows) {
        setState(() {
          _statusMessage = 'On Windows, USB connection is handled automatically on print.';
        });
        return;
      } else {
        result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      }
      
      setState(() {
        _isConnected = result;
        _statusMessage = result ? 'Connected successfully!' : 'Failed to connect.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection error: $e';
      });
    }
  }

  Future<void> _testPrint() async {
    if (Platform.isWindows) {
      // Windows USB direct printing using text from input
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];
      bytes += generator.text("Test Print Success!", styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.feed(2);
      bytes += generator.cut();
      bytes += generator.drawer();
      
      String printerName = _printNameController.text;
      if (printerName.isEmpty) {
        setState(() => _statusMessage = 'Please enter Windows Printer Name first.');
        return;
      }
      
      setState(() => _statusMessage = 'Sending test print to $printerName...');
      final success = await usb_esc_printer_windows.sendPrintRequest(bytes, printerName);
      setState(() => _statusMessage = success == "Success" ? 'Print request sent!' : 'Print failed: $success');
      
    } else {
      if (!_isConnected) {
        setState(() => _statusMessage = 'Please connect to a Bluetooth printer first.');
        return;
      }
      
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];
      bytes += generator.text("Test Print Success!", styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.feed(2);
      bytes += generator.cut();
      
      final success = await PrintBluetoothThermal.writeBytes(bytes);
      setState(() => _statusMessage = success ? 'Print success!' : 'Print failed.');
    }
  }

  void _savePrintName() {
    getIt.get<SellingController>().selectedPrint.value = _printNameController.text;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printer setting saved!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A1A),
        foregroundColor: Colors.white,
        elevation: 0.5,
      ),
      backgroundColor: context.pageBackground,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 0,
                color: context.panelBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: context.borderColor)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary Printer Configuration',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appTextColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your printer name (Windows USB) or MAC Address (Bluetooth).',
                        style: TextStyle(color: context.secondaryTextColor),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _printNameController,
                              style: TextStyle(color: context.appTextColor),
                              decoration: InputDecoration(
                                labelText: 'Printer Name / MAC Address',
                                labelStyle: TextStyle(color: context.secondaryTextColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: context.mutedBackground,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5E3C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _savePrintName,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Actions Row
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    onPressed: _isSearching ? null : _searchPrinters,
                    icon: _isSearching 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.search),
                    label: const Text('Search Bluetooth Printers'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _testPrint,
                    icon: const Icon(Icons.print),
                    label: const Text('Run Test Print'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Status Message
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.mutedBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[300], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_statusMessage, style: TextStyle(color: context.appTextColor)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Printer List
              Text('Discovered Printers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appTextColor)),
              const SizedBox(height: 8),
              Expanded(
                child: _printers.isEmpty
                  ? Center(child: Text('No printers found. Click search.', style: TextStyle(color: context.secondaryTextColor)))
                  : ListView.builder(
                      itemCount: _printers.length,
                      itemBuilder: (context, index) {
                        final printer = _printers[index];
                        return Card(
                          elevation: 0,
                          color: context.panelBackground,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: context.borderColor)
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF8B5E3C),
                              child: Icon(Icons.bluetooth, color: Colors.white),
                            ),
                            title: Text(printer.name.isNotEmpty ? printer.name : 'Unknown Device', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(printer.macAdress),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5E3C),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                _printNameController.text = printer.macAdress;
                                _connectToPrinter(printer.macAdress);
                              },
                              child: const Text('Connect & Use'),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
