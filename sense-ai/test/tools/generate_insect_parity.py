"""Reproducible synthetic NUMERICAL fixtures; not insect recordings/accuracy evidence.
Run with inspected pinned upstream checkout and numpy/scipy/torch/h5py/tensorflow.
Never unpickles model.pt. Outputs stay under native tests, never app assets.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

parser = argparse.ArgumentParser()
parser.add_argument('upstream', type=Path)
parser.add_argument('output', type=Path)
a = parser.parse_args()
checks = {
 'src/audio.py': 'df78b3a6c79840569ac5c7fb073ac390c28de138cf493ba618073931f5975e85',
 'src/inference.py': 'f0fc307a7991c0ee666a8c8267e8b32be28dce50a250772f03d273ad5180fc01',
 'src/model.py': '45afb6821e15a503434d3d6c2a50ad619dce7c17f0966f1862dd6a209fe13a3f',
 'src/__init__.py': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
 'model.h5': '6a31529c5c7e27767246b99617c8f54ca36165fcb172814a9e50a8e168fc0ca7',
 'model.tflite': '55ad541b87d1ae0bae5a71c7ec9091fc40617051f479ac3f12996bacda6f597e',
 'config.json': '52d8010c97b0d01a87f4f32a4e2294e6a03d1ff769352568a200e2404c618f6d',
 'labels.json': 'c71894abb1c95dc877b59d48c7028cb3e9aa898d8352113ee280240b92b33748',
}
for path, digest in checks.items():
    assert hashlib.sha256((a.upstream/path).read_bytes()).hexdigest() == digest, path
sys.path.insert(0, str(a.upstream.resolve()))
import numpy as np
import scipy
from scipy.io import wavfile
import torch
import tensorflow as tf
from src.audio import read_audio, resample, crop_offsets, logmel
from src.inference import load_model, predict_wav
net, _, _ = load_model(a.upstream)
interpreter = tf.lite.Interpreter(model_path=str(a.upstream/'model.tflite'), num_threads=1)
interpreter.allocate_tensors()
input_detail = interpreter.get_input_details()[0]
output_detail = interpreter.get_output_details()[0]
print('INPUT', input_detail)
print('OUTPUT', output_detail)
assert input_detail['shape'].tolist() == [1,1,64,201]
assert output_detail['shape'].tolist() == [1,32]
a.output.mkdir(parents=True, exist_ok=True)
report = {'notice':'SYNTHETIC numerical fixtures, not species validation',
          'revision':'001425d7fab4b44af5cc571174410f1c78552d0e',
          'versions':{'numpy':np.__version__, 'scipy':scipy.__version__, 'torch':torch.__version__, 'tensorflow':tf.__version__},
          'cases':{}}
for name, sr, duration, stereo in [('mono16',16000,2,False), ('short16',16000,.3,False), ('long16',16000,4.2501875,False), ('stereo44',44100,2.125,True), ('mono48',48000,2,False)]:
    t = np.arange(int(sr*duration))/sr
    rng = np.random.default_rng(321)
    y = .12*np.sin(2*np.pi*(1300*t+170*t*t))*(.55+.45*np.sin(2*np.pi*7*t)) + .03*rng.standard_normal(len(t))
    if stereo: y = np.stack([y,.11*np.sin(2*np.pi*3700*t)],axis=1)
    wav = a.output/(name+'.wav')
    wavfile.write(wav, sr, np.round(y*32767).astype(np.int16))
    sr, mono = read_audio(wav)
    mono.astype('<f4').tofile(a.output/(name+'.mono.f32'))
    y16 = resample(mono,sr)
    y16.astype('<f4').tofile(a.output/(name+'.resampled.f32'))
    offsets=crop_offsets(len(y16),5)
    features=np.stack([logmel(y16,16000,o) for o in offsets])
    features.astype('<f4').tofile(a.output/(name+'.features.f32'))
    logits=[]
    for feature in features:
        interpreter.set_tensor(input_detail['index'],feature[None])
        interpreter.invoke()
        logits.append(interpreter.get_tensor(output_detail['index'])[0])
    logits=np.stack(logits)
    with torch.no_grad(): pt=net(torch.from_numpy(features)).numpy()
    diff=float(np.max(np.abs(pt-logits)))
    assert diff < 1e-4, (name,diff)
    logits.astype('<f4').tofile(a.output/(name+'.logits.f32'))
    result=predict_wav(wav,a.upstream)
    probs=torch.softmax(torch.from_numpy(pt),dim=1).mean(dim=0).numpy()
    probs.astype('<f4').tofile(a.output/(name+'.probs.f32'))
    report['cases'][name]={'rate':sr,'samples':len(mono),'offsets':offsets,'max_logit_error':diff,'upstream':result}
    print(name,'crops',len(offsets),'PT-TFLite max_abs_logits',diff, flush=True)
(a.output/'parity.json').write_text(json.dumps(report,indent=2))
print('PASS: all real TFLite logits match safe H5 PyTorch on synthetic test inputs')
