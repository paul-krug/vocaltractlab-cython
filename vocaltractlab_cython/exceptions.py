

api_exceptions = dict(
    vtlInitialize = [
        'Success.',
        'Loading the speaker file failed.',
    ],
    vtlClose = [
        'Success.',
        'The API was not initialized.',
    ],
    vtlCalcTongueRootAutomatically = [
        'Success.',
        'The API was not initialized.',
    ],
    vtlGetVersion = None,
    vtlGetConstants = [
        'Success.',
        'The API was not initialized.',
    ],
    vtlGetTractParamInfo = [
        'Success.',
        'The API was not initialized.',
    ],
    vtlGetGlottisParamInfo = [
        'Success.',
        'The API was not initialized.',
    ],
    vtlGetGlottisParams = [
        'Success.',
        'The API was not initialized.',
        'A shape with the given name does not exist.',
    ],
    vtlGetTractParams = [
        'Success.',
        'The API was not initialized.',
        'A shape with the given name does not exist.',
    ],
    vtlExportTractSvg = [
        'Success.',
        'The API was not initialized.',
        'Writing the SVG file failed.',
    ],
    vtlTractToTube = [
        'Success.',
        'The API was not initialized.',
    ],
    vtlFastTractToTube = [
        'Success.',
        'The API was not initialized.',
    ],
    vtlGetDefaultTransferFunctionOptions = [
        'Success.',
        'The API was not initialized.',
    ],
    vtlGetTransferFunction = [
        'Success.',
        'The API was not initialized.',
    ],
    vtlInputTractToLimitedTract = [
        'Success.',
        'The API was not initialized.',
    ],
    vtlSynthesisReset = [
        'Success.',
        'The API was not initialized.',
    ],
    vtlSynthesisAddTube = [
        'Success.',
        'The API was not initialized.',
        """
        Number of generated audio samples is wrong
        (may happen when numNewSamples != 0 during
        the first call of this function after reset).
        """,
    ],
    vtlSynthesisAddTract = [
        'Success.',
        'The API was not initialized.',
        """
        Number of generated audio samples is wrong
        (may happen when numNewSamples != 0 during
        the first call of this function after reset).
        """,
    ],
    vtlSynthBlock = [
        'Success.',
        'The API was not initialized.',
    ],
    vtlApiTest = None,
    vtlSegmentSequenceToGesturalScore = [
        'Success.',
        'The API was not initialized.',
        'Loading the segment sequence file failed.',
        'Saving the gestural score file failed.',
    ],
    vtlGesturalScoreToAudio = [
        'Success.',
        'The API was not initialized.',
        'Loading the gestural score file failed.',
        'Values in the gestural score file are out of range.',
        'The WAV file could not be saved.',
    ],
    vtlGesturalScoreToTractSequence = [
        'Success.',
        'The API was not initialized.',
        'Loading the gestural score file failed.',
        'Values in the gestural score file are out of range.',
        'The tract sequence file could not be saved.',
    ],
    vtlGetGesturalScoreDuration = [
        'Success.',
        'The API was not initialized.',
        'Loading the gestural score file failed.',
        'Values in the gestural score file are out of range.',
    ],
    vtlTractSequenceToAudio = [
        'Success.',
        'The API was not initialized.',
        'Synthesis of the tract sequence file failed.',
        'The WAV file could not be saved.',
    ],
    vtlGesturalScoreToEma = [
        'Success.',
        'The API was not initialized.',
        'Loading the gestural score file failed.',
        'Values in the gestural score files are out of range.',
    ],
    vtlGesturalScoreToEmaAndMesh = [
        'Success.',
        'The API was not initialized.',
        'Loading the gestural score file failed.',
        'Values in the gestural score files are out of range.',
    ],
    vtlTractSequenceToEmaAndMesh = [
        'Success.',
        'numEmaPoints <= 0',
        'surf == NULL',
        'vert == NULL',
        'surface index of a selected EmaPoints exceeds 30',
        'vertex index of a selected EmaPoint exceeds possible range',
        'filePath is not valid',
        'mesh folder already exist: prevents overwriting',
        'EMA file already exists: prevents overwriting',
        'EMA file could not be opened',
        'The API was not initialized.',
    ],
    vtlSaveSpeaker = [
        'Success.',
        'Saving the speaker file failed.',
    ],
)



class VtlApiError( ValueError ):
    """Error codes returned from the VTL API."""



def get_api_exception(
        function_name,
        return_value,
        function_args = None,
        ):
    if function_name not in api_exceptions.keys():
        raise ValueError(
            f"""
            An error occurred while handling an API exception
            with function name {function_name} and return value
            {return_value}.
            The function name was not found in exceptions.
            Make sure the vtl_cython version is in sync
            with the used VTL API version.
            """
            )
    try:
        api_exception = api_exceptions[function_name][return_value]
    except IndexError:
        raise ValueError(
            f"""
            An error occurred while handling an API exception
            with function name {function_name} and return value
            {return_value}.
            The return value was not found in exceptions.
            Make sure the vtl_cython version is in sync
            with the used VTL API version.
            """
            )
    error_message = f"""
        The VTL API function {function_name} returned the error code
        {return_value} which probably means: {api_exception}. Please
        check the API documention or backend source code for details.
        """
    if function_args is not None:
        error_message += f"""
            The function arguments were: {function_args}.
            """
    return error_message