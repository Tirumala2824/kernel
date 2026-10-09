"""Off-device training pipeline for the Kernel acoustic screening model.

Nothing in this package ships in the APK. Only the exported `.tflite` and
`.properties` in `model-training/dist/` are copied into the app's assets by
the lead.
"""

import os
import sys

if os.name == "nt":
    # TensorFlow needs msvcp140.dll / msvcp140_1.dll. The `msvc-runtime` wheel
    # installs them into the venv; register those dirs so Windows' safe DLL
    # search (which ignores PATH since Python 3.8) finds them before TF loads.
    for _d in (sys.prefix, os.path.join(sys.prefix, "Scripts")):
        if os.path.isfile(os.path.join(_d, "msvcp140_1.dll")):
            os.add_dll_directory(_d)
