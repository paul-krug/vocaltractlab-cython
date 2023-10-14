import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

import unittest
from vocaltractlab_cython import gesture_file_to_motor_file, VtlApiError
import os

class TestGestureFileToMotorFile(unittest.TestCase):

    def test_generate_motor_file_from_gesture_file(self):
        # Test generating a motor file from a valid gesture file
        gesture_file = "valid_gestural_score.txt"
        motor_file = "output_motor.tract"
        gesture_file_to_motor_file(gesture_file, motor_file)
        self.assertTrue(os.path.exists(motor_file))  # Check if the motor file was generated

    def test_generate_motor_file_invalid_gesture_file(self):
        # Test generating a motor file from an invalid gesture file (should raise an exception)
        invalid_gesture_file = "invalid_gestural_score.txt"
        motor_file = "output_motor.tract"
        with self.assertRaises(VtlApiError):
            gesture_file_to_motor_file(invalid_gesture_file, motor_file)