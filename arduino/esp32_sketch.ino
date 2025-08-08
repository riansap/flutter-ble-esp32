// =======================================================================
// A. HEADER & DESKRIPSI PROYEK
// =======================================================================
/**
 * @file       ESP32_BLE_Server_RNT_Style.ino
 * @author     Rian Saputra (diadaptasi dari RNT & C++ BLE examples)
 * @date       5 Agustus 2025
 * @brief      BLE Server untuk dikontrol oleh Flutter - kontrol LED + indikator standby
 */


// =======================================================================
// B. KONFIGURASI PENGGUNA
// =======================================================================
#define DEVICE_NAME "ESP32 Audioteq Control"
#define LED_PIN 13
#define LED_BUILTIN 2

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"


// =======================================================================
// C. INCLUDE LIBRARIES
// =======================================================================
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>


// =======================================================================
// D. VARIABEL GLOBAL
// =======================================================================
bool deviceConnected = false;


// =======================================================================
// E. CALLBACK DEFINITIONS
// =======================================================================
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Perangkat terhubung!");

      // Matikan LED standby
      digitalWrite(LED_BUILTIN, LOW);
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Koneksi terputus, mulai advertising lagi...");

      // Nyalakan LED
      digitalWrite(LED_BUILTIN, HIGH);

      BLEDevice::startAdvertising();
    }
};

class MyCharacteristicCallbacks: public BLECharacteristicCallbacks {
   void onWrite(BLECharacteristic *pCharacteristic) {
    uint8_t* data = pCharacteristic->getData();
    size_t length = pCharacteristic->getValue().length();

    if (length > 0) {
      Serial.print("Data diterima dari Flutter (byte): ");
      Serial.println(data[0]);

      if (data[0] == 1) {
        Serial.println("Byte 1 -> Menyalakan LED");
        digitalWrite(LED_PIN, HIGH);
      } else if (data[0] == 0) {
        Serial.println("Byte 0 -> Mematikan LED");
        digitalWrite(LED_PIN, LOW);
      } else {
        Serial.print("Byte tidak dikenali: ");
        Serial.println((int)data[0]);
      }
    }
  }
};


// =======================================================================
// F. SETUP
// =======================================================================
void setup() {
  Serial.begin(115200);
  Serial.println("===================================");
  Serial.println("  ESP32 Custom BLE Server - Start  ");
  Serial.println("===================================");

  // Konfigurasi pin
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH); // LED menyala sekali saat belum terkoneksi

  // Test LED hardware
  Serial.println("Testing LED hardware...");
  digitalWrite(LED_PIN, HIGH);
  delay(1000);
  digitalWrite(LED_PIN, LOW);
  delay(1000);
  Serial.println("LED test complete");
  digitalWrite(LED_BUILTIN, HIGH);


  // BLE setup
  Serial.println("1. Menginisialisasi BLE...");
  BLEDevice::init(DEVICE_NAME);

  Serial.println("2. Membuat server...");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  Serial.println("3. Membuat service...");
  BLEService *pService = pServer->createService(SERVICE_UUID);

  Serial.println("4. Membuat characteristic...");
  BLECharacteristic *pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE
  );

  pCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
  pCharacteristic->setValue("0"); // Nilai awal = LED mati

  Serial.println("5. Memulai service...");
  pService->start();

  Serial.println("6. Mulai advertising...");
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  BLEDevice::startAdvertising();

  Serial.println("\n>>> ESP32 siap dihubungkan oleh Flutter <<<");
}


// =======================================================================
// G. LOOP
// =======================================================================
void loop() {
  delay(2000);
}
