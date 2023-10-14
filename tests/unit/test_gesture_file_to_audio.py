import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

import unittest
from vocaltractlab_cython import gesture_file_to_audio, VtlApiError
import numpy as np

class TestGestureFileToAudio(unittest.TestCase):

    def test_generate_audio_from_gesture_file(self):
        # Test generating audio from a valid gesture file
        gesture_file = "valid_gestural_score.txt"
        audio = gesture_file_to_audio(gesture_file)
        self.assertIsInstance(audio, np.ndarray)  # Check if audio is a NumPy array

    def test_save_generated_audio(self):
        # Test generating audio and saving it to a WAV file
        gesture_file = "valid_gestural_score.txt"
        audio_file = "output_audio.wav"
        audio = gesture_file_to_audio(gesture_file, audio_file)
        self.assertIsInstance(audio, np.ndarray)  # Check if audio is a NumPy array

    def test_generate_audio_with_verbose_output(self):
        # Test generating audio with verbose API output
        gesture_file = "valid_gestural_score.txt"
        audio = gesture_file_to_audio(gesture_file, verbose_api=True)
        self.assertIsInstance(audio, np.ndarray)  # Check if audio is a NumPy array

    def test_invalid_gesture_file(self):
        # Test generating audio from an invalid gesture file (should raise an exception)
        invalid_gesture_file = "invalid_gestural_score.txt"
        with self.assertRaises(VtlApiError):
            gesture_file_to_audio(invalid_gesture_file)