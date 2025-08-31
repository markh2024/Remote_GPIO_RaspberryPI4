#include <pigpiod_if2.h>
#include <iostream>
#include <unistd.h> // for sleep()

int main() {
    // Replace with the IP of your Raspberry Pi running pigpiod
    const char* remotePi = "192.168.1.50";

    int pi = pigpio_start(remotePi, NULL); // connect to pigpiod daemon
    if (pi < 0) {
        std::cerr << "❌ Failed to connect to pigpiod at " << remotePi << std::endl;
        return 1;
    }

    std::cout << "✅ Connected to pigpiod at " << remotePi << std::endl;

    // Example: toggle GPIO17
    int gpio = 17;
    set_mode(pi, gpio, PI_OUTPUT);

    std::cout << "🔆 Turning GPIO " << gpio << " ON" << std::endl;
    gpio_write(pi, gpio, 1);
    sleep(1);

    std::cout << "🌑 Turning GPIO " << gpio << " OFF" << std::endl;
    gpio_write(pi, gpio, 0);

    pigpio_stop(pi);
    return 0;
}

