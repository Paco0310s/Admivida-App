# Admivida

Aplicación para administrar negocios, productos y ventas.

## Impresión de tickets

### Windows por USB

1. Conecta la impresora térmica por USB e instala en Windows su controlador.
2. Comprueba en la configuración de impresoras de Windows que el puerto asignado sea USB.
3. Selecciona la impresora desde Admivida. Windows envía el ticket en modo RAW; el controlador y la impresora deben aceptar comandos ESC/POS.
4. Para abrir el cajón, debe estar conectado a la impresora y ser compatible con el comando ESC/POS de apertura (pines 2 y 5).

Windows no ofrece impresión Bluetooth desde Admivida actualmente.

### Android por USB OTG o Bluetooth

- USB: conecta una impresora compatible mediante un adaptador OTG.
- Bluetooth: empareja primero la impresora clásica desde los ajustes de Android y concede el permiso de ubicación cuando se solicite para descubrirla.

La impresión y apertura del cajón dependen de que el modelo de impresora admita ESC/POS y el comando de cajón. Conviene validar ambos con el hardware concreto antes de operar en producción.
