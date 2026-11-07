/*
 * user_config_override.h — ZB-GW03 overrides (user side)
 *
 * Adapted from xsp1989/ZB-GW03_firmware's tasmota/README.md recipe (v14.5.0 era).
 * Everything is gated by -DFIRMWARE_EASYIOT, set by env:tasmota32-ZB-GW03-EN in
 * platformio_override.ini. FIRMWARE_EASYIOT is a recipe-local gate; Upstream
 * does not interpret it anywhere.
 *
 * Copied into the Upstream checkout's tasmota/ directory by tasmota/build.sh.
 */

#ifdef FIRMWARE_EASYIOT
  //#undef  SERIAL_LOG_LEVEL
  //#define SERIAL_LOG_LEVEL LOG_LEVEL_NONE
  //mDNS
  #define USE_DISCOVERY                            // Enable mDNS for the following services (+8k code or +23.5k code with core 2_5_x, +0.3k mem)
  #undef MDNS_ENABLED
  #define MDNS_ENABLED          true              // mDNS enabled by default
  #undef  MQTT_HOST_DISCOVERY                    // Find MQTT host server (overrides MQTT_HOST if found)


//  #define MY_LANGUAGE            zh_CN           // Chinese (Simplified) in China
  #undef MODULE
  #define MODULE USER_MODULE
  #undef FALLBACK_MODULE 
  #define FALLBACK_MODULE USER_MODULE
  #define USER_TEMPLATE "{\"NAME\":\"ZB-GW03\",\"GPIO\":[0,0,3552,0,3584,0,0,0,5793,5792,320,544,5536,0,5600,0,0,0,0,5568,0,0,0,0,0,0,0,0,608,640,32,0,0,0,0,0],\"FLAG\":0,\"BASE\":1}"  // [Template] Set JSON template

  #undef LIGHT_MODE
  #define LIGHT_MODE false
  #undef USE_DOMOTICZ

  #undef OTA_URL
  #define OTA_URL ""

  #undef WEB_PASSWORD
  #define WEB_PASSWORD ""

//  #undef WEB_PORT
//  #define WEB_PORT      8888

  #undef OTA_URL
  #define OTA_URL                ""

#undef APP_TIMEZONE
#define APP_TIMEZONE 8
#undef ROTARY_V1             // Add support for Rotary Encoder as used in MI Desk Lamp (+0k8 code)
#undef ROTARY_MAX_STEPS      // Rotary step boundary
#undef USE_SONOFF_RF         // Add support for Sonoff Rf Bridge (+3k2 code)
#undef USE_RF_FLASH          // Add support for flashing the EFM8BB1 chip on the Sonoff RF Bridge. C2CK must be connected to GPIO4, C2D to GPIO5 on the PCB (+2k7 code)
#undef USE_SONOFF_SC         // Add support for Sonoff Sc (+1k1 code)
#undef USE_TUYA_MCU          // Add support for Tuya Serial MCU
#undef TUYA_DIMMER_ID        // Default dimmer Id
#undef USE_TUYA_TIME         // Add support for Set Time in Tuya MCU
#undef USE_ARMTRONIX_DIMMERS // Add support for Armtronix Dimmers (+1k4 code)
#undef USE_PS_16_DZ          // Add support for PS-16-DZ Dimmer (+2k code)
#undef USE_SONOFF_IFAN       // Add support for Sonoff iFan02 and iFan03 (+2k code)
#undef USE_BUZZER            // Add support for a buzzer (+0k6 code)
#undef USE_ARILUX_RF         // Add support for Arilux RF remote controller (+0k8 code, 252 iram (non 2.3.0))
#undef USE_SHUTTER           // Add Shutter support for up to 4 shutter with different motortypes (+11k code)
#undef USE_DEEPSLEEP         // Add support for deepsleep (+1k code)
#undef USE_EXS_DIMMER        // Add support for ES-Store Wi-Fi Dimmer (+1k5 code)
#undef EXS_MCU_CMNDS                          // Add command to send MCU commands (+0k8 code)
#undef USE_HOTPLUG                              // Add support for sensor HotPlug
#undef USE_DEVICE_GROUPS                        // Add support for device groups (+5k5 code)
#undef DEVICE_GROUPS_ADDRESS // Device groups multicast address
#undef DEVICE_GROUPS_PORT                   // Device groups multicast port
#undef USE_DEVICE_GROUPS_SEND                   // Add support for the DevGroupSend command (+0k6 code)
#undef USE_PWM_DIMMER                           // Add support for MJ-SD01/acenx/NTONPOWER PWM dimmers (+2k3 code, DGR=0k7)
#undef USE_PWM_DIMMER_REMOTE                    // Add support for remote switches to PWM Dimmer (requires USE_DEVICE_GROUPS) (+0k6 code)
#undef USE_KEELOQ                               // Add support for Jarolift rollers by Keeloq algorithm (+4k5 code)
#undef USE_SONOFF_D1     // Add support for Sonoff D1 Dimmer (+0k7 code)
#undef USE_SHELLY_DIMMER // Add support for Shelly Dimmer (+3k code)
#undef SHELLY_CMDS       // Add command to send co-processor commands (+0k3 code)
#undef SHELLY_FW_UPGRADE // Add firmware upgrade option for co-processor (+3k4 code)
#undef SHELLY_VOLTAGE_MON                     // Add support for reading voltage and current measurment (-0k0 code)
//#undef USE_AUTOCONF
#undef USE_BERRY

  // -- Optional light modules ----------------------
#undef USE_LIGHT                         // Add support for light control
#undef USE_WS2812                        // WS2812 Led string using library NeoPixelBus (+5k code, +1k mem, 232 iram) - Disable by //
                                          //  #define USE_WS2812_DMA                         // ESP8266 only, DMA supports only GPIO03 (= Serial RXD) (+1k mem). When USE_WS2812_DMA is enabled expect Exceptions on Pow
//#define USE_WS2812_RMT 0                  // ESP32 only, hardware RMT support (default). Specify the RMT channel 0..7. This should be preferred to software bit bang.
                                          //  #define USE_WS2812_I2S  0                      // ESP32 only, hardware I2S support. Specify the I2S channel 0..2. This is exclusive from RMT. By default, prefer RMT support
                                          //  #define USE_WS2812_INVERTED                    // Use inverted data signal
#undef USE_WS2812_HARDWARE                // Hardware type (NEO_HW_WS2812, NEO_HW_WS2812X, NEO_HW_WS2813, NEO_HW_SK6812, NEO_HW_LC8812, NEO_HW_APA106, NEO_HW_P9813)
#undef USE_WS2812_CTYPE                   // Color type (NEO_RGB, NEO_GRB, NEO_BRG, NEO_RBG, NEO_RGBW, NEO_GRBW)
#undef USE_MY92X1                        // Add support for MY92X1 RGBCW led controller as used in Sonoff B1, Ailight and Lohas
#undef USE_SM16716                       // Add support for SM16716 RGB LED controller (+0k7 code)
#undef USE_SM2135                        // Add support for SM2135 RGBCW led control as used in Action LSC (+0k6 code)
#undef USE_SM2335                        // Add support for SM2335 RGBCW led control as used in SwitchBot Color Bulb (+0k8 code)
#undef USE_BP5758D                       // Add support for BP5758D RGBCW led control as used in some Tuya lightbulbs (+0k8 code)
#undef USE_SONOFF_L1                     // Add support for Sonoff L1 led control
#undef USE_ELECTRIQ_MOODL                // Add support for ElectriQ iQ-wifiMOODL RGBW LED controller (+0k3 code)
#undef USE_LIGHT_PALETTE                 // Add support for color palette (+0k7 code)
#undef USE_LIGHT_VIRTUAL_CT              // Add support for Virtual White Color Temperature (+1.1k code)
#undef USE_DGR_LIGHT_SEQUENCE            // Add support for device group light sequencing (requires USE_DEVICE_GROUPS) (+0k2 code)
#undef USE_LSC_MCSL                             // Add support for GPE Multi color smart light as sold by Action in the Netherlands (+1k1 code)

#define USE_ZIGBEE
#undef USE_ZIGBEE_ZNP
#define USE_ZIGBEE_EZSP
#define USE_UFILESYS
#define USE_ZIGBEE_EEPROM // T24C512A
#define USE_TCP_BRIDGE
#undef USE_ZIGBEE_CHANNEL
#define USE_ZIGBEE_CHANNEL 11 // (11-26)

#define USE_ETHERNET
#undef ETH_TYPE
#define ETH_TYPE 0 // ETH_PHY_LAN8720
#undef ETH_CLKMODE
#define ETH_CLKMODE 3 // ETH_CLOCK_GPIO17_OUT
#undef ETH_ADDRESS
#define ETH_ADDRESS 1 // PHY1
#endif
