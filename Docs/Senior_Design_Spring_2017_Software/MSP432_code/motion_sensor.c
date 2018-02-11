#include "driverlib.h"

void motion_sensor_init() {
    /* Configuring P3.0 as an input and enabling interrupts */
    MAP_GPIO_setAsInputPinWithPullUpResistor(GPIO_PORT_P3, GPIO_PIN0);
    MAP_GPIO_clearInterruptFlag(GPIO_PORT_P3, GPIO_PIN0);
    MAP_GPIO_enableInterrupt(GPIO_PORT_P3, GPIO_PIN0);
    MAP_Interrupt_enableInterrupt(INT_PORT3);
}

void motion_sensor_disable() {
    MAP_GPIO_clearInterruptFlag(GPIO_PORT_P3, GPIO_PIN0);
    MAP_GPIO_disableInterrupt(GPIO_PORT_P3, GPIO_PIN0);
    MAP_Interrupt_disableInterrupt(INT_PORT3);
}

void motion_sensor_enable() {
    MAP_GPIO_clearInterruptFlag(GPIO_PORT_P3, GPIO_PIN0);
    MAP_GPIO_enableInterrupt(GPIO_PORT_P3, GPIO_PIN0);
    MAP_Interrupt_enableInterrupt(INT_PORT3);
}
