import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

import unittest
from vocaltractlab_cython import phoneme_file_to_gesture_file, VtlApiError
import os

class TestPhonemeFileToGestureFile(unittest.TestCase):

    def test_generate_gestural_score(self):
        # Test generating a gestural score file from a phoneme sequence file
        try:
            phoneme_file = "phoneme_sequence.txt"
            gesture_file = "output_gestural_score.txt"
            phoneme_file_to_gesture_file(phoneme_file, gesture_file, verbose_api=True)
            self.assertTrue(os.path.exists(gesture_file))  # Check if the gesture file was created
        except VtlApiError as e:
            self.fail(f"Failed to generate gestural score file: {e}")

    def test_nonexistent_phoneme_file(self):
        # Test providing a nonexistent phoneme sequence file (should raise a VtlApiError)
        with self.assertRaises(VtlApiError):
            phoneme_file = "nonexistent_phoneme_sequence.txt"
            gesture_file = "output_gestural_score.txt"
            phoneme_file_to_gesture_file(phoneme_file, gesture_file)

if __name__ == '__main__':
    unittest.main()
