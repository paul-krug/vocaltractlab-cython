

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
from .cVocalTractLabApi cimport vtlGetDefaultTransferFunctionOptions
from .cVocalTractLabApi cimport vtlGetTransferFunction
from .cVocalTractLabApi cimport vtlInputTractToLimitedTract
#from .cVocalTractLabApi cimport vtlSynthesisReset
#from .cVocalTractLabApi cimport vtlSynthesisAddTube
#from .cVocalTractLabApi cimport vtlSynthesisAddTract
from .cVocalTractLabApi cimport vtlSynthBlock
#from .cVocalTractLabApi cimport vtlApiTest
from .cVocalTractLabApi cimport vtlSegmentSequenceToGesturalScore
from .cVocalTractLabApi cimport vtlGesturalScoreToAudio
from .cVocalTractLabApi cimport vtlGesturalScoreToTractSequence
from .cVocalTractLabApi cimport vtlGetGesturalScoreDuration
from .cVocalTractLabApi cimport vtlTractSequenceToAudio
#from .cVocalTractLabApi cimport vtlGesturalScoreToEma
#from .cVocalTractLabApi cimport vtlGesturalScoreToEmaAndMesh
#from .cVocalTractLabApi cimport vtlTractSequenceToEmaAndMesh
#from .cVocalTractLabApi cimport vtlSaveSpeaker

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
    cOpts = NULL
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



    

# Function to be called at module exit
atexit.register( _close )

# Function to be called at module import
_initialize( DEFAULT_SPEAKER_PATH )