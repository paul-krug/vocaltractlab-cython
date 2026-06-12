

import os
import atexit
import logging as log
import warnings
import numpy as np
cimport numpy as np

from pathlib import Path 
from typing import List, Dict, Union, Optional


from .cVocalTractLabApi cimport vtlInitialize
from .cVocalTractLabApi cimport vtlClose
from .cVocalTractLabApi cimport vtlCalcTongueRootAutomatically
from .cVocalTractLabApi cimport vtlGetVersion
from .cVocalTractLabApi cimport vtlGetConstants
from .cVocalTractLabApi cimport vtlGetTractParamInfo
from .cVocalTractLabApi cimport vtlGetGlottisParamInfo
from .cVocalTractLabApi cimport vtlGetGlottisParams
from .cVocalTractLabApi cimport vtlGetTractParams
from .cVocalTractLabApi cimport vtlExportTractSvg
from .cVocalTractLabApi cimport vtlTractToTube
from .cVocalTractLabApi cimport vtlFastTractToTube
from .cVocalTractLabApi cimport vtlTractToFullTube
from .cVocalTractLabApi cimport vtlGetDefaultTransferFunctionOptions
from .cVocalTractLabApi cimport vtlGetTransferFunction
from .cVocalTractLabApi cimport TransferFunctionOptions
from .cVocalTractLabApi cimport RadiationType
from .cVocalTractLabApi cimport NO_RADIATION
from .cVocalTractLabApi cimport SPECTRUM_UU
from .cVocalTractLabApi cimport vtlInputTractToLimitedTract
from .cVocalTractLabApi cimport vtlSynthesisReset
from .cVocalTractLabApi cimport vtlSynthesisAddTube
#from .cVocalTractLabApi cimport vtlSynthesisAddTract
from .cVocalTractLabApi cimport vtlSynthBlock
#from .cVocalTractLabApi cimport vtlApiTest
from .cVocalTractLabApi cimport vtlSegmentSequenceToGesturalScore
from .cVocalTractLabApi cimport vtlGesturalScoreToAudio
from .cVocalTractLabApi cimport vtlGesturalScoreToTractSequence
from .cVocalTractLabApi cimport vtlGetGesturalScoreDuration
from .cVocalTractLabApi cimport vtlTractSequenceToAudio
#from .cVocalTractLabApi cimport vtlGesturalScoreToEmaAndMesh
#from .cVocalTractLabApi cimport vtlTractSequenceToEmaAndMesh
from .cVocalTractLabApi cimport vtlSaveSpeaker
from .cVocalTractLabApi cimport vtlSetAnatomyFromAge
from .cVocalTractLabApi cimport vtlGetAnatomyParams
from .cVocalTractLabApi cimport vtlSetAnatomyParams
from .cVocalTractLabApi cimport vtlGlottisCalcGeometry
from .cVocalTractLabApi cimport vtlGlottisIncTime
from .cVocalTractLabApi cimport vtlGlottisResetMotion
from .cVocalTractLabApi cimport vtlGetGlottisStaticParamInfo
from .cVocalTractLabApi cimport vtlTdsSetOptions
from .cVocalTractLabApi cimport vtlTdsResetMotion
from .cVocalTractLabApi cimport vtlSetFossaDims
from .cVocalTractLabApi cimport vtlTdsSetTubeAndRun
from .cVocalTractLabApi cimport vtlGetTLIntermediateValues
from .cVocalTractLabApi cimport vtlGetCrossSections
from .cVocalTractLabApi cimport vtlGetProfiles
from .cVocalTractLabApi cimport vtlGetCenterline
from .cVocalTractLabApi cimport vtlGetOutlines
from .cVocalTractLabApi cimport vtlGetTongueRibData
from .cVocalTractLabApi cimport vtlGetTongueWidthBounds
from .cVocalTractLabApi cimport vtlGetSurfaceVertices
from .cVocalTractLabApi cimport vtlGetCuts

from .utils import check_file_path
from .utils import make_file_path
from .utils import format_cstring

from .exceptions import VtlApiError
from .exceptions import get_api_exception


DEFAULT_SPEAKER = 'JD3.speaker'
DEFAULT_SPEAKER_PATH = os.path.join(
    os.path.dirname(__file__),
    'resources',
    DEFAULT_SPEAKER,
    )
ACTIVE_SPEAKER_PATH = None
# TODO: get auto_tongue_root directly from the API
# Speaker path can currently not be accessed from the API,
# because the API does not save it


def _initialize(
        speaker_file_path: Optional[ str ] = None,
        ):
    """
    Initialize the VocalTractLab API.

    This function initializes the VocalTractLab (VTL) API by loading a
    speaker-specific configuration file. This function will be called
    automatically when the module is loaded. Therefore, users do not
    need to call this function explicitly.

    Parameters
    ----------
    speaker_file_path : str, optional
        The path to the speaker-specific configuration file. If not
        provided, the default speaker configuration file will be used.

    Raises
    ------
    VtlApiError
        If the initialization process fails, a VtlApiError is raised 
        with details.

    Returns
    -------
    None

    Notes
    -----
    - The `speaker_file_path` should be a valid path to the speaker
      configuration file needed by the VTL API.
    - If the initialization process is successful, the VTL API is ready
      for use.

    Example
    -------
    >>> from vocaltractlab_cython import _initialize
    >>> try:
    >>>     _initialize("path/to/speaker.cfg")
    >>>     print("VTL API initialized successfully.")
    >>> except VtlApiError as e:
    >>>     print(f"Initialization failed: {e}")

    """
    if speaker_file_path is None:
        speaker_file_path = DEFAULT_SPEAKER_PATH
    cSpeakerFileName = speaker_file_path.encode()
    value = vtlInitialize( cSpeakerFileName )
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlInitialize',
                return_value = value,
                )
            )
    global ACTIVE_SPEAKER_PATH
    ACTIVE_SPEAKER_PATH = speaker_file_path
    log.info( f'VTL API was initialized with speaker: {ACTIVE_SPEAKER_PATH}' )
    return

def _close():
    """
    Close the VocalTractLab API.

    This function closes the VocalTractLab (VTL) API, releasing any
    allocated resources and finalizing the VTL API. It is automatically
    called when the module is unloaded. Therefore, users do not need to
    call this function explicitly.

    Raises
    ------
    VtlApiError
        If the closing process fails, a VtlApiError is raised with details.

    Returns
    -------
    None

    Notes
    -----
    - Use this function to gracefully close the VTL API after you've finished your tasks
      with the API.
    - If the closing process is successful, the VTL API will be closed, and allocated
      resources will be released.

    Example
    -------
    >>> from vocaltractlab_cython import _close
    >>> try:
    >>>     _close()
    >>>     print("VTL API closed successfully.")
    >>> except VtlApiError as e:
    >>>     print(f"Closing failed: {e}")

    """
    value = vtlClose()
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlClose',
                return_value = value,
                )
            )
    global ACTIVE_SPEAKER_PATH
    ACTIVE_SPEAKER_PATH = None
    log.info( 'VTL API closed.' )
    return

def active_speaker():
    """
    Get the path to the active speaker configuration file.

    This function retrieves the path to the active speaker configuration file
    that was used to initialize the VocalTractLab (VTL) API.

    Returns
    -------
    str
        The path to the active speaker configuration file.

    Notes
    -----
    - Use this function to obtain the path to the active speaker configuration file
      that was used to initialize the VTL API.

    Example
    -------
    >>> from vocaltractlab_cython import active_speaker
    >>> speaker_path = active_speaker()
    >>> print("Active Speaker Path:", speaker_path)

    """
    return ACTIVE_SPEAKER_PATH

# TODO: Implement the following function
#def auto_tongue_root_status():
#    """
#    Get the current status of automatic Tongue Root calculation.
#
#    This function retrieves the current status of automatic calculation of
#    Tongue Root parameters in the VocalTractLab (VTL) API.
#
#    Returns
#    -------
#    bool
#        True if automatic calculation of Tongue Root parameters is enabled,
#        False if it is disabled.
#
#    Notes
#    -----
#    - Use this function to check the current status of automatic calculation of
#      Tongue Root parameters in the VTL API.
#
#    Example
#    -------
#    >>> from vocaltractlab_cython import auto_tongue_root
#    >>> auto_calculation = auto_tongue_root_status()
#    >>> if auto_calculation:
#    >>>     print("Automatic Tongue Root calculation is enabled.")
#    >>> else:
#    >>>     print("Automatic Tongue Root calculation is disabled.")
#    
#    """
#    cdef bint automaticCalculationStatus
#    value = vtlGetAutomaticTongeStatus( &automaticCalculationStatus )
#    if value != 0:
#        raise VtlApiError(
#            get_api_exception(
#                function_name = 'vtlGetAutomaticTongeStatus',
#                return_value = value,
#                )
#            )
#    x = bool( automaticCalculationStatus )
#    return x



def calculate_tongueroot_automatically( automatic_calculation: bool ):
    """
    Configure automatic calculation of Tongue Root parameters.

    This function configures whether the VocalTractLab (VTL) API should automatically calculate
    the Tongue Root parameters or not.

    Parameters
    ----------
    automatic_calculation : bool
        Specify whether to enable (True) or disable (False) automatic calculation of Tongue Root parameters.

    Raises
    ------
    TypeError
        If the `automatic_calculation` argument is not a boolean.

    VtlApiError
        If the configuration process fails, a VtlApiError is raised with details.

    Returns
    -------
    None

    Notes
    -----
    - Use this function to configure the VTL API's behavior regarding the automatic calculation of Tongue Root parameters.
    - Set `automatic_calculation` to True to enable automatic calculation or False to disable it.

    Example
    -------
    >>> from vocaltractlab_cython import calculate_tongueroot_automatically
    >>> try:
    >>>     calculate_tongueroot_automatically(True)  # Enable automatic calculation
    >>>     print("Automatic Tongue Root calculation enabled.")
    >>> except TypeError as te:
    >>>     print(f"Invalid argument: {te}")
    >>> except VtlApiError as e:
    >>>     print(f"Configuration failed: {e}")

    """
    if not isinstance( automatic_calculation, bool ):
        raise TypeError(
            f"""
            Argument automatic_calculation must be a boolean,
            not {type( automatic_calculation )}.
            """
            )

    cdef bint automaticCalculation = automatic_calculation
    value = vtlCalcTongueRootAutomatically( automaticCalculation )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlCalcTongueRootAutomatically',
                return_value = value,
                )
            )

    log.info(
        f'Automatic calculation of the Tongue Root parameters was set to {automatic_calculation}.'
        )
    return

def gesture_file_to_audio(
        gesture_file: str,
        audio_file: Optional[ str ] = None,
        verbose_api: bool = False,
        ) -> np.ndarray:
    """
    Generate audio from a gestural score file.

    This function generates audio from a gestural score file using the VocalTractLab (VTL) API.
    The generated audio can be saved as a WAV file.

    Parameters
    ----------
    gesture_file : str
        The path to the gestural score file.
    audio_file : str, optional
        The path to save the generated audio as a WAV file. If not provided, the audio is not saved.
    verbose_api : bool, optional
        Enable console output from the VTL API (True) or disable it (False, default).

    Returns
    -------
    np.ndarray
        A NumPy array containing the generated audio samples.

    Raises
    ------
    VtlApiError
        If the audio generation process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to generate audio from a gestural score file.
    - The generated audio can be saved as a WAV file at the specified audio_file path.
    - The audio will be an array of audio samples.

    Example
    -------
    >>> from vocaltractlab_cython import gesture_file_to_audio
    >>> try:
    >>>     gesture_file = "gestural_score.txt"
    >>>     audio_file = "output_audio.wav"
    >>>     audio = gesture_file_to_audio(gesture_file, audio_file, verbose_api=True)
    >>>     print(f"Audio generated and saved as {audio_file}")
    >>> except VtlApiError as e:
    >>>     print(f"Audio generation failed: {e}")

    """
    check_file_path( gesture_file )

    if audio_file is None:
        audio_file = ''
    check_file_path( audio_file, must_exist=False )

    cGesFileName = gesture_file.encode()
    cWavFileName = audio_file.encode()

    duration = get_gesture_duration( gesture_file )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cAudio = np.zeros(
        duration[ 'n_audio_samples' ],
        dtype='float64',
        )
    cdef bint cEnableConsoleOutput = verbose_api
    cdef int cNumS = 0

    value = vtlGesturalScoreToAudio(
        cGesFileName,
        cWavFileName,
        &cAudio[0],
        &cNumS,
        cEnableConsoleOutput,
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGesturalScoreToAudio',
                return_value = value,
                function_args = dict(
                    gesture_file = gesture_file,
                    audio_file = audio_file,
                )
            )
        )

    audio = np.array( cAudio )

    log.info(
        f'Audio file: {audio_file} generated from gesture file: {gesture_file}'
        )
    return audio

def gesture_file_to_motor_file(
        gesture_file: str,
        motor_file: str,
        ):
    """
    Generate a motor (tract sequence) file from a gestural score file.

    This function generates a motor (tract sequence) file from a gestural score file using the VocalTractLab (VTL) API.

    Parameters
    ----------
    gesture_file : str
        The path to the gestural score file.
    motor_file : str
        The path to save the generated motor (tract sequence) file.

    Raises
    ------
    VtlApiError
        If the motor file generation process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to generate a motor file (tract sequence) from a gestural score file.
    - The motor file will be created at the specified motor_file path.

    Example
    -------
    >>> from vocaltractlab_cython import gesture_file_to_motor_file
    >>> try:
    >>>     gesture_file = "gestural_score.txt"
    >>>     motor_file = "output_motor.tract"
    >>>     gesture_file_to_motor_file(gesture_file, motor_file)
    >>>     print(f"Motor file generated and saved as {motor_file}")
    >>> except VtlApiError as e:
    >>>     print(f"Motor file generation failed: {e}")

    """
    check_file_path( gesture_file )
    # Make the directory of the tract file if it does not exist
    make_file_path( motor_file )

    cGesFileName = gesture_file.encode()
    cTractSequenceFileName = motor_file.encode()

    value = vtlGesturalScoreToTractSequence(
        cGesFileName,
        cTractSequenceFileName,
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGesturalScoreToTractSequence',
                return_value = value,
                function_args = dict(
                    gesture_file = gesture_file,
                    motor_file = motor_file,
                )
            )
        )

    log.info(
        f'Generated motor file {motor_file} from gesture file: {gesture_file}'
        )
    return

def get_constants():
    """
    Retrieve constants and parameters from the VocalTractLab API.

    This function retrieves various constants and parameters from the VocalTractLab (VTL) API,
    providing important information about the current VTL configuration.

    Returns
    -------
    dict
        A dictionary containing the following VTL constants and parameters:
        - 'sr_audio': int - Audio sampling rate.
        - 'sr_internal': float - Internal sampling rate.
        - 'n_tube_sections': int - Number of tube sections in the vocal tract model.
        - 'n_tract_params': int - Number of vocal tract parameters.
        - 'n_glottis_params': int - Number of glottis parameters.
        - 'n_samples_per_state': int - Number of audio samples per vocal tract state.

    Raises
    ------
    VtlApiError
        If the retrieval process fails, a VtlApiError is raised with details.
    ValueError
        If any of the retrieved values are below zero, a ValueError is raised.

    Notes
    -----
    - Use this function to obtain important constants and parameters to configure your VTL API
      usage.
    - It's important to check the retrieved values to ensure they are valid for your application.

    Example
    -------
    >>> from vocaltractlab_cython import get_constants
    >>> try:
    >>>     constants = get_constants()
    >>>     print("VTL Constants and Parameters:")
    >>>     for key, value in constants.items():
    >>>         print(f"{key}: {value}")
    >>> except VtlApiError as e:
    >>>     print(f"Retrieval failed: {e}")
    >>> except ValueError as ve:
    >>>     print(f"Invalid values retrieved: {ve}")

    """
    cdef int cAudioSamplingRate = -1
    cdef int cNumTubeSections = -1
    cdef int cNumVocalTractParams = -1
    cdef int cNumGlottisParams = -1
    cdef int cNumAudioSamplesPerTractState = -1
    cdef double cInternalSamplingRate = -1.0
    value = vtlGetConstants(
        &cAudioSamplingRate,
        &cNumTubeSections,
        &cNumVocalTractParams,
        &cNumGlottisParams,
        &cNumAudioSamplesPerTractState,
        &cInternalSamplingRate,
        )
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGetConstants',
                return_value = value,
                )
            )
    constants = dict(
        sr_audio = int( cAudioSamplingRate ),
        sr_internal = float( cInternalSamplingRate ),
        n_tube_sections = int( cNumTubeSections ),
        n_tract_params = int( cNumVocalTractParams ),
        n_glottis_params = int( cNumGlottisParams ),
        n_samples_per_state = int( cNumAudioSamplesPerTractState ),
    )
    # Check if any of the values is below zero, if so, raise an error
    for key, value in constants.items():
        if value < 0:
            raise ValueError(
                f'VTL API function vtlGetConstants returned a negative value for {key}: {value}'
                )
    return constants

def get_gesture_duration(
        gesture_file: str,
        ) -> Dict[str, Union[int, float]]:
    """
    Get the duration information of a gestural score file.

    This function retrieves information about the duration of a gestural
    score file, including the number of audio samples,
    the number of gesture samples, and the duration in seconds.

    Parameters
    ----------
    gesture_file : str
        The path to the gestural score file.

    Returns
    -------
    dict
        A dictionary containing the following duration information:
        - 'n_audio_samples': int - Number of audio samples.
        - 'n_gesture_samples': int - Number of gesture samples.
        - 'duration': float - Duration in seconds.

    Raises
    ------
    VtlApiError
        If the retrieval process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to obtain information about the duration of a gestural score file.
    - The duration is calculated based on the number of audio samples and the audio sampling rate.

    Example
    -------
    >>> from vocaltractlab_cython import get_gesture_duration
    >>> try:
    >>>     gesture_file = "gestural_score.txt"
    >>>     duration_info = get_gesture_duration(gesture_file)
    >>>     print("Duration Information:")
    >>>     for key, value in duration_info.items():
    >>>         print(f"{key}: {value}")
    >>> except VtlApiError as e:
    >>>     print(f"Retrieval failed: {e}")

    """
    check_file_path( gesture_file )

    cGesFileName = gesture_file.encode()
    cdef int cNumAudioSamples = -1
    cdef int cNumGestureSamples = -1

    value = vtlGetGesturalScoreDuration(
        cGesFileName,
        &cNumAudioSamples,
        &cNumGestureSamples,
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGetGesturalScoreDuration',
                return_value = value,
                )
            )

    vtl_constants = get_constants()
    n_audio_samples = int( cNumAudioSamples )
    n_gesture_samples = int( cNumGestureSamples )
    duration = n_audio_samples / vtl_constants[ 'sr_audio' ]
    
    result = dict(
        n_audio_samples = n_audio_samples,
        n_gesture_samples = n_gesture_samples,
        duration = duration,
    )

    return result

def get_param_info( params: str ) -> List[Dict[str, Union[str, float]]]:
    """
    Retrieve parameter information for either vocal tract or glottis parameters.

    This function retrieves information about vocal tract or glottis parameters from the VocalTractLab (VTL) API,
    including parameter names, descriptions, units, minimum and maximum values, and standard values.

    Parameters
    ----------
    params : str
        Specify whether to retrieve 'tract' parameters (vocal tract) or 'glottis' parameters (vocal folds).

    Returns
    -------
    List[Dict[str, Union[str, float]]]
        A list of dictionaries, each containing the following parameter information:
        - 'name': str - The name of the parameter.
        - 'description': str - A brief description of the parameter.
        - 'unit': str - The unit in which the parameter is measured.
        - 'min': float - The minimum allowable value for the parameter.
        - 'max': float - The maximum allowable value for the parameter.
        - 'standard': float - A standard or default value for the parameter.

    Raises
    ------
    ValueError
        If the `params` argument is not 'tract' or 'glottis'.
    VtlApiError
        If the retrieval process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to obtain information about vocal tract or glottis parameters in the VTL API.
    - Check the `params` argument to specify whether you want vocal tract or glottis parameters.

    Example
    -------
    >>> from vocaltractlab_cython import get_param_info
    >>> try:
    >>>     vocal_tract_params = get_param_info('tract')
    >>>     for param in vocal_tract_params:
    >>>         print("Parameter Name:", param['name'])
    >>>         print("Description:", param['description'])
    >>>         print("Unit:", param['unit'])
    >>>         print("Min Value:", param['min'])
    >>>         print("Max Value:", param['max'])
    >>>         print("Standard Value:", param['standard'])
    >>> except ValueError as ve:
    >>>     print(f"Invalid argument: {ve}")
    >>> except VtlApiError as e:
    >>>     print(f"Retrieval failed: {e}")

    """
    if params not in [ 'tract', 'glottis' ]:
        raise ValueError(
            'Argument params must be either "tract" or "glottis".'
            )
    if params == 'tract':
        key = 'n_tract_params'
    elif params == 'glottis':
        key = 'n_glottis_params'
    constants = get_constants()

    cNames = ( ' ' * 10 * constants[ key ] ).encode()
    cDescriptions = (' ' * 100 * constants[key]).encode()
    cUnits = (' ' * 10 * constants[key]).encode()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cParamMin = np.empty( constants[key], dtype='float64' )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cParamMax = np.empty( constants[key], dtype='float64' )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cParamStandard = np.empty( constants[key], dtype='float64' )
    if params == 'tract':
        vtlGetParamInfo = vtlGetTractParamInfo
        function_name = 'vtlGetTractParamInfo'
    elif params == 'glottis':
        vtlGetParamInfo = vtlGetGlottisParamInfo
        function_name = 'vtlGetGlottisParamInfo'
    value = vtlGetParamInfo(
            cNames,
            cDescriptions,
            cUnits,
            &cParamMin[0],
            &cParamMax[0],
            &cParamStandard[0],
            )
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = function_name,
                return_value = value,
                )
            )

    names = format_cstring( cNames )
    descriptions = format_cstring( cDescriptions )
    units = format_cstring( cUnits )
    
    param_info = [
        dict(
            name = name,
            description = desc,
            unit = unit,
            min = min_v,
            max = max_v,
            standard = std_v,
            )
        for name, desc, unit, min_v, max_v, std_v in zip(
            names,
            descriptions,
            units,
            cParamMin,
            cParamMax,
            cParamStandard,
            )
        ]
    return param_info

def get_shape(
        shape_name: str,
        params: str,
        ) -> np.ndarray:
    """
    Retrieve the shape parameters for a specific vocal tract or glottis shape.

    This function retrieves the shape parameters for a specific vocal tract or glottis shape
    from the VocalTractLab (VTL) API. The shape parameters represent the configuration of
    the vocal tract or glottis at a particular point in time.

    Parameters
    ----------
    shape_name : str
        The name of the vocal tract or glottis shape to retrieve.
    params : str
        Specify whether to retrieve 'tract' parameters (vocal tract) or 'glottis' parameters (vocal folds).

    Returns
    -------
    np.ndarray
        A NumPy array containing the shape parameters for the specified shape.

    Raises
    ------
    ValueError
        If the `params` argument is not 'tract' or 'glottis'.
    VtlApiError
        If the retrieval process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to obtain shape parameters for a specific vocal tract or glottis shape.
    - Check the `params` argument to specify whether you want vocal tract or glottis parameters.
    - The returned NumPy array contains the shape parameters, and its size is determined by
      the number of vocal tract or glottis parameters.

    Example
    -------
    >>> from vocaltractlab_cython import get_shape
    >>> try:
    >>>     shape_name = "example_shape"
    >>>     vocal_tract_shape = get_shape(shape_name, 'tract')
    >>>     print("Vocal Tract Shape Parameters for", shape_name, ":", vocal_tract_shape)
    >>> except ValueError as ve:
    >>>     print(f"Invalid argument: {ve}")
    >>> except VtlApiError as e:
    >>>     print(f"Retrieval failed: {e}")

    """
    if params not in [ 'tract', 'glottis' ]:
        raise ValueError(
            'Argument params must be either "tract" or "glottis".'
            )
    if params == 'tract':
        key = 'n_tract_params'
        vtlGetParams = vtlGetTractParams
        function_name = 'vtlGetTractParams'
    elif params == 'glottis':
        key = 'n_glottis_params'
        vtlGetParams = vtlGetGlottisParams
        function_name = 'vtlGetGlottisParams'
    vtl_constants = get_constants()
    cShapeName = shape_name.encode()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cParams = np.empty(
        shape = vtl_constants[ key ],
        dtype='float64',
        )
    value = vtlGetParams(
        cShapeName,
        &cParams[ 0 ],
        )
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = function_name,
                return_value = value,
                )
            )
    shape = np.array( cParams )
    return shape

def get_version() -> str:
    """
    Retrieve the version information of the VocalTractLab library.

    This function retrieves and returns the version information of the VocalTractLab (VTL) library,
    including the compile date of the library.

    Returns
    -------
    str
        A string containing the version information of the VTL library.

    Notes
    -----
    - Use this function to obtain information about the version of the VTL library.
    - The returned string typically includes the compile date of the library.

    Example
    -------
    >>> from vocaltractlab_cython import get_version
    >>> version = get_version()
    >>> print("VTL Library Version:", version)

    """
    cdef char cVersion[32]
    vtlGetVersion( cVersion )
    version = cVersion.decode()
    log.info( f'Compile date of the library: {version}' )
    return version

def phoneme_file_to_gesture_file(
        phoneme_file: str,
        gesture_file: str,
        verbose_api: bool = False,
        ):
    """
    Generate a gestural score file from a phoneme sequence file.

    This function generates a gestural score file from a phoneme sequence file using the VocalTractLab (VTL) API.

    Parameters
    ----------
    phoneme_file : str
        The path to the phoneme sequence file.
    gesture_file : str
        The path to save the generated gestural score file.
    verbose_api : bool, optional
        Enable console output from the VTL API (True) or disable it (False, default).

    Raises
    ------
    VtlApiError
        If the gestural score file generation process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to generate a gestural score file from a phoneme sequence file.
    - The generated gestural score file will be created at the specified gesture_file path.

    Example
    -------
    >>> from vocaltractlab_cython import phoneme_file_to_gesture_file
    >>> try:
    >>>     phoneme_file = "phoneme_sequence.txt"
    >>>     gesture_file = "output_gestural_score.txt"
    >>>     phoneme_file_to_gesture_file(phoneme_file, gesture_file, verbose_api=True)
    >>>     print(f"Gestural score file generated and saved as {gesture_file}")
    >>> except VtlApiError as e:
    >>>     print(f"Gestural score file generation failed: {e}")

    """
    check_file_path( phoneme_file )
    # Make the directory of the gestural score file if it does not exist
    make_file_path( gesture_file )

    
    cSegFileName = phoneme_file.encode()
    cGesFileName = gesture_file.encode()
    cdef bint cEnableConsoleOutput = verbose_api
    
    value = vtlSegmentSequenceToGesturalScore(
        cSegFileName,
        cGesFileName,
        cEnableConsoleOutput,
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlSegmentSequenceToGesturalScore',
                return_value = value,
                function_args = dict(
                    phoneme_file = phoneme_file,
                    gesture_file = gesture_file,
                )
            )
        )
    
    log.info(
        f'Created gesture file from phoneme sequence file: {phoneme_file}'
        )
    return

def _synth_block(
        tract_parameters: np.ndarray,
        glottis_parameters: np.ndarray,
        state_samples: int,
        verbose_api: bool = False,
        ) -> np.ndarray:
    """
    Synthesize audio from tract and glottis parameters.

    This function synthesizes audio based on the given tract and glottis parameters using the VocalTractLab (VTL) API.

    Parameters
    ----------
    tract_parameters : np.ndarray
        An array containing tract parameters for each frame.
    glottis_parameters : np.ndarray
        An array containing glottis parameters for each frame.
    state_samples : int
        The number of audio samples per vocal tract state (frame).
    verbose_api : bool, optional
        Enable console output from the VTL API (True) or disable it (False, default).

    Returns
    -------
    np.ndarray
        An array containing the synthesized audio samples.

    Raises
    ------
    VtlApiError
        If the audio synthesis process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to synthesize audio based on tract and glottis parameters.
    - The length of the returned audio array is determined by the number of frames and state_samples.

    Example
    -------
    >>> from vocaltractlab_cython import _synth_block
    >>> import numpy as np
    >>> try:
    >>>     # Generate tract and glottis parameter arrays
    >>>     tract_params = np.array([[0.1, 0.2, 0.3], [0.4, 0.5, 0.6]])
    >>>     glottis_params = np.array([[0.7, 0.8, 0.9], [1.0, 1.1, 1.2]])
    >>>     state_samples = 48000  # Example value
    >>>     audio = _synth_block(tract_params, glottis_params, state_samples, verbose_api=True)
    >>>     print(f"Synthesized audio with {len(audio)} samples.")
    >>> except VtlApiError as e:
    >>>     print(f"Audio synthesis failed: {e}")

    """
    n_frames = tract_parameters.shape[0]
    cdef int cNumFrames = n_frames
    cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = tract_parameters.ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cGlottisParams = glottis_parameters.ravel()
    cdef int cFrameStep_samples = state_samples
    cdef np.ndarray[ np.float64_t, ndim=1 ] cAudio = np.zeros(
        n_frames * state_samples,
        dtype='float64',
        )
    cdef bint cEnableConsoleOutput = verbose_api
    value = vtlSynthBlock(
        &cTractParams[0],
        &cGlottisParams[0],
        cNumFrames,
        cFrameStep_samples,
        &cAudio[0],
        cEnableConsoleOutput,
        )
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlSynthBlock',
                return_value = value,
                )
            )
    audio = np.array( cAudio )
    return audio

def synth_block(
        tract_parameters: np.ndarray,
        glottis_parameters: np.ndarray,
        state_samples: int = None,
        verbose_api: bool = False,
        ) -> np.ndarray:
    """
    Synthesize audio from tract and glottis parameters.

    This function synthesizes audio based on the given tract and glottis parameters using the VocalTractLab (VTL) API.
    It automatically checks and handles parameter shapes and provides an option to specify the number of audio samples
    per vocal tract state (frame).

    Parameters
    ----------
    tract_parameters : np.ndarray
        An array containing tract parameters for each frame.
    glottis_parameters : np.ndarray
        An array containing glottis parameters for each frame.
    state_samples : int, optional
        The number of audio samples per vocal tract state (frame). If not specified, it will be determined by the VTL API.
    verbose_api : bool, optional
        Enable console output from the VTL API (True) or disable it (False, default).

    Returns
    -------
    np.ndarray
        An array containing the synthesized audio samples.

    Raises
    ------
    ValueError
        If the input parameter arrays have incorrect shapes or dimensions.
    VtlApiError
        If the audio synthesis process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to synthesize audio based on tract and glottis parameters.
    - The function automatically checks the input parameter shapes and dimensions.
    - You can specify the number of audio samples per vocal tract state, or it will be determined by the VTL API.

    Example
    -------
    >>> from vocaltractlab_cython import synth_block
    >>> import numpy as np
    >>> try:
    >>>     # Generate tract and glottis parameter arrays
    >>>     tract_params = np.array([[0.1, 0.2, 0.3], [0.4, 0.5, 0.6]])
    >>>     glottis_params = np.array([[0.7, 0.8, 0.9], [1.0, 1.1, 1.2]])
    >>>     audio = synth_block(tract_params, glottis_params, state_samples=48000, verbose_api=True)
    >>>     print(f"Synthesized audio with {len(audio)} samples.")
    >>> except ValueError as ve:
    >>>     print(f"Input parameters have incorrect shapes: {ve}")
    >>> except VtlApiError as e:
    >>>     print(f"Audio synthesis failed: {e}")

    """
    vtl_constants = get_constants()

    # Input arrays are 2D
    if tract_parameters.ndim != 2:
        raise ValueError( 'Tract parameters must be a 2D array.' )
    if glottis_parameters.ndim != 2:
        raise ValueError( 'Glottis parameters must be a 2D array.' )

    # Check if the number of time steps is equal
    if tract_parameters.shape[0] != glottis_parameters.shape[0]:
        raise ValueError(
            'Number of rows in tract and glottis parameters must be equal.'
            )

    # Check if the number of tract parameters is correct
    if tract_parameters.shape[1] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError(
            f"""
            Number of columns in tract parameters must be equal to the
            number of VTL tract parameters ({vtl_constants[ 'n_tract_params' ]}).
            """
            )

    # Check if the number of glottis parameters is correct
    if glottis_parameters.shape[1] != vtl_constants[ 'n_glottis_params' ]:
        raise ValueError(
            f"""
            Number of columns in glottis parameters must be equal to the
            number of VTL glottis parameters ({vtl_constants[ 'n_glottis_params' ]}).
            """
            )

    if state_samples is None:
        state_samples = vtl_constants[ 'n_samples_per_state' ]

    audio = _synth_block(
        tract_parameters,
        glottis_parameters,
        state_samples,
        verbose_api,
        )

    return audio

def motor_file_to_audio_file(
        motor_file: str,
        audio_file: str,
        ):
    """
    Convert a motor (tract) file to an audio file.

    This function converts a motor (tract) file to an audio file using the VocalTractLab (VTL) API. The motor file
    contains motor commands for the vocal tract, which are used to generate the corresponding audio.

    Parameters
    ----------
    motor_file : str
        The path to the motor (tract) file to be converted.
    audio_file : str
        The path to the output audio file to be generated.

    Raises
    ------
    VtlApiError
        If the conversion process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to convert a motor file to an audio file.
    - The motor file should contain motor commands for the vocal tract.
    - The audio file will be generated based on the motor commands.

    Example
    -------
    >>> from vocaltractlab_cython import motor_file_to_audio_file
    >>> try:
    >>>     motor_file = 'motor_commands.ctr'
    >>>     audio_file = 'output_audio.wav'
    >>>     motor_file_to_audio_file(motor_file, audio_file)
    >>>     print(f"Converted motor file '{motor_file}' to audio file '{audio_file}'.")
    >>> except VtlApiError as e:
    >>>     print(f"Conversion failed: {e}")

    """
    check_file_path( motor_file )

    # Make the directory of the audio file if it does not exist
    make_file_path( audio_file )

    cTractSequenceFileName = motor_file.encode()
    cWavFileName = audio_file.encode()
    cAudio = NULL
    cNumS = NULL

    value = vtlTractSequenceToAudio(
        cTractSequenceFileName,
        cWavFileName,
        cAudio,
        cNumS,
        )
    
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlTractSequenceToAudio',
                return_value = value,
                function_args = dict(
                    motor_file = motor_file,
                    audio_file = audio_file,
                )
            )
        )

    log.info( f'Audio generated from tract sequence file: {motor_file}' )
    return

def tract_state_to_limited_tract_state(
        tract_state: np.ndarray
        ) -> np.ndarray:
    """
    Convert a full tract state to a limited tract state.

    This function converts a full vocal tract state to a limited vocal tract state using the VocalTractLab (VTL) API.
    The limited tract state has the same length as the full state but may have limited parameter values.

    Parameters
    ----------
    tract_state : np.ndarray
        An array representing the full vocal tract state.

    Returns
    -------
    np.ndarray
        An array representing the limited vocal tract state.

    Raises
    ------
    ValueError
        If the input tract state is not a 1D array or has an incorrect length.
    VtlApiError
        If the conversion process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to convert a full vocal tract state to a limited vocal tract state.
    - The limited state may have parameter values limited by the VTL API.

    Warnings
    --------
    - Virtual target parameters will be limited to the respective non-virtual range.
    - This may have a significant impact on the resulting vocal tract dynamics.

    Example
    -------
    >>> from vocaltractlab_cython import tract_state_to_limited_tract_state
    >>> import numpy as np
    >>> try:
    >>>     full_state = np.array([0.1, 0.2, 0.3])
    >>>     limited_state = tract_state_to_limited_tract_state(full_state)
    >>>     print(f"Full tract state: {full_state}")
    >>>     print(f"Limited tract state: {limited_state}")
    >>> except ValueError as ve:
    >>>     print(f"Invalid input tract state: {ve}")
    >>> except VtlApiError as e:
    >>>     print(f"Conversion failed: {e}")

    """
    vtl_constants = get_constants()

    # Check if the tract state is a 1D array
    if tract_state.ndim != 1:
        raise ValueError( 'Tract state must be a 1D array.' )

    # Check if the tract state has the correct length
    if tract_state.shape[0] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError(
            f"""
            Tract state has length {tract_state.shape[0]}, 
            but should have length {vtl_constants[ "n_tract_params" ]}.
            """
            )

    cdef np.ndarray[ np.float64_t, ndim=1 ] cInTractParams = tract_state.ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cOutTractParams = np.zeros(
        vtl_constants[ 'n_tract_params' ],
        dtype='float64',
        )

    value = vtlInputTractToLimitedTract(
        &cInTractParams[0],
        &cOutTractParams[0],
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlInputTractToLimitedTract',
                return_value = value,
                function_args = dict(
                    tract_state = tract_state,
                )
            )
        )

    limited_state = np.array( cOutTractParams )

    return limited_state

def tract_state_to_svg(
        tract_state: np.ndarray,
        svg_path: str,
        ):
    """
    Export vocal tract state to an SVG file.

    This function exports the vocal tract state represented by a 1D NumPy array to an SVG file.
    The SVG file visually represents the vocal tract configuration at a specific point in time.

    Parameters
    ----------
    tract_state : np.ndarray
        A 1D NumPy array representing the vocal tract state.
    svg_path : str, optional
        The path to save the SVG file. If not provided, the file will not be saved.

    Raises
    ------
    ValueError
        - If the tract_state is not a 1D array.
        - If the length of the tract_state does not match the number of vocal tract parameters.

    VtlApiError
        If the SVG export process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to visualize and export the vocal tract state as an SVG file.
    - The SVG file visually represents the vocal tract configuration.
    - The SVG file will be created at the specified svg_path.

    Example
    -------
    >>> from vocaltractlab_cython import tract_state_to_svg
    >>> try:
    >>>     vocal_tract_state = np.array([0.1, 0.2, 0.3, 0.4, 0.5])  # Example vocal tract state
    >>>     svg_path = "vocal_tract_state.svg"
    >>>     tract_state_to_svg(vocal_tract_state, svg_path)
    >>>     print(f"Vocal tract state exported as SVG: {svg_path}")
    >>> except ValueError as ve:
    >>>     print(f"Invalid argument: {ve}")
    >>> except VtlApiError as e:
    >>>     print(f"SVG export failed: {e}")

    """
    vtl_constants = get_constants()

    # Check if the tract state is a 1D array
    if tract_state.ndim != 1:
        raise ValueError( 'Tract state must be a 1D array.' )

    # Check if the tract state has the correct length
    if tract_state.shape[0] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError(
            f"""
            Tract state has length {tract_state.shape[0]}, 
            but should have length {vtl_constants[ "n_tract_params" ]}.
            """
            )

    # Make the directory of the svg file if it does not exist
    make_file_path( svg_path )
    
    vtl_constants = get_constants()
    cdef np.ndarray[np.float64_t, ndim = 1] cTractParams = tract_state.ravel()
    cFileName = svg_path.encode()

    value = vtlExportTractSvg(
        &cTractParams[0],
        cFileName,
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlExportTractSvg',
                return_value = value,
                function_args = dict(
                    tract_state = tract_state,
                    svg_path = svg_path,
                )
            )
        )

    return

def tract_state_to_transfer_function(
        tract_state: np.ndarray,
        n_spectrum_samples: int = 8192,
        save_magnitude_spectrum: bool = True,
        save_phase_spectrum: bool = True,
        boundary_layer: bool = None,
        heat_conduction: bool = None,
        soft_walls: bool = None,
        hagen_resistance: bool = None,
        inner_length_corrections: bool = None,
        lumped_elements: bool = None,
        paranasal_sinuses: bool = None,
        piriform_fossa: bool = None,
        static_pressure_drops: bool = None,
        radiation_type: int = None,
        ) -> Dict[ str, np.ndarray | int | None ]:
    """
    Compute the transfer function from a vocal tract state.

    This function computes the transfer function, including the magnitude and phase spectra, from a given vocal tract
    state using the VocalTractLab (VTL) API.

    Parameters
    ----------
    tract_state : np.ndarray
        An array representing the vocal tract state.
    n_spectrum_samples : int, optional
        The number of spectrum samples to compute (default is 8192).
    save_magnitude_spectrum : bool, optional
        Set to True to save the magnitude spectrum (default is True).
    save_phase_spectrum : bool, optional
        Set to True to save the phase spectrum (default is True).

    Returns
    -------
    dict
        A dictionary containing the following computed spectra and information:
        - 'magnitude_spectrum': np.ndarray - Magnitude spectrum of the transfer function.
        - 'phase_spectrum': np.ndarray - Phase spectrum of the transfer function.
        - 'n_spectrum_samples': int - Number of spectrum samples.

    Raises
    ------
    ValueError
        If the input tract state is not a 1D array or has an incorrect length.
    VtlApiError
        If the transfer function computation process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to compute the transfer function from a vocal tract state.
    - The computed transfer function includes both magnitude and phase spectra.

    Example
    -------
    >>> from vocaltractlab_cython import tract_state_to_transfer_function
    >>> import numpy as np
    >>> try:
    >>>     vocal_tract_state = np.array([0.1, 0.2, 0.3])
    >>>     transfer_function = tract_state_to_transfer_function(vocal_tract_state)
    >>>     print("Computed Transfer Function:")
    >>>     print(f"Magnitude Spectrum: {transfer_function['magnitude_spectrum']}")
    >>>     print(f"Phase Spectrum: {transfer_function['phase_spectrum']}")
    >>> except ValueError as ve:
    >>>     print(f"Invalid input vocal tract state: {ve}")
    >>> except VtlApiError as e:
    >>>     print(f"Transfer function computation failed: {e}")

    """
    vtl_constants = get_constants()

    # Check if the tract state is a 1D array
    if tract_state.ndim != 1:
        raise ValueError( 'Tract state must be a 1D array.' )

    # Check if the tract state has the correct length
    if tract_state.shape[0] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError(
            f"""
            Tract state has length {tract_state.shape[0]}, 
            but should have length {vtl_constants[ "n_tract_params" ]}.
            """
            )

    magnitude_spectrum = None
    phase_spectrum = None
    cdef int cNumSpectrumSamples = n_spectrum_samples
    cdef TransferFunctionOptions cOptsStruct
    cdef TransferFunctionOptions *cOpts = NULL

    # If any option is specified, build a custom options struct
    _any_opt = any(x is not None for x in [
        boundary_layer, heat_conduction, soft_walls, hagen_resistance,
        inner_length_corrections, lumped_elements, paranasal_sinuses,
        piriform_fossa, static_pressure_drops, radiation_type])
    if _any_opt:
        vtlGetDefaultTransferFunctionOptions(&cOptsStruct)
        if boundary_layer is not None:
            cOptsStruct.boundaryLayer = boundary_layer
        if heat_conduction is not None:
            cOptsStruct.heatConduction = heat_conduction
        if soft_walls is not None:
            cOptsStruct.softWalls = soft_walls
        if hagen_resistance is not None:
            cOptsStruct.hagenResistance = hagen_resistance
        if inner_length_corrections is not None:
            cOptsStruct.innerLengthCorrections = inner_length_corrections
        if lumped_elements is not None:
            cOptsStruct.lumpedElements = lumped_elements
        if paranasal_sinuses is not None:
            cOptsStruct.paranasalSinuses = paranasal_sinuses
        if piriform_fossa is not None:
            cOptsStruct.piriformFossa = piriform_fossa
        if static_pressure_drops is not None:
            cOptsStruct.staticPressureDrops = static_pressure_drops
        if radiation_type is not None:
            cOptsStruct.radiationType = <RadiationType>radiation_type
        cOpts = &cOptsStruct

    cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = tract_state.ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cMagnitude = np.zeros(
        n_spectrum_samples,
        dtype='float64',
        )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cPhase_rad = np.zeros(
        n_spectrum_samples,
        dtype='float64',
        )

    value = vtlGetTransferFunction(
        &cTractParams[0],
        cNumSpectrumSamples,
        cOpts,
        &cMagnitude[0],
        &cPhase_rad[0],
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGetTransferFunction',
                return_value = value,
                )
            )

    if save_magnitude_spectrum:
        magnitude_spectrum = np.array( cMagnitude )

    if save_phase_spectrum:
        phase_spectrum = np.array( cPhase_rad )

    transfer_function = dict(
        magnitude_spectrum = magnitude_spectrum,
        phase_spectrum = phase_spectrum,
        n_spectrum_samples = n_spectrum_samples,
        )

    return transfer_function

def tract_state_to_tube_state(
        tract_state: np.ndarray,
        fast_calculation: bool = False,
        save_tube_length: bool = True,
        save_tube_area: bool = True,
        save_tube_articulator: bool = True,
        save_incisor_position: bool = True,
        save_tongue_tip_side_elevation: bool = True,
        save_velum_opening: bool = True,
        ) -> Dict[ str, np.ndarray | float | None ]:
    """
    Compute tube state information from a vocal tract state.

    This function computes various tube state information from a given vocal tract state using the VocalTractLab (VTL) API.

    Parameters
    ----------
    tract_state : np.ndarray
        An array representing the vocal tract state.
    fast_calculation : bool, optional
        Set to True to use a fast calculation method (default is False).
    save_tube_length : bool, optional
        Set to True to save tube length information (default is True).
    save_tube_area : bool, optional
        Set to True to save tube area information (default is True).
    save_tube_articulator : bool, optional
        Set to True to save tube articulator information (default is True).
    save_incisor_position : bool, optional
        Set to True to save incisor position information (default is True).
    save_tongue_tip_side_elevation : bool, optional
        Set to True to save tongue tip side elevation information (default is True).
    save_velum_opening : bool, optional
        Set to True to save velum opening information (default is True).

    Returns
    -------
    dict
        A dictionary containing various tube state information:
        - 'tube_length': np.ndarray - Tube length information.
        - 'tube_area': np.ndarray - Tube area information.
        - 'tube_articulator': np.ndarray - Tube articulator information.
        - 'incisor_position': float - Incisor position.
        - 'tongue_tip_side_elevation': float - Tongue tip side elevation.
        - 'velum_opening': float - Velum opening.
        Values may be None for the information that is not requested to be saved.

    Raises
    ------
    ValueError
        If the input tract state is not a 1D array or has an incorrect length.
    VtlApiError
        If the tube state computation process fails, a VtlApiError is raised with details.

    Notes
    -----
    - Use this function to compute tube state information from a vocal tract state.
    - The computed information may include tube length, tube area, tube articulator, incisor position,
      tongue tip side elevation, and velum opening, depending on the selected options.

    Example
    -------
    >>> from vocaltractlab_cython import tract_state_to_tube_state
    >>> import numpy as np
    >>> try:
    >>>     vocal_tract_state = np.array([0.1, 0.2, 0.3])
    >>>     tube_state = tract_state_to_tube_state(vocal_tract_state)
    >>>     print("Computed Tube State:")
    >>>     if tube_state['tube_length'] is not None:
    >>>         print(f"Tube Length: {tube_state['tube_length']}")
    >>>     if tube_state['tube_area'] is not None:
    >>>         print(f"Tube Area: {tube_state['tube_area']}")
    >>>     if tube_state['tube_articulator'] is not None:
    >>>         print(f"Tube Articulator: {tube_state['tube_articulator']}")
    >>>     if tube_state['incisor_position'] is not None:
    >>>         print(f"Incisor Position: {tube_state['incisor_position']}")
    >>>     if tube_state['tongue_tip_side_elevation'] is not None:
    >>>         print(f"Tongue Tip Side Elevation: {tube_state['tongue_tip_side_elevation']}")
    >>>     if tube_state['velum_opening'] is not None:
    >>>         print(f"Velum Opening: {tube_state['velum_opening']}")
    >>> except ValueError as ve:
    >>>     print(f"Invalid input vocal tract state: {ve}")
    >>> except VtlApiError as e:
    >>>     print(f"Tube state computation failed: {e}")

    """
    vtl_constants = get_constants()

    # Check if the tract state is a 1D array
    if tract_state.ndim != 1:
        raise ValueError( 'Tract state must be a 1D array.' )

    # Check if the tract state has the correct length
    if tract_state.shape[0] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError(
            f"""
            Tract state has length {tract_state.shape[0]}, 
            but should have length {vtl_constants[ "n_tract_params" ]}.
            """
            )
        
    tube_length = None
    tube_area = None
    tube_articulator = None
    incisor_position = None
    tongue_tip_side_elevation = None
    velum_opening = None

    cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = tract_state.ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cTubeLength_cm = np.zeros(
        vtl_constants[ 'n_tube_sections' ],
        dtype='float64',
        )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cTubeArea_cm2 = np.zeros(
        vtl_constants[ 'n_tube_sections' ],
        dtype='float64',
        )
    cdef np.ndarray[ int, ndim=1 ] cTubeArticulator = np.zeros(
        vtl_constants[ 'n_tube_sections' ],
        dtype='i',
        )
    cdef double cIncisorPos_cm = 0.0
    cdef double cTongueTipSideElevation = 0.0
    cdef double cVelumOpening_cm2 = 0.0

    if fast_calculation:
        vtlCalcTube = vtlFastTractToTube
        function_name = 'vtlFastTractToTube'
    else:
        vtlCalcTube = vtlTractToTube
        function_name = 'vtlTractToTube'
        
    value = vtlCalcTube(
        &cTractParams[0],
        &cTubeLength_cm[0],
        &cTubeArea_cm2[0],
        &cTubeArticulator[0],
        &cIncisorPos_cm,
        &cTongueTipSideElevation,
        &cVelumOpening_cm2
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = function_name,
                return_value = value,
                function_args = dict(
                    tract_state = tract_state,
                    fast_calculation = fast_calculation,
                    save_tube_length = save_tube_length,
                    save_tube_area = save_tube_area,
                    save_tube_articulator = save_tube_articulator,
                    save_incisor_position = save_incisor_position,
                    save_tongue_tip_side_elevation = save_tongue_tip_side_elevation,
                    save_velum_opening = save_velum_opening,
                )
            )
        )

    if save_tube_length:
        tube_length = np.array( cTubeLength_cm )

    if save_tube_area:
        tube_area = np.array( cTubeArea_cm2 )

    if save_tube_articulator:
        tube_articulator = np.array( cTubeArticulator )

    if save_incisor_position:
        incisor_position = float( cIncisorPos_cm )

    if save_tongue_tip_side_elevation:
        tongue_tip_side_elevation = float( cTongueTipSideElevation )

    if save_velum_opening:
        velum_opening = float( cVelumOpening_cm2 )
    
    tube_state = dict(
        tube_length = tube_length,
        tube_area = tube_area,
        tube_articulator = tube_articulator,
        incisor_position = incisor_position,
        tongue_tip_side_elevation = tongue_tip_side_elevation,
        velum_opening = velum_opening,
        )

    return tube_state


def tract_state_to_full_tube(
        tract_state: np.ndarray,
        ) -> dict:
    """
    Compute the FULL tube (all 93 sections) from a vocal tract state.

    Unlike tract_state_to_tube_state which only returns the 40 pharynx/mouth
    sections, this function returns all 93 sections including trachea, glottis,
    nose, piriform fossa, and paranasal sinuses.

    After computing the tube, the glottis area is set to zero (matching
    vtlGetTransferFunction behavior).

    Parameters
    ----------
    tract_state : np.ndarray
        1D array of vocal tract parameters.

    Returns
    -------
    dict
        Dictionary with keys:
        - 'tube_length': np.ndarray (93,) - Section lengths in cm.
        - 'tube_area': np.ndarray (93,) - Section areas in cm^2.
        - 'tube_volume': np.ndarray (93,) - Section volumes in cm^3.
        - 'tube_wall_mass': np.ndarray (93,) - Wall mass in CGS.
        - 'tube_wall_stiffness': np.ndarray (93,) - Wall stiffness in CGS.
        - 'tube_wall_resistance': np.ndarray (93,) - Wall resistance in CGS.
        - 'tube_articulator': np.ndarray (93,) - Articulator indices.
        - 'incisor_position': float - Incisor position in cm.
        - 'tongue_tip_side_elevation': float - TS3 parameter.
        - 'velum_opening': float - Velum opening area in cm^2.
        - 'piriform_fossa_length': float - Piriform fossa length in cm.
        - 'piriform_fossa_volume': float - Piriform fossa volume in cm^3.
    """
    vtl_constants = get_constants()

    if tract_state.ndim != 1:
        raise ValueError('Tract state must be a 1D array.')
    if tract_state.shape[0] != vtl_constants['n_tract_params']:
        raise ValueError(
            f"Tract state has length {tract_state.shape[0]}, "
            f"but should have length {vtl_constants['n_tract_params']}."
        )

    cdef int NUM_SECTIONS = 93
    cdef np.ndarray[np.float64_t, ndim=1] cTractParams = tract_state.astype(np.float64).ravel()
    cdef np.ndarray[np.float64_t, ndim=1] cLength = np.zeros(NUM_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] cArea = np.zeros(NUM_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] cVolume = np.zeros(NUM_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] cWallMass = np.zeros(NUM_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] cWallStiffness = np.zeros(NUM_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] cWallResistance = np.zeros(NUM_SECTIONS, dtype='float64')
    cdef np.ndarray[int, ndim=1] cArticulator = np.zeros(NUM_SECTIONS, dtype='i')
    cdef double cIncisorPos = 0.0
    cdef double cTongueTipSideElev = 0.0
    cdef double cVelumOpening = 0.0
    cdef double cFossaLength = 0.0
    cdef double cFossaVolume = 0.0

    value = vtlTractToFullTube(
        &cTractParams[0],
        &cLength[0],
        &cArea[0],
        &cVolume[0],
        &cWallMass[0],
        &cWallStiffness[0],
        &cWallResistance[0],
        &cArticulator[0],
        &cIncisorPos,
        &cTongueTipSideElev,
        &cVelumOpening,
        &cFossaLength,
        &cFossaVolume,
    )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlTractToFullTube',
                return_value=value,
                function_args=dict(tract_state=tract_state),
            )
        )

    return dict(
        tube_length=np.array(cLength),
        tube_area=np.array(cArea),
        tube_volume=np.array(cVolume),
        tube_wall_mass=np.array(cWallMass),
        tube_wall_stiffness=np.array(cWallStiffness),
        tube_wall_resistance=np.array(cWallResistance),
        tube_articulator=np.array(cArticulator),
        incisor_position=float(cIncisorPos),
        tongue_tip_side_elevation=float(cTongueTipSideElev),
        velum_opening=float(cVelumOpening),
        piriform_fossa_length=float(cFossaLength),
        piriform_fossa_volume=float(cFossaVolume),
    )


def glottis_calc_geometry(
        control_params: np.ndarray,
        ) -> dict:
    """
    Set control parameters and compute glottis geometry.

    Parameters
    ----------
    control_params : np.ndarray
        1D array of control parameter values (numGlottisParams elements).

    Returns
    -------
    dict
        Dictionary with keys:
        - 'derived_params': np.ndarray of derived parameter values
        - 'tube_lengths': np.ndarray of tube section lengths (2 elements)
        - 'tube_areas': np.ndarray of tube section areas (2 elements)
    """
    cdef np.ndarray[np.float64_t, ndim=1] cControlParams = np.asarray(control_params, dtype='float64').ravel()
    # Buffer size 32: accommodates all glottis models (Geometric=8, Triangular=11, TwoMass=11)
    cdef np.ndarray[np.float64_t, ndim=1] cDerivedParams = np.zeros(32, dtype='float64')
    cdef int cNumDerived = 0
    cdef np.ndarray[np.float64_t, ndim=1] cTubeLength = np.zeros(2, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] cTubeArea = np.zeros(2, dtype='float64')

    value = vtlGlottisCalcGeometry(
        &cControlParams[0],
        &cDerivedParams[0],
        &cNumDerived,
        &cTubeLength[0],
        &cTubeArea[0],
    )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlGlottisCalcGeometry',
                return_value=value,
            )
        )

    return dict(
        derived_params=np.array(cDerivedParams[:cNumDerived]),
        tube_lengths=np.array(cTubeLength),
        tube_areas=np.array(cTubeArea),
    )


def glottis_inc_time(
        time_increment_s: float,
        pressure_dpa: np.ndarray,
        control_params: np.ndarray,
        ) -> dict:
    """
    Advance glottis simulation by one time step.

    Parameters
    ----------
    time_increment_s : float
        Time step in seconds.
    pressure_dpa : np.ndarray
        Pressure values (4 elements):
        [subglottal, lower_glottis, upper_glottis, supraglottal].
    control_params : np.ndarray
        Control parameter values (numGlottisParams elements).

    Returns
    -------
    dict
        Dictionary with keys:
        - 'derived_params': np.ndarray of derived parameter values
        - 'tube_lengths': np.ndarray of tube section lengths (2 elements)
        - 'tube_areas': np.ndarray of tube section areas (2 elements)
    """
    cdef double cTimeIncrement = time_increment_s
    cdef np.ndarray[np.float64_t, ndim=1] cPressure = np.asarray(pressure_dpa, dtype='float64').ravel()
    cdef np.ndarray[np.float64_t, ndim=1] cControlParams = np.asarray(control_params, dtype='float64').ravel()
    # Buffer size 32: accommodates all glottis models (Geometric=8, Triangular=11, TwoMass=11)
    cdef np.ndarray[np.float64_t, ndim=1] cDerivedParams = np.zeros(32, dtype='float64')
    cdef int cNumDerived = 0
    cdef np.ndarray[np.float64_t, ndim=1] cTubeLength = np.zeros(2, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] cTubeArea = np.zeros(2, dtype='float64')

    value = vtlGlottisIncTime(
        cTimeIncrement,
        &cPressure[0],
        &cControlParams[0],
        &cDerivedParams[0],
        &cNumDerived,
        &cTubeLength[0],
        &cTubeArea[0],
    )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlGlottisIncTime',
                return_value=value,
            )
        )

    return dict(
        derived_params=np.array(cDerivedParams[:cNumDerived]),
        tube_lengths=np.array(cTubeLength),
        tube_areas=np.array(cTubeArea),
    )


def glottis_reset_motion():
    """Reset the motion state of the glottis model (phase, time, filters)."""
    value = vtlGlottisResetMotion()
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlGlottisResetMotion',
                return_value=value,
            )
        )


def get_glottis_static_param_info() -> list:
    """
    Get static parameter info for the current glottis model.

    Returns
    -------
    list of dict
        Each dict has keys: 'name', 'min', 'max', 'standard'.
    """
    # Buffer sizes accommodate all glottis models (Geometric=4, Triangular=16, TwoMass=20)
    cdef char[1024] cNames
    cdef np.ndarray[np.float64_t, ndim=1] cMin = np.zeros(32, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] cMax = np.zeros(32, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] cStandard = np.zeros(32, dtype='float64')
    cdef int cNumParams = 0

    value = vtlGetGlottisStaticParamInfo(
        cNames,
        &cMin[0],
        &cMax[0],
        &cStandard[0],
        &cNumParams,
    )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlGetGlottisStaticParamInfo',
                return_value=value,
            )
        )

    names = cNames.decode('utf-8').split('\t')
    params = []
    for i in range(cNumParams):
        params.append(dict(
            name=names[i] if i < len(names) else f'param_{i}',
            min=float(cMin[i]),
            max=float(cMax[i]),
            standard=float(cStandard[i]),
        ))

    return params


# ===========================================================================
# TDS (Time-Domain Simulation) Component Testing API
# ===========================================================================

NUM_TDS_SECTIONS = 93
NUM_TDS_BRANCH_CURRENTS = 97


def tds_set_options(
    generate_noise_sources: bool = True,
    turbulence_losses: bool = True,
    soft_walls: bool = True,
    radiation_from_skin: bool = True,
    piriform_fossa: bool = True,
    inner_length_corrections: bool = False,
    transvelar_coupling: bool = False,
):
    """Set TDS options.

    Parameters
    ----------
    generate_noise_sources : bool
        Enable/disable noise source generation.
    turbulence_losses : bool
        Consider fluid dynamic losses due to turbulence.
    soft_walls : bool
        Consider losses due to soft walls.
    radiation_from_skin : bool
        Allow sound radiation from the skin.
    piriform_fossa : bool
        Include the piriform fossa.
    inner_length_corrections : bool
        Additional inductivities between adjacent sections.
    transvelar_coupling : bool
        Sound transmission through the velum tissue.
    """
    value = vtlTdsSetOptions(
        generate_noise_sources,
        turbulence_losses,
        soft_walls,
        radiation_from_skin,
        piriform_fossa,
        inner_length_corrections,
        transvelar_coupling,
    )
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlTdsSetOptions',
                return_value=value,
            )
        )


def tds_reset_motion():
    """Reset the TDS model motion state (pressures, currents, filters)."""
    value = vtlTdsResetMotion()
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlTdsResetMotion',
                return_value=value,
            )
        )


def set_fossa_dims(length_cm: float, volume_cm3: float):
    """Set piriform fossa dimensions on the global tube object.

    This modifies the global tube used by synthesis_add_tube() so that
    it uses custom fossa dimensions instead of the default 3.0/2.0.

    Args:
        length_cm: Fossa length in cm.
        volume_cm3: Fossa volume in cm^3.
    """
    value = vtlSetFossaDims(length_cm, volume_cm3)
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlSetFossaDims',
                return_value=value,
            )
        )


def synthesis_reset():
    """Reset the incremental Synthesizer (using vtlSynthesisAddTube/AddTract)."""
    value = vtlSynthesisReset()
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlSynthesisReset',
                return_value=value,
            )
        )


def synthesis_add_tube(
        num_new_samples: int,
        tube_length: np.ndarray,
        tube_area: np.ndarray,
        tube_articulator: np.ndarray,
        incisor_pos_cm: float,
        velum_opening_cm2: float,
        tongue_tip_side_elevation: float,
        glottis_params: np.ndarray,
        ) -> np.ndarray:
    """Incremental tube-based synthesis. Uses a global Tube with DEFAULT
    static cavity dimensions (fossa 3.0/2.0, subglottal 23.0, nasal 11.4).

    The first call after synthesis_reset() should use num_new_samples=0 to
    initialise the tube state. Subsequent calls generate audio.

    Parameters
    ----------
    num_new_samples : int
        Number of audio samples to generate.
    tube_length : np.ndarray
        PM section lengths (n_tube_sections,).
    tube_area : np.ndarray
        PM section areas (n_tube_sections,).
    tube_articulator : np.ndarray
        PM section articulators (n_tube_sections,).
    incisor_pos_cm : float
        Incisor position.
    velum_opening_cm2 : float
        Velum opening area.
    tongue_tip_side_elevation : float
        Tongue tip side elevation.
    glottis_params : np.ndarray
        Glottis control parameters (n_glottis_params,).

    Returns
    -------
    np.ndarray
        Audio samples of shape (num_new_samples,).
    """
    cdef np.ndarray[ np.float64_t, ndim=1 ] cAudio = np.zeros(
        max(num_new_samples, 1), dtype='float64')
    cdef np.ndarray[ np.float64_t, ndim=1 ] cTubeLength = np.array(
        tube_length, dtype='float64').ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cTubeArea = np.array(
        tube_area, dtype='float64').ravel()
    cdef np.ndarray[ int, ndim=1 ] cTubeArticulator = np.array(
        tube_articulator, dtype='i').ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cGlottisParams = np.array(
        glottis_params, dtype='float64').ravel()

    value = vtlSynthesisAddTube(
        num_new_samples,
        &cAudio[0],
        &cTubeLength[0],
        &cTubeArea[0],
        &cTubeArticulator[0],
        incisor_pos_cm,
        velum_opening_cm2,
        tongue_tip_side_elevation,
        &cGlottisParams[0],
    )
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlSynthesisAddTube',
                return_value=value,
            )
        )
    return cAudio[:num_new_samples]


def tds_set_tube_and_run(
        tube_length: np.ndarray,
        tube_area: np.ndarray,
        tube_articulator: np.ndarray,
        incisor_pos_cm: float,
        velum_opening_cm2: float,
        tongue_tip_side_elevation: float = 0.0,
        filtering: bool = False,
        pressure_source_section: int = -1,
        pressure_source_amp: float = 0.0,
        ) -> dict:
    """Set tube geometry on the TDS model, run one time step, return all state.

    Parameters
    ----------
    tube_length : np.ndarray
        Pharynx+mouth section lengths (40 elements).
    tube_area : np.ndarray
        Pharynx+mouth section areas (40 elements).
    tube_articulator : np.ndarray
        Pharynx+mouth articulators (40 elements, int).
    incisor_pos_cm : float
        Position of the incisors.
    velum_opening_cm2 : float
        Naso-pharyngeal port area.
    tongue_tip_side_elevation : float
        TS3 parameter.
    filtering : bool
        Apply area smoothing filter.
    pressure_source_section : int
        Section index for pressure source (-1 = none).
    pressure_source_amp : float
        Pressure source amplitude in dPa.

    Returns
    -------
    dict
        Dictionary with keys:
        - 'sec_area': (93,) section areas
        - 'sec_length': (93,) section lengths
        - 'sec_R0': (93,) left resistance
        - 'sec_R1': (93,) right resistance
        - 'sec_L': (93,) inductance
        - 'sec_C': (93,) capacitance
        - 'sec_D': (93,) D values
        - 'sec_E': (93,) E values
        - 'sec_alpha': (93,) wall vibration alpha
        - 'sec_beta': (93,) wall vibration beta
        - 'sec_pressure': (93,) pressure after step
        - 'bc_magnitude': (97,) branch current magnitudes
        - 'mouth_flow': float
        - 'nostril_flow': float
        - 'skin_flow': float
    """
    cdef np.ndarray[np.float64_t, ndim=1] cLength = np.ascontiguousarray(
        tube_length.ravel(), dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] cArea = np.ascontiguousarray(
        tube_area.ravel(), dtype='float64')
    cdef np.ndarray[int, ndim=1] cArt = np.ascontiguousarray(
        tube_articulator.ravel(), dtype='i')

    # Output arrays
    cdef np.ndarray[np.float64_t, ndim=1] oArea = np.zeros(NUM_TDS_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] oLength = np.zeros(NUM_TDS_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] oR0 = np.zeros(NUM_TDS_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] oR1 = np.zeros(NUM_TDS_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] oL = np.zeros(NUM_TDS_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] oC = np.zeros(NUM_TDS_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] oD = np.zeros(NUM_TDS_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] oE = np.zeros(NUM_TDS_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] oAlpha = np.zeros(NUM_TDS_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] oBeta = np.zeros(NUM_TDS_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] oPressure = np.zeros(NUM_TDS_SECTIONS, dtype='float64')
    cdef np.ndarray[np.float64_t, ndim=1] oBcMag = np.zeros(NUM_TDS_BRANCH_CURRENTS, dtype='float64')
    cdef double oMouth = 0.0, oNostril = 0.0, oSkin = 0.0

    value = vtlTdsSetTubeAndRun(
        &cLength[0], &cArea[0], &cArt[0],
        incisor_pos_cm, velum_opening_cm2, tongue_tip_side_elevation,
        filtering, pressure_source_section, pressure_source_amp,
        &oArea[0], &oLength[0],
        &oR0[0], &oR1[0], &oL[0], &oC[0],
        &oD[0], &oE[0], &oAlpha[0], &oBeta[0],
        &oPressure[0],
        &oBcMag[0],
        &oMouth, &oNostril, &oSkin,
    )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlTdsSetTubeAndRun',
                return_value=value,
            )
        )

    return dict(
        sec_area=np.array(oArea),
        sec_length=np.array(oLength),
        sec_R0=np.array(oR0),
        sec_R1=np.array(oR1),
        sec_L=np.array(oL),
        sec_C=np.array(oC),
        sec_D=np.array(oD),
        sec_E=np.array(oE),
        sec_alpha=np.array(oAlpha),
        sec_beta=np.array(oBeta),
        sec_pressure=np.array(oPressure),
        bc_magnitude=np.array(oBcMag),
        mouth_flow=float(oMouth),
        nostril_flow=float(oNostril),
        skin_flow=float(oSkin),
    )

def get_tl_intermediate_values(
        tract_params: np.ndarray,
        n_samples: int = 1000,
        options: dict = None,
        freq_index: int = 0,
        ) -> dict:
    """Get intermediate matrices and impedances of the TL model computation."""
    cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = np.array( tract_params, dtype='float64' )
    cdef int cNumSpectrumSamples = n_samples
    cdef int cFreqIndex = freq_index
    cdef TransferFunctionOptions cOpts
    
    if options is not None:
        cOpts.spectrumType = options.get('spectrum_type', NO_RADIATION)
        cOpts.radiationType = options.get('radiation_type', SPECTRUM_UU)
        cOpts.boundaryLayer = options.get('boundary_layer', True)
        cOpts.heatConduction = options.get('heat_conduction', True)
        cOpts.softWalls = options.get('soft_walls', True)
        cOpts.hagenResistance = options.get('hagen_resistance', True)
        cOpts.innerLengthCorrections = options.get('inner_length_corrections', True)
        cOpts.lumpedElements = options.get('lumped_elements', False)
        cOpts.paranasalSinuses = options.get('paranasal_sinuses', True)
        cOpts.piriformFossa = options.get('piriform_fossa', True)
        cOpts.staticPressureDrops = options.get('static_pressure_drops', True)
    
    cdef np.ndarray[ np.float64_t, ndim=1 ] cMatrixARe = np.empty( 93, dtype='float64' )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cMatrixAIm = np.empty( 93, dtype='float64' )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cMatrixBRe = np.empty( 93, dtype='float64' )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cMatrixBIm = np.empty( 93, dtype='float64' )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cMatrixCRe = np.empty( 93, dtype='float64' )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cMatrixCIm = np.empty( 93, dtype='float64' )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cMatrixDRe = np.empty( 93, dtype='float64' )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cMatrixDIm = np.empty( 93, dtype='float64' )
    
    cdef double cfossa_input_imp_re = 0
    cdef double cfossa_input_imp_im = 0
    cdef double cnose_rad_imp_re = 0
    cdef double cnose_rad_imp_im = 0
    cdef double cmouth_rad_imp_re = 0
    cdef double cmouth_rad_imp_im = 0
    
    if options is None:
        value = vtlGetTLIntermediateValues(
            &cTractParams[0],
            cNumSpectrumSamples,
            NULL,
            cFreqIndex,
            &cMatrixARe[0], &cMatrixAIm[0],
            &cMatrixBRe[0], &cMatrixBIm[0],
            &cMatrixCRe[0], &cMatrixCIm[0],
            &cMatrixDRe[0], &cMatrixDIm[0],
            &cfossa_input_imp_re, &cfossa_input_imp_im,
            &cnose_rad_imp_re, &cnose_rad_imp_im,
            &cmouth_rad_imp_re, &cmouth_rad_imp_im
        )
    else:
        value = vtlGetTLIntermediateValues(
            &cTractParams[0],
            cNumSpectrumSamples,
            &cOpts,
            cFreqIndex,
            &cMatrixARe[0], &cMatrixAIm[0],
            &cMatrixBRe[0], &cMatrixBIm[0],
            &cMatrixCRe[0], &cMatrixCIm[0],
            &cMatrixDRe[0], &cMatrixDIm[0],
            &cfossa_input_imp_re, &cfossa_input_imp_im,
            &cnose_rad_imp_re, &cnose_rad_imp_im,
            &cmouth_rad_imp_re, &cmouth_rad_imp_im
        )
        
    if value != 0:
        raise VtlApiError(f"vtlGetTLIntermediateValues failed with code {value}")
        
    return dict(
        matrix_a = np.array(cMatrixARe) + 1j * np.array(cMatrixAIm),
        matrix_b = np.array(cMatrixBRe) + 1j * np.array(cMatrixBIm),
        matrix_c = np.array(cMatrixCRe) + 1j * np.array(cMatrixCIm),
        matrix_d = np.array(cMatrixDRe) + 1j * np.array(cMatrixDIm),
        fossa_input_imp = cfossa_input_imp_re + 1j * cfossa_input_imp_im,
        nose_rad_imp = cnose_rad_imp_re + 1j * cnose_rad_imp_im,
        mouth_rad_imp = cmouth_rad_imp_re + 1j * cmouth_rad_imp_im,
    )

NUM_CROSS_SECTIONS = 129

def get_cross_sections(
        tract_state: np.ndarray,
        ) -> dict:
    """
    Get the 129 cross-section areas, positions, and articulators from the
    VocalTract model for a given tract state.

    Parameters
    ----------
    tract_state : np.ndarray
        An array representing the vocal tract state with numVocalTractParams
        elements.

    Returns
    -------
    dict
        A dictionary with keys:
        - 'areas': np.ndarray of shape (129,) with cross-section areas in cm^2.
        - 'positions': np.ndarray of shape (129,) with positions along the
          center line in cm.
        - 'articulators': np.ndarray of shape (129,) with articulator indices
          (int).

    Raises
    ------
    ValueError
        If the input tract state is not a 1D array or has an incorrect length.
    VtlApiError
        If the C API call fails.
    """
    vtl_constants = get_constants()

    if tract_state.ndim != 1:
        raise ValueError( 'Tract state must be a 1D array.' )

    if tract_state.shape[0] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError(
            f"""
            Tract state has length {tract_state.shape[0]},
            but should have length {vtl_constants[ "n_tract_params" ]}.
            """
            )

    cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = tract_state.astype( 'float64' ).ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cAreas = np.zeros( NUM_CROSS_SECTIONS, dtype='float64' )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cPositions = np.zeros( NUM_CROSS_SECTIONS, dtype='float64' )
    cdef np.ndarray[ int, ndim=1 ] cArticulators = np.zeros( NUM_CROSS_SECTIONS, dtype='i' )

    value = vtlGetCrossSections(
        &cTractParams[0],
        &cAreas[0],
        &cPositions[0],
        &cArticulators[0],
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGetCrossSections',
                return_value = value,
                function_args = dict(
                    tract_state = tract_state,
                )
            )
        )

    return dict(
        areas = np.array( cAreas ),
        positions = np.array( cPositions ),
        articulators = np.array( cArticulators ),
    )


NUM_PROFILE_SAMPLES = 96

def get_profiles(
        tract_state: np.ndarray,
        centerline_index: int,
        ) -> dict:
    """
    Get the upper and lower cross-sectional profiles at a specific
    centerline index for the given vocal tract parameters.

    Parameters
    ----------
    tract_state : np.ndarray
        An array representing the vocal tract state with
        numVocalTractParams (19) elements.
    centerline_index : int
        Index along the centerline (0..128).

    Returns
    -------
    dict
        A dictionary with keys:
        - 'upper_profile': np.ndarray of shape (96,) with upper profile values.
        - 'lower_profile': np.ndarray of shape (96,) with lower profile values.
        - 'info': np.ndarray of shape (6,) with centerline info:
            [point.x, point.y, normal.x, normal.y, area, pos].

    Raises
    ------
    ValueError
        If the input tract state is not a 1D array, has an incorrect
        length, or the centerline index is out of range.
    VtlApiError
        If the C API call fails.
    """
    vtl_constants = get_constants()

    if tract_state.ndim != 1:
        raise ValueError( 'Tract state must be a 1D array.' )

    if tract_state.shape[0] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError(
            f"""
            Tract state has length {tract_state.shape[0]},
            but should have length {vtl_constants[ "n_tract_params" ]}.
            """
            )

    if centerline_index < 0 or centerline_index >= NUM_CROSS_SECTIONS:
        raise ValueError(
            f"""
            centerline_index {centerline_index} is out of range
            [0, {NUM_CROSS_SECTIONS}).
            """
            )

    cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = tract_state.astype( 'float64' ).ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cUpperProfile = np.zeros( NUM_PROFILE_SAMPLES, dtype='float64' )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cLowerProfile = np.zeros( NUM_PROFILE_SAMPLES, dtype='float64' )
    cdef np.ndarray[ np.float64_t, ndim=1 ] cCenterlineInfo = np.zeros( 6, dtype='float64' )

    value = vtlGetProfiles(
        &cTractParams[0],
        centerline_index,
        &cUpperProfile[0],
        &cLowerProfile[0],
        &cCenterlineInfo[0],
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGetProfiles',
                return_value = value,
                function_args = dict(
                    tract_state = tract_state,
                    centerline_index = centerline_index,
                )
            )
        )

    return dict(
        upper_profile = np.array( cUpperProfile ),
        lower_profile = np.array( cLowerProfile ),
        info = np.array( cCenterlineInfo ),
    )


def get_centerline(
        tract_state: np.ndarray,
        ) -> np.ndarray:
    """
    Get all 129 centerline points for the given vocal tract parameters.

    Parameters
    ----------
    tract_state : np.ndarray
        An array representing the vocal tract state with
        numVocalTractParams (19) elements.

    Returns
    -------
    np.ndarray
        Array of shape (129, 5) with columns [x, y, normal_x, normal_y, pos].
    """
    vtl_constants = get_constants()

    if tract_state.ndim != 1:
        raise ValueError( 'Tract state must be a 1D array.' )

    if tract_state.shape[0] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError(
            f"""
            Tract state has length {tract_state.shape[0]},
            but should have length {vtl_constants[ "n_tract_params" ]}.
            """
            )

    cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = tract_state.astype( 'float64' ).ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cCenterlineData = np.zeros( NUM_CROSS_SECTIONS * 5, dtype='float64' )

    value = vtlGetCenterline(
        &cTractParams[0],
        &cCenterlineData[0],
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGetCenterline',
                return_value = value,
                function_args = dict(
                    tract_state = tract_state,
                )
            )
        )

    return np.array( cCenterlineData ).reshape( NUM_CROSS_SECTIONS, 5 )


def get_outlines(
        tract_state: np.ndarray,
        ) -> dict:
    """
    Get the 4 outlines (upper, lower, tongue, epiglottis) for centerline computation.

    Returns
    -------
    dict with keys 'upper', 'lower', 'tongue', 'epiglottis', each np.ndarray of shape (n, 2).
    """
    vtl_constants = get_constants()
    if tract_state.ndim != 1 or tract_state.shape[0] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError( 'Invalid tract_state shape.' )

    cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = tract_state.astype( 'float64' ).ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cOutlineData = np.zeros( 1600, dtype='float64' )
    cdef np.ndarray[ int, ndim=1 ] cOutlineSizes = np.zeros( 4, dtype=np.intc )

    value = vtlGetOutlines(
        &cTractParams[0],
        &cOutlineData[0],
        &cOutlineSizes[0],
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGetOutlines',
                return_value = value,
                function_args = dict( tract_state = tract_state ),
            )
        )

    names = ['upper', 'lower', 'tongue', 'epiglottis']
    result = {}
    offset = 0
    for idx, name in enumerate(names):
        n = cOutlineSizes[idx]
        result[name] = np.array( cOutlineData[offset:offset + n * 2] ).reshape( n, 2 )
        offset += n * 2

    return result


def get_tongue_rib_data(
        tract_state: np.ndarray,
        ) -> np.ndarray:
    """Get tongue rib data: (N, 6) = [px, py, nx, ny, leftH, rightH]."""
    vtl_constants = get_constants()
    if tract_state.ndim != 1 or tract_state.shape[0] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError( 'Invalid tract_state shape.' )

    cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = tract_state.astype( 'float64' ).ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cRibData = np.zeros( 50 * 6, dtype='float64' )
    cdef int cNumRibs = 0

    value = vtlGetTongueRibData(
        &cTractParams[0],
        &cRibData[0],
        &cNumRibs,
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGetTongueRibData',
                return_value = value,
                function_args = dict( tract_state = tract_state ),
            )
        )

    return np.array( cRibData[:cNumRibs * 6] ).reshape( cNumRibs, 6 )


def get_tongue_width_bounds(
        tract_state: np.ndarray,
        ) -> np.ndarray:
    """Get tongue rib width bounds: (N, 2) = [minX, maxX]."""
    vtl_constants = get_constants()
    if tract_state.ndim != 1 or tract_state.shape[0] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError( 'Invalid tract_state shape.' )

    cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = tract_state.astype( 'float64' ).ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cBoundsData = np.zeros( 50 * 2, dtype='float64' )
    cdef int cNumRibs = 0

    value = vtlGetTongueWidthBounds(
        &cTractParams[0],
        &cBoundsData[0],
        &cNumRibs,
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGetTongueWidthBounds',
                return_value = value,
                function_args = dict( tract_state = tract_state ),
            )
        )

    return np.array( cBoundsData[:cNumRibs * 2] ).reshape( cNumRibs, 2 )


def get_surface_vertices(
        tract_state: np.ndarray,
        surface_index: int,
        ) -> np.ndarray:
    """Get all vertex positions for a specific surface.

    Returns ndarray of shape (numRibs, numRibPoints, 3) with (x, y, z) per vertex.
    """
    vtl_constants = get_constants()
    if tract_state.ndim != 1 or tract_state.shape[0] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError( 'Invalid tract_state shape.' )

    cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = tract_state.astype( 'float64' ).ravel()
    # Max surface size: 100 ribs * 50 rib points * 3 coords
    cdef np.ndarray[ np.float64_t, ndim=1 ] cVertexData = np.zeros( 100 * 50 * 3, dtype='float64' )
    cdef int cNumRibs = 0
    cdef int cNumRibPoints = 0

    value = vtlGetSurfaceVertices(
        &cTractParams[0],
        surface_index,
        &cVertexData[0],
        &cNumRibs,
        &cNumRibPoints,
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGetSurfaceVertices',
                return_value = value,
                function_args = dict( tract_state = tract_state, surface_index = surface_index ),
            )
        )

    n = cNumRibs * cNumRibPoints * 3
    return np.array( cVertexData[:n] ).reshape( cNumRibs, cNumRibPoints, 3 )


def get_cuts(
        tract_state: np.ndarray,
        centerline_index: int,
        ) -> dict:
    """Get raw triangle intersection cuts at a specific centerline index.

    Returns dict with:
        'cuts': ndarray of shape (numCuts, 8) where each row is
                [P0.x, P0.y, P1.x, P1.y, n.x, n.y, globalSurfaceIndex, localSurfaceIndex]
        'num_cuts': int
    """
    vtl_constants = get_constants()
    if tract_state.ndim != 1 or tract_state.shape[0] != vtl_constants[ 'n_tract_params' ]:
        raise ValueError( 'Invalid tract_state shape.' )

    cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = tract_state.astype( 'float64' ).ravel()
    cdef np.ndarray[ np.float64_t, ndim=1 ] cCutData = np.zeros( 2048 * 8, dtype='float64' )
    cdef int cNumCuts = 0

    value = vtlGetCuts(
        &cTractParams[0],
        centerline_index,
        &cCutData[0],
        &cNumCuts,
        )

    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name = 'vtlGetCuts',
                return_value = value,
                function_args = dict( tract_state = tract_state, centerline_index = centerline_index ),
            )
        )

    return dict(
        cuts = np.array( cCutData[:cNumCuts * 8] ).reshape( cNumCuts, 8 ),
        num_cuts = cNumCuts,
    )


def save_speaker(speaker_file_path: str) -> None:
    """Save the currently loaded speaker to a .speaker XML file.

    Parameters
    ----------
    speaker_file_path : str
        Output file path.
    """
    cdef bytes cSpeakerPath = str(speaker_file_path).encode('utf-8')
    value = vtlSaveSpeaker(cSpeakerPath)
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlSaveSpeaker',
                return_value=value,
                function_args=dict(speaker_file_path=speaker_file_path),
            )
        )


def set_anatomy_from_age(age_months: int, is_male: bool) -> None:
    """Apply anatomy parameters derived from age and gender.

    Calls calcFromAge, restrictParams, and setFor on the loaded vocal tract.

    Parameters
    ----------
    age_months : int
        Age in months (minimum 12).
    is_male : bool
        True for male, False for female.
    """
    value = vtlSetAnatomyFromAge(age_months, is_male)
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlSetAnatomyFromAge',
                return_value=value,
                function_args=dict(age_months=age_months, is_male=is_male),
            )
        )


def get_anatomy_params() -> np.ndarray:
    """Get the 13 anatomy parameters from the loaded vocal tract.

    Returns
    -------
    np.ndarray
        Array of 13 doubles (anatomy parameter values).
    """
    cdef np.ndarray[np.float64_t, ndim=1] cParams = np.zeros(13, dtype='float64')
    value = vtlGetAnatomyParams(&cParams[0])
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlGetAnatomyParams',
                return_value=value,
                function_args=dict(),
            )
        )
    return cParams


def set_anatomy_params(anatomy_params: np.ndarray) -> None:
    """Set the 13 anatomy parameters on the loaded vocal tract.

    Calls restrictParams and setFor internally.

    Parameters
    ----------
    anatomy_params : np.ndarray
        Array of 13 doubles with the anatomy parameter values.
    """
    cdef np.ndarray[np.float64_t, ndim=1] cParams = np.array(
        anatomy_params, dtype='float64'
    ).ravel()
    if cParams.shape[0] != 13:
        raise ValueError(f'Expected 13 anatomy params, got {cParams.shape[0]}')
    value = vtlSetAnatomyParams(&cParams[0])
    if value != 0:
        raise VtlApiError(
            get_api_exception(
                function_name='vtlSetAnatomyParams',
                return_value=value,
                function_args=dict(anatomy_params=anatomy_params),
            )
        )


# Function to be called at module exit
atexit.register( _close )

# Function to be called at module import
_initialize( DEFAULT_SPEAKER_PATH )