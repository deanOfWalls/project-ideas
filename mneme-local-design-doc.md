# Mneme Local Implementation Design Document

## Overview
Mneme is a personal memory capture system designed to run locally on an Arch Linux machine. It continuously listens for a hotword (e.g., "jì de"), upon which it records audio, transcribes it to text using Whisper, and stores the resulting text as a memory entry in a local file system for easy retrieval and management.

## Goals
- Always-on, low-impact background process.
- Hotword-activated recording to minimize resource usage and unnecessary recording.
- Voice Activity Detection (VAD) to automatically stop recording when silence is detected.
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
| Audio Capture + VAD         | sox (with silence detection) or ffmpeg |
| Transcription               | Whisper (CPU/GPU)         |
| Memory Storage              | Markdown files / Obsidian |
| Automation + Sync           | Git + GitHub Actions      |

## System Workflow
1. **Always-Listening Hotword Detection:**
   - Porcupine listens for the hotword (e.g., "jì de").
   - When detected, trigger audio recording.

2. **Audio Recording with VAD:**
   - Use `sox` or `ffmpeg` with silence detection to record audio until silence is detected.
   - Store the audio in a temporary WAV file.

3. **Transcription:**
   - Pass the WAV file to Whisper for transcription.
   - Use `whisper.cpp` for CPU or `whisper` with ROCm for GPU acceleration.

4. **Memory Storage:**
   - Append the transcription text to a timestamped Markdown file (e.g., `YYYY-MM-DD_HH-MM-SS.md`).
   - Store files in a directory (e.g., `~/Mneme_Memories/`).

5. **Git Sync + Index Update:**
   - Push new memory files to a GitHub repository.
   - Trigger a GitHub Actions workflow to update an `index.html` page listing all `.md` files.

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

### Audio Recording with VAD
```bash
sox -t alsa default memory.wav silence 1 0.1 1% 1 1.0 1%
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
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
mv memory.txt ~/Mneme_Memories/"$DATE.md"
```

### Git Sync + Index Update
Local push script example:
```bash
cd ~/Mneme_Memories
if [[ -n $(git status --porcelain) ]]; then
    git add *.md
    git commit -m "Add new memory files"
fi
if [[ -n $(git log origin/main..HEAD) ]]; then
    git push origin main
fi
```
GitHub Actions workflow example:
```yaml
name: Build Index
on:
  push:
    branches:
      - main
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Generate index.html
        run: |
          echo "<html><body>" > index.html
          for file in *.md; do
            echo "<p><a href=\"$file\">$file</a></p>" >> index.html
          done
          echo "</body></html>" >> index.html
      - name: Commit and Push index.html
        run: |
          git config --global user.name 'github-actions'
          git config --global user.email 'actions@github.com'
          git add index.html
          git commit -m "Update index.html"
          git push
```

## Directory Structure
```
~/Mneme_Memories/
    2025-02-13_12-45-32.md
    2025-02-14_08-22-11.md
    index.html
```

## Performance Considerations
- Use **Porcupine** for low CPU impact during idle listening.
- Prefer **Whisper.cpp (Tiny/Base)** for fast CPU transcription.
- Enable **GPU acceleration (ROCm)** for faster transcription on larger models if needed.

## Future Enhancements
- Implement **a local TUI or GUI** to **browse, search, and tag memories**.
- Explore **embedding metadata (timestamps, tags)** into memory files.
- Integrate with **Obsidian** for advanced note management.

## Summary
This design provides a robust, fully-local memory capture system leveraging hotword detection, audio transcription, and Markdown-based storage. It ensures privacy while enabling easy future expansion.

