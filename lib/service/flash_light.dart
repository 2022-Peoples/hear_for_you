import 'dart:async';
import 'package:torch_light/torch_light.dart';

class FlashLight {
  static startFlashLight(cnt) {
    Timer timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (Timer timer) {
        cnt += 1;
        if (cnt == 10) {
          timer.cancel();
        }
        if (cnt % 2 == 0) {
          TorchLight.disableTorch();
        } else {
          TorchLight.enableTorch();
        }
      },
    );
  }
}
