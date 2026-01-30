#!/usr/bin/env python3
"""
Video Converter GUI for Tom's Peripherals GPU
Modern PySide6 UI
"""

import sys
import os
import struct
import threading
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QPushButton, QLineEdit, QProgressBar, QFileDialog,
    QMessageBox, QFrame, QSpinBox, QGroupBox, QSizePolicy
)
from PySide6.QtCore import Qt, Signal, QObject, QSize
from PySide6.QtGui import QFont, QIcon, QPalette, QColor, QDragEnterEvent, QDropEvent


STYLESHEET = """
QMainWindow {
    background-color: #1a1a2e;
}

QWidget {
    color: #eee;
    font-family: 'Segoe UI', 'SF Pro Display', 'Helvetica Neue', sans-serif;
}

QGroupBox {
    background-color: #16213e;
    border: 1px solid #0f3460;
    border-radius: 12px;
    margin-top: 12px;
    padding: 20px 15px 15px 15px;
    font-weight: bold;
    font-size: 13px;
}

QGroupBox::title {
    subcontrol-origin: margin;
    left: 20px;
    padding: 0 10px;
    color: #888;
    font-size: 12px;
    font-weight: normal;
}

QLineEdit {
    background-color: #0f3460;
    border: 2px solid #1a1a4e;
    border-radius: 8px;
    padding: 12px 15px;
    font-size: 14px;
    color: #fff;
    selection-background-color: #e94560;
}

QLineEdit:focus {
    border: 2px solid #e94560;
}

QLineEdit:disabled {
    background-color: #1a1a3e;
    color: #666;
}

QPushButton {
    background-color: #e94560;
    border: none;
    border-radius: 8px;
    padding: 12px 24px;
    font-size: 14px;
    font-weight: bold;
    color: white;
}

QPushButton:hover {
    background-color: #ff6b6b;
}

QPushButton:pressed {
    background-color: #c73e54;
}

QPushButton:disabled {
    background-color: #444;
    color: #888;
}

QPushButton#secondaryBtn {
    background-color: #0f3460;
}

QPushButton#secondaryBtn:hover {
    background-color: #1a4a7a;
}

QPushButton#presetLow {
    background-color: #c0392b;
}
QPushButton#presetLow:hover {
    background-color: #e74c3c;
}

QPushButton#presetMed {
    background-color: #d35400;
}
QPushButton#presetMed:hover {
    background-color: #e67e22;
}

QPushButton#presetHigh {
    background-color: #27ae60;
}
QPushButton#presetHigh:hover {
    background-color: #2ecc71;
}

QPushButton#presetMax {
    background-color: #2980b9;
}
QPushButton#presetMax:hover {
    background-color: #3498db;
}

QProgressBar {
    background-color: #0f3460;
    border: none;
    border-radius: 10px;
    height: 20px;
    text-align: center;
    font-weight: bold;
}

QProgressBar::chunk {
    background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
        stop:0 #e94560, stop:1 #ff6b6b);
    border-radius: 10px;
}

QSpinBox {
    background-color: #0f3460;
    border: 2px solid #1a1a4e;
    border-radius: 8px;
    padding: 8px 12px;
    font-size: 14px;
    color: #fff;
}

QSpinBox:focus {
    border: 2px solid #e94560;
}

QSpinBox::up-button, QSpinBox::down-button {
    background-color: #1a4a7a;
    border: none;
    width: 20px;
}

QSpinBox::up-button:hover, QSpinBox::down-button:hover {
    background-color: #e94560;
}

QLabel#title {
    font-size: 32px;
    font-weight: bold;
    color: #fff;
}

QLabel#subtitle {
    font-size: 14px;
    color: #888;
}

QLabel#status {
    font-size: 13px;
    color: #aaa;
}

QLabel#dropZone {
    background-color: #0f3460;
    border: 3px dashed #1a4a7a;
    border-radius: 12px;
    padding: 40px;
    font-size: 16px;
    color: #666;
}

QLabel#dropZone:hover {
    border-color: #e94560;
    color: #888;
}
"""


class WorkerSignals(QObject):
    progress = Signal(int, str)
    finished = Signal(str)
    error = Signal(str)


class VideoConverterWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("CC Video Converter")
        self.setMinimumSize(550, 650)
        self.resize(650, 750)
        self.setAcceptDrops(True)

        self.signals = WorkerSignals()
        self.signals.progress.connect(self.update_progress)
        self.signals.finished.connect(self.conversion_finished)
        self.signals.error.connect(self.conversion_error)

        self.converting = False
        self.setup_ui()

    def setup_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setContentsMargins(30, 30, 30, 30)
        layout.setSpacing(15)

        # Header
        title = QLabel("Video Converter")
        title.setObjectName("title")
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)

        subtitle = QLabel("Convert videos for Tom's Peripherals GPU")
        subtitle.setObjectName("subtitle")
        subtitle.setAlignment(Qt.AlignCenter)
        layout.addWidget(subtitle)

        layout.addSpacing(10)

        # Drop Zone / Input
        input_group = QGroupBox("INPUT VIDEO")
        input_group.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        input_layout = QVBoxLayout(input_group)

        self.drop_label = QLabel("Drag & drop a video file here\nor click Browse")
        self.drop_label.setObjectName("dropZone")
        self.drop_label.setAlignment(Qt.AlignCenter)
        self.drop_label.setMinimumHeight(80)
        self.drop_label.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        input_layout.addWidget(self.drop_label, 1)

        input_row = QHBoxLayout()
        self.input_edit = QLineEdit()
        self.input_edit.setPlaceholderText("No file selected...")
        input_row.addWidget(self.input_edit)

        browse_btn = QPushButton("Browse")
        browse_btn.setObjectName("secondaryBtn")
        browse_btn.setMinimumWidth(100)
        browse_btn.clicked.connect(self.browse_input)
        input_row.addWidget(browse_btn)
        input_layout.addLayout(input_row)

        layout.addWidget(input_group, 2)

        # Output
        output_group = QGroupBox("OUTPUT FILE")
        output_layout = QHBoxLayout(output_group)

        self.output_edit = QLineEdit("video.raw")
        output_layout.addWidget(self.output_edit)

        save_btn = QPushButton("Save As")
        save_btn.setObjectName("secondaryBtn")
        save_btn.setMinimumWidth(100)
        save_btn.clicked.connect(self.browse_output)
        output_layout.addWidget(save_btn)

        layout.addWidget(output_group)

        # Resolution
        res_group = QGroupBox("RESOLUTION")
        res_group.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        res_layout = QVBoxLayout(res_group)

        # Presets
        presets_layout = QHBoxLayout()
        presets_layout.setSpacing(10)

        presets = [
            ("Low\n64×36", 64, 36, "presetLow"),
            ("Medium\n128×72", 128, 72, "presetMed"),
            ("High\n256×144", 256, 144, "presetHigh"),
            ("Max\n384×216", 384, 216, "presetMax"),
        ]

        for text, w, h, obj_name in presets:
            btn = QPushButton(text)
            btn.setObjectName(obj_name)
            btn.setMinimumHeight(55)
            btn.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
            btn.clicked.connect(lambda checked, w=w, h=h: self.set_resolution(w, h))
            presets_layout.addWidget(btn)

        res_layout.addLayout(presets_layout)

        # Custom
        custom_layout = QHBoxLayout()
        custom_layout.setSpacing(15)

        custom_layout.addWidget(QLabel("Custom:"))

        self.width_spin = QSpinBox()
        self.width_spin.setRange(16, 1920)
        self.width_spin.setValue(256)
        self.width_spin.setFixedWidth(90)
        custom_layout.addWidget(self.width_spin)

        custom_layout.addWidget(QLabel("×"))

        self.height_spin = QSpinBox()
        self.height_spin.setRange(16, 1080)
        self.height_spin.setValue(144)
        self.height_spin.setFixedWidth(90)
        custom_layout.addWidget(self.height_spin)

        custom_layout.addStretch()

        custom_layout.addWidget(QLabel("Max Frames:"))

        self.frames_spin = QSpinBox()
        self.frames_spin.setRange(0, 10000)
        self.frames_spin.setValue(0)
        self.frames_spin.setSpecialValueText("All")
        self.frames_spin.setFixedWidth(90)
        custom_layout.addWidget(self.frames_spin)

        res_layout.addLayout(custom_layout)
        layout.addWidget(res_group, 1)

        # Progress
        progress_group = QGroupBox("PROGRESS")
        progress_group.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        progress_layout = QVBoxLayout(progress_group)

        progress_layout.addStretch(1)

        self.progress_bar = QProgressBar()
        self.progress_bar.setTextVisible(True)
        self.progress_bar.setFormat("%p%")
        self.progress_bar.setValue(0)
        self.progress_bar.setMinimumHeight(25)
        self.progress_bar.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Preferred)
        progress_layout.addWidget(self.progress_bar)

        self.status_label = QLabel("Ready")
        self.status_label.setObjectName("status")
        self.status_label.setAlignment(Qt.AlignCenter)
        progress_layout.addWidget(self.status_label)

        progress_layout.addStretch(1)

        layout.addWidget(progress_group, 1)

        # Convert button
        self.convert_btn = QPushButton("Convert Video")
        self.convert_btn.setMinimumHeight(55)
        self.convert_btn.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Preferred)
        self.convert_btn.setFont(QFont("", 16, QFont.Bold))
        self.convert_btn.clicked.connect(self.start_conversion)
        layout.addWidget(self.convert_btn)

        # Footer
        footer = QLabel("After conversion, copy the .raw file to your ComputerCraft computer\nand run: fastvideo video.raw 15")
        footer.setObjectName("status")
        footer.setAlignment(Qt.AlignCenter)
        layout.addWidget(footer)

    def set_resolution(self, w, h):
        self.width_spin.setValue(w)
        self.height_spin.setValue(h)

    def browse_input(self):
        path, _ = QFileDialog.getOpenFileName(
            self, "Select Video File", "",
            "Video files (*.gif *.mp4 *.webm *.avi *.mov *.mkv);;All files (*.*)"
        )
        if path:
            self.set_input_file(path)

    def set_input_file(self, path):
        self.input_edit.setText(path)
        base = os.path.splitext(path)[0]
        self.output_edit.setText(base + ".raw")
        self.drop_label.setText(f"Selected: {os.path.basename(path)}")

    def browse_output(self):
        path, _ = QFileDialog.getSaveFileName(
            self, "Save Raw Video As", self.output_edit.text(),
            "Raw video (*.raw);;All files (*.*)"
        )
        if path:
            self.output_edit.setText(path)

    def dragEnterEvent(self, event: QDragEnterEvent):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()

    def dropEvent(self, event: QDropEvent):
        urls = event.mimeData().urls()
        if urls:
            path = urls[0].toLocalFile()
            if os.path.isfile(path):
                self.set_input_file(path)

    def update_progress(self, value, status):
        self.progress_bar.setValue(value)
        self.status_label.setText(status)

    def conversion_finished(self, message):
        self.converting = False
        self.convert_btn.setEnabled(True)
        self.convert_btn.setText("Convert Video")
        QMessageBox.information(self, "Success", message)

    def conversion_error(self, message):
        self.converting = False
        self.convert_btn.setEnabled(True)
        self.convert_btn.setText("Convert Video")
        self.status_label.setText("Failed")
        QMessageBox.critical(self, "Error", message)

    def start_conversion(self):
        if self.converting:
            return

        input_path = self.input_edit.text()
        output_path = self.output_edit.text()

        if not input_path:
            QMessageBox.warning(self, "Error", "Please select an input video file")
            return

        if not os.path.exists(input_path):
            QMessageBox.warning(self, "Error", "Input file does not exist")
            return

        width = self.width_spin.value()
        height = self.height_spin.value()
        max_frames = self.frames_spin.value()

        self.converting = True
        self.convert_btn.setEnabled(False)
        self.convert_btn.setText("Converting...")

        thread = threading.Thread(
            target=self.convert_video,
            args=(input_path, output_path, width, height, max_frames)
        )
        thread.daemon = True
        thread.start()

    def convert_video(self, input_path, output_path, width, height, max_frames):
        try:
            try:
                import imageio.v3 as iio
                from PIL import Image
            except ImportError:
                self.signals.error.emit(
                    "Missing dependencies!\n\nRun: pip install pillow imageio imageio-ffmpeg"
                )
                return

            self.signals.progress.emit(5, "Reading video file...")

            try:
                frames_raw = iio.imread(input_path, plugin="pyav")
            except:
                try:
                    frames_raw = iio.imread(input_path)
                except Exception as e:
                    self.signals.error.emit(f"Failed to read video:\n{e}")
                    return

            if len(frames_raw.shape) == 3:
                frames_raw = [frames_raw]

            total_frames = len(frames_raw)
            if max_frames > 0:
                total_frames = min(total_frames, max_frames)

            self.signals.progress.emit(10, f"Processing {total_frames} frames...")

            frames = []
            for i, frame in enumerate(frames_raw[:total_frames]):
                img = Image.fromarray(frame)
                img = img.convert("RGBA")
                img = img.resize((width, height), Image.Resampling.LANCZOS)
                pixels = list(img.getdata())
                frames.append(pixels)

                progress = 10 + int((i / total_frames) * 60)
                if i % 3 == 0:
                    self.signals.progress.emit(progress, f"Processing frame {i+1}/{total_frames}")

            self.signals.progress.emit(75, "Writing output file...")

            with open(output_path, "wb") as f:
                f.write(struct.pack("<III", width, height, len(frames)))

                for i, pixels in enumerate(frames):
                    for r, g, b, a in pixels:
                        f.write(struct.pack("BBBB", b, g, r, a))

                    progress = 75 + int((i / len(frames)) * 20)
                    if i % 3 == 0:
                        self.signals.progress.emit(progress, f"Writing frame {i+1}/{len(frames)}")

            file_size = os.path.getsize(output_path) / 1024
            self.signals.progress.emit(100, f"Complete! ({file_size:.1f} KB)")

            self.signals.finished.emit(
                f"Video converted successfully!\n\n"
                f"Output: {os.path.basename(output_path)}\n"
                f"Size: {file_size:.1f} KB\n"
                f"Frames: {len(frames)}\n"
                f"Resolution: {width}×{height}\n\n"
                f"Copy to ComputerCraft and run:\n"
                f"fastvideo {os.path.basename(output_path)} 15"
            )

        except Exception as e:
            self.signals.error.emit(f"Conversion failed:\n{e}")


def main():
    app = QApplication(sys.argv)
    app.setStyleSheet(STYLESHEET)

    window = VideoConverterWindow()
    window.show()

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
