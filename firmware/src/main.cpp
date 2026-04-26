// kc_smart_lamp firmware — ESP32-S3 + NimBLE + FastLED.
//
// Architecture: one BLE service, one 5-byte characteristic (LAMP_STATE).
// Each client write atomically updates power/RGB/brightness; characteristic
// remains readable for future status query (see docs/gatt_spec.md).

#include <Arduino.h>
#include <NimBLEDevice.h>
#include <FastLED.h>

#define DEVICE_NAME       "kc_smart_lamp"
#define SERVICE_UUID      "2f421b7d-41dd-4de6-a19a-1194b4d04361"
#define LAMP_STATE_UUID   "2f421b7d-41dd-4de6-a19a-a2a6dae023f9"

#ifndef LAMP_LED_PIN
#define LAMP_LED_PIN 48
#endif

#define NUM_LEDS          1

struct LampState {
    bool    power;
    uint8_t r, g, b;
    uint8_t brightness;  // 0-100
};

static LampState g_state = { false, 255, 255, 255, 50 };
static CRGB      g_leds[NUM_LEDS];
static NimBLECharacteristic* g_lamp_char = nullptr;

static void apply_state() {
    if (g_state.power) {
        uint8_t scaled = (uint16_t)g_state.brightness * 255 / 100;
        FastLED.setBrightness(scaled);
        g_leds[0] = CRGB(g_state.r, g_state.g, g_state.b);
    } else {
        // Off: clear LED but retain RGB/brightness in g_state for next power-on.
        FastLED.setBrightness(0);
        g_leds[0] = CRGB::Black;
    }
    FastLED.show();
}

static void publish_state_to_characteristic() {
    if (g_lamp_char == nullptr) return;
    uint8_t bytes[5] = {
        (uint8_t)(g_state.power ? 1 : 0),
        g_state.r, g_state.g, g_state.b,
        g_state.brightness,
    };
    g_lamp_char->setValue(bytes, sizeof(bytes));
}

class LampStateCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* ch) override {
        std::string val = ch->getValue();
        if (val.length() != 5) {
            Serial.printf("[ble] reject write: expected 5 bytes, got %u\n",
                          (unsigned)val.length());
            // Re-publish current state so client can read what's actually there.
            publish_state_to_characteristic();
            return;
        }

        g_state.power      = val[0] != 0;
        g_state.r          = (uint8_t)val[1];
        g_state.g          = (uint8_t)val[2];
        g_state.b          = (uint8_t)val[3];
        uint8_t bright     = (uint8_t)val[4];
        if (bright > 100) bright = 100;
        g_state.brightness = bright;

        Serial.printf("[ble] state: power=%d rgb=(%u,%u,%u) brightness=%u%%\n",
                      g_state.power ? 1 : 0,
                      g_state.r, g_state.g, g_state.b, g_state.brightness);

        apply_state();
        // Re-publish so the read value reflects clamped brightness.
        publish_state_to_characteristic();
    }
};

static void boot_self_test() {
    // Brief RGB sweep so we can confirm GPIO + FastLED + on-board LED chain
    // is correct *before* any BLE traffic. If this doesn't show, the LED_PIN
    // is wrong for this clone board (try 38 or 47, see dev_setup.md).
    FastLED.setBrightness(64);
    g_leds[0] = CRGB::Red;   FastLED.show(); delay(300);
    g_leds[0] = CRGB::Green; FastLED.show(); delay(300);
    g_leds[0] = CRGB::Blue;  FastLED.show(); delay(300);
    g_leds[0] = CRGB::Black; FastLED.show();
    Serial.println("[boot] self-test ok (R/G/B/off shown on on-board LED)");
}

void setup() {
    Serial.begin(115200);
    delay(500);
    Serial.println("\n[boot] kc_smart_lamp v0.1.0");
    Serial.printf("[boot] LED_PIN=%d, NUM_LEDS=%d\n", LAMP_LED_PIN, NUM_LEDS);

    FastLED.addLeds<WS2812, LAMP_LED_PIN, GRB>(g_leds, NUM_LEDS);
    boot_self_test();

    NimBLEDevice::init(DEVICE_NAME);
    NimBLEServer*   server  = NimBLEDevice::createServer();
    NimBLEService*  service = server->createService(SERVICE_UUID);

    g_lamp_char = service->createCharacteristic(
        LAMP_STATE_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE
    );
    g_lamp_char->setCallbacks(new LampStateCallbacks());
    publish_state_to_characteristic();

    service->start();

    NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
    adv->addServiceUUID(SERVICE_UUID);
    adv->start();

    Serial.printf("[ble] advertising as '%s'\n", DEVICE_NAME);
    Serial.printf("[ble] service UUID:    %s\n", SERVICE_UUID);
    Serial.printf("[ble] LAMP_STATE UUID: %s\n", LAMP_STATE_UUID);
    Serial.println("[ble] ready — waiting for client write");
}

void loop() {
    delay(1000);
}
