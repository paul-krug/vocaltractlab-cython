
import os

from .VocalTractLabApi import *


def speaker_path() -> str:
    """Return the absolute path of the bundled JD3 speaker file."""
    return os.path.join(
        os.path.dirname( os.path.abspath( __file__ ) ),
        'resources',
        'JD3.speaker',
        )

#from .VocalTractLabApi import calculate_tongueroot_automatically
#from .VocalTractLabApi import gestural_score_to_audio
#from .VocalTractLabApi import gestural_score_to_tract_sequence
#from .VocalTractLabApi import get_constants
#from .VocalTractLabApi import get_gestural_score_duration
#from .VocalTractLabApi import get_param_info
#from .VocalTractLabApi import get_shape
#from .VocalTractLabApi import get_version
#from .VocalTractLabApi import segment_sequence_to_gestural_score
#from .VocalTractLabApi import
#from .VocalTractLabApi import
#from .VocalTractLabApi import
#from .VocalTractLabApi import
#from .VocalTractLabApi import
#from .VocalTractLabApi import
#from .VocalTractLabApi import
#from .VocalTractLabApi import
#from .VocalTractLabApi import
#from .VocalTractLabApi import
#from .VocalTractLabApi import
#from .VocalTractLabApi import
