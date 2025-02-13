# Mneme Local Implementation Design Document

## Overview
Mneme is a personal memory capture system designed to run locally on an Arch Linux machine. It continuously listens for a hotword (e.g., "jì de"), upon which it records audio, transcribes it to text using Whisper, and stores the resulting text as a memory entry in a local file system for easy retrieval and management.

## Goals
- Always-on, low-impact background process.
- Hotword-activated recording to minimize resource usage and unnecessary recording.
- Local transcription using Whisper for privacy and control.
- Memory storage in a local, user-friendly format (e.g., Markdown/Obsidian-compatible).

## Hardware
- **CPU:** Intel i7-12700F
- **GPU:** AMD RX 6800/6800 XT (optional GPU acceleration via ROCm)
- **Microphone:** Any good-quality microphone supported by ALSA (e.g., USB condenser mic).

## Software Components
| Component                   | Tool                     |
|-----------------------------|---------------------------|
| Hotword Detection           | Porcupine (local)         |
| Audio Capture               | arecord (ALSA) or ffmpeg |
| Transcription               | Whisper (CPU/GPU)         |
| Memory Storage              | Markdown files / Obsidian |

## System Workflow
1. **Always-Listening Hotword Detection:**
   - Porcupine listens for the hotword (e.g., "jì de").
   - When detected, trigger audio recording.

2. **Audio Recording:**
   - Use `arecord` to record 10-30 seconds of audio (configurable).
   - Store the audio in a temporary WAV file.

3. **Transcription:**
   - Pass the WAV file to Whisper for transcription.
   - Use `whisper.cpp` for CPU or `whisper` with ROCm for GPU acceleration.

4. **Memory Storage:**
   - Append the transcription text to a daily Markdown file (e.g., `YYYY-MM-DD.md`).
   - Store files in a directory (e.g., `~/Mneme_Memories/`).

## Detailed Implementation
### Hotword Detection
```python
import pvporcupine
import pyaudio

porcupine = pvporcupine.create(keywords=["custom"], keyword_paths=["/path/to/jide.ppn"])
pa = pyaudio.PyAudio()
audio_stream = pa.open(rate=porcupine.sample_rate, channels=1, format=pyaudio.paInt16, input=True, frames_per_buffer=porcupine.frame_length)

while True:
    pcm = audio_stream.read(porcupine.frame_length)
    pcm = [int.from_bytes(pcm[i:i+2], 'little', signed=True) for i in range(0, len(pcm), 2)]
    if porcupine.process(pcm) >= 0:
        print("Hotword detected!")
        # Trigger audio recording
```

### Audio Recording
```bash
arecord -f cd -t wav -d 15 memory.wav
```

### Transcription
#### CPU (Whisper.cpp)
```bash
./main -m models/ggml-base.bin -f memory.wav --output-txt
```
#### GPU (ROCm Whisper)
```bash
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/rocm6.0
pip install openai-whisper
whisper memory.wav --model base --device cuda
```

### Memory Storage
```bash
cat memory.txt >> ~/Mneme_Memories/$(date +%F).md
```

## Directory Structure
```
~/Mneme_Memories/
    2025-02-13.md
    2025-02-14.md
```

## Performance Considerations
- Use **Porcupine** for low CPU impact during idle listening.
- Prefer **Whisper.cpp (Tiny/Base)** for fast CPU transcription.
- Enable **GPU acceleration (ROCm)** for faster transcription on larger models if needed.

## Future Enhancements
- Implement **Voice Activity Detection (VAD)** to **automatically stop recording** when silence is detected.
- Build **a local TUI or GUI** to **browse, search, and tag memories**.
- Explore **embedding metadata (timestamps, tags)** into memory files.
- Integrate with **Obsidian** for advanced note management.

## Summary
This design provides a robust, fully-local memory capture system leveraging hotword detection, audio transcription, and Markdown-based storage. It ensures privacy while enabling easy future expansion.

