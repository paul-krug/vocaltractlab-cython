# distutils: language=c++



#path must be relative to setup.py

import os
import atexit
import logging as log
import warnings
import numpy as np
import pandas as pd

#from .cVocalTractLabApi cimport vtlCalcTongueRootAutomatically

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
from .cVocalTractLabApi cimport vtlSynthesisReset
from .cVocalTractLabApi cimport vtlSynthesisAddTube
from .cVocalTractLabApi cimport vtlSynthesisAddTract
from .cVocalTractLabApi cimport vtlSynthBlock
from .cVocalTractLabApi cimport vtlApiTest
from .cVocalTractLabApi cimport vtlSegmentSequenceToGesturalScore
from .cVocalTractLabApi cimport vtlGesturalScoreToAudio
from .cVocalTractLabApi cimport vtlGesturalScoreToTractSequence
from .cVocalTractLabApi cimport vtlGetGesturalScoreDuration
from .cVocalTractLabApi cimport vtlTractSequenceToAudio
from .cVocalTractLabApi cimport vtlGesturalScoreToEma
from .cVocalTractLabApi cimport vtlGesturalScoreToEmaAndMesh
from .cVocalTractLabApi cimport vtlTractSequenceToEmaAndMesh
from .cVocalTractLabApi cimport vtlSaveSpeaker

from .exceptions import VtlApiError
from .exceptions import get_api_exception


def _initialize( speaker_file_path: str ):
	cSpeakerFileName = speaker_file_path.encode()
	value = vtlInitialize( cSpeakerFileName )
	if value != 0:
		raise VtlApiError(
			get_api_exception(
				function_name = 'vtlInitialize',
				return_value = value,
				)
			)
	log.info( 'VTL API initialized.' )
	return

def _close():
	value = vtlClose()
	if value != 0:
		raise VtlApiError(
			get_api_exception(
				function_name = 'vtlClose',
				return_value = value,
				)
			)
	log.info( 'VTL API closed.' )
	return

def calculate_tongueroot_automatically( automatic_calculation: bool ):
	cdef bool automaticCalculation = automatic_calculation
	value = vtlCalcTongueRootAutomatically( automaticCalculation )
	if value != 0:
		raise VtlApiError(
			get_api_exception(
				function_name = 'vtlCalcTongueRootAutomatically',
				return_value = value,
				)
			)
	warnings.warn( f'Automatic calculation of the Tongue Root parameters was set to {automatic_calculation}.' )
	return

def check_file_path( file_path: str ):
	if not os.path.isfile( file_path ):
		raise FileNotFoundError( f'File not found: {file_path}' )
	# Check if path contains special characters
	if not file_path.isascii():
		raise ValueError(
			f'File path contains non-ascii characters: {file_path}'
			)
	return

def format_cstring( cString ):
	x = cString.decode()
	x = x.replace('\x00', '')
	x = x.strip(' ')
	x = x.strip('')
	x = x.split('\t')
	return x

def gestural_score_to_audio(
		ges_file_path: str,
		audio_file_path: str = None,
		verbose_api: bool = False,
 		):
	check_file_path( ges_file_path )

	if audio_file_path is None:
		audio_file_path = ''
	cGesFileName = ges_file_path.encode()
	cWavFileName = audio_file_path.encode()

	duration = get_gestural_score_duration( ges_file_path )
	cdef np.ndarray[ np.float64_t, ndim=1 ] cAudio = np.zeros(
		duration[ 'n_audio_samples' ],
		dtype='float64',
		)
	cdef bool cEnableConsoleOutput = verbose_api
	cdef int cNumS = 0
	value = vtlGesturalScoreToAudio(
		cGesFileName,
		cWavFileName,
		&cAudio[0],
		&cNumS,
		cEnableConsoleOutput,
		)
	#time_synth_end = time.time()
	#print( 'elapsed synthesis time {}'.format( time_synth_end-time_synth_start ) )
	if value != 0:
		raise ValueError('VTL API function vtlGesturalScoreToAudio returned the Errorcode: {}  (See API doc for info.) \
			while processing gestural score file (input): {}, audio file (output): {}'.format(value, ges_file_path, audio_file_path) )

	audio = np.array( cAudio )

	log.info( 'Audio generated from gestural score file: {}'.format( ges_file_path ) )
	return audio

def gestural_score_to_tract_sequence(
		ges_file_path: str,
		tract_file_path: str,
		):
	check_file_path( ges_file_path )
	# Make the directory of the tract file if it does not exist
	os.makedirs( os.path.dirname( tract_file_path ), exist_ok=True )

	cGesFileName = ges_file_path.encode()
	cTractSequenceFileName = tract_file_path.encode()
	value = vtlGesturalScoreToTractSequence(
		cGesFileName,
		cTractSequenceFileName,
		)
	if value != 0:
		raise ValueError('VTL API function vtlGesturalScoreToTractSequence returned the Errorcode: {}  (See API doc for info.) \
			while processing gestural score file (input): {}, tract sequence file (output): {}'.format(value, ges_file_path, tract_file_path) )
	log.info( f'Created tract sequence file {tract_file_path} from gestural score file: {ges_file_path}' )
	return

def get_constants():
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

def get_gestural_score_duration(
		ges_file_path: str,
		return_samples: bool = True,
		):
	cGesFileName = ges_file_path.encode()
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
	results = dict(
		n_audio_samples = int( cNumAudioSamples ),
		n_gesture_samples = int( cNumGestureSamples ),
	)
	#if return_samples: # returning number of audio samples
	#	return n_samples
	#else: # returning time in seconds
	#	return n_samples / self.params.samplerate_audio
	return results

def get_param_info( params ):
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
	elif params == 'glottis':
		vtlGetParamInfo = vtlGetGlottisParamInfo
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
				function_name = vtlGetParamInfo.__name__,
				return_value = value,
				)
			)
	#descriptions = descriptions.decode().replace('\x00', '').strip(' ').strip('').split('\t')
	#units = units.decode().replace('\x00', '').strip(' ').strip( '' ).split('\t')
	descriptions = format_cstring( cDescriptions )
	units = format_cstring( cUnits )
	df = pd.DataFrame(
		np.array( [
			descriptions,
			units,
			cParamMin,
			cParamMax,
			cParamStandard,
			] ).T,
		columns = [
			'description',
			'unit',
			'min',
			'max',
			'standard',
			]
		)
	df.index = format_cstring( cNames )
	return df

def get_version():
	'''
	A function to get the internal VTL-backend version string.

	Parameters
	----------

	Returns
	-------
	version: str
		String that contains the VTL-backend version and compile date.

	'''
	cdef char cVersion[32]
	vtlGetVersion( cVersion )
	version = cVersion.decode()
	log.info( f'Compile date of the library: {version}' )
	return version

def segment_sequence_to_gestural_score(
		seg_file_path: str,
		ges_file_path: str,
		verbose_api: bool = False,
		):
	check_file_path( seg_file_path )
	# Make the directory of the gestural score file if it does not exist
	os.makedirs( os.path.dirname( ges_file_path ), exist_ok=True )
	
	cSegFileName = seg_file_path.encode()
	cGesFileName = ges_file_path.encode()
	cdef bool cEnableConsoleOutput = verbose_api
	value = vtlSegmentSequenceToGesturalScore(
		cSegFileName,
		cGesFileName,
		cEnableConsoleOutput,
		)
	if value != 0:
		raise ValueError('VTL API function vtlSegmentSequenceToGesturalScore returned the Errorcode: {}  (See API doc for info.) \
			while processing segment sequence file (input): {}, gestural score file (output): {}'.format(value, seg_file_path, ges_file_path) )
	log.info( f'Created gestural score from segment sequence file: {seg_file_path}' )
	return

def _synth_block(
		tract_parameters: np.ndarray,
		glottis_parameters: np.ndarray,
		state_samples: int = None,
		verbose_api: bool = False,
		):
	n_frames = tract_parameters.shape[0]
	cdef int cNumFrames = n_frames
	cdef np.ndarray[ np.float64_t, ndim=1 ] cTractParams = tract_parameters.ravel()
	cdef np.ndarray[ np.float64_t, ndim=1 ] cGlottisParams = glottis_parameters.ravel()
	cdef int cFrameStep_samples = state_samples
	cdef np.ndarray[ np.float64_t, ndim=1 ] cAudio = np.zeros(
		n_frames * state_samples,
		dtype='float64',
		)
	cdef bool cEnableConsoleOutput = verbose_api
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
		):
	vtl_constants = get_constants()
	# Input arrays are 2D
	if tract_parameters.ndim != 2:
		raise ValueError( 'Tract parameters must be a 2D array.' )
	if glottis_parameters.ndim != 2:
		raise ValueError( 'Glottis parameters must be a 2D array.' )
	# Check if the number of time steps is equal
	if tract_parameters.shape[0] != glottis_parameters.shape[0]:
		raise ValueError( 'Number of rows in tract and glottis parameters must be equal.' )
	# Check if the number of tract parameters is correct
	if tract_parameters.shape[1] != vtl_constants[ 'n_tract_params' ]:
		raise ValueError( 'Number of columns in tract parameters must be equal to the number of tract parameters.' )
	# Check if the number of glottis parameters is correct
	if glottis_parameters.shape[1] != vtl_constants[ 'n_glottis_params' ]:
		raise ValueError( 'Number of columns in glottis parameters must be equal to the number of glottis parameters.' )

	audio = _synth_block(
		tract_parameters,
		glottis_parameters,
		state_samples,
		verbose_api,
		)
	return audio

def tract_sequence_to_audio(
		tract_file_path: str,
		audio_file_path: str,
		):
	check_file_path( tract_file_path )
	# Make the directory of the audio file if it does not exist
	os.makedirs( os.path.dirname( audio_file_path ), exist_ok=True )

	#if audio_file_path is None:
	#	audio_file_path = ''
	cTractSequenceFileName = tract_file_path.encode()
	cWavFileName = audio_file_path.encode()
	cdef int cAudio = NULL
	cdef int cNumS = NULL
	value = vtlTractSequenceToAudio(
		cTractSequenceFileName,
		cWavFileName,
		&cAudio,
		&cNumS,
		)
	if value != 0:
		raise ValueError('VTL API function vtlTractSequenceToAudio returned the Errorcode: {}  (See API doc for info.) \
			while processing tract sequence file (input): {}, audio file (output): {}'.format(value, tract_file_path, audio_file_path) )
	log.info( f'Audio generated from tract sequence file: {tract_file_path}' )
	return

def tract_state_to_limited_tract_state( tract_state: np.ndarray ):
	vtl_constants = get_constants()
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
				)
			)
	limited_state = np.array( cOutTractParams )
	return limited_state

def tract_state_to_svg(
		tract_state: np.ndarray,
		svg_path: str = None,
		):
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
	os.makedirs( os.path.dirname( svg_path ), exist_ok=True )
	
	vtl_constants = get_constants()
	cdef np.ndarray[np.float64_t, ndim = 1] tractParams = np.zeros(
		vtl_constants['n_tract_params'],
		dtype = 'float64'
		)

	cTractParams = tract_state.ravel()
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
				)
			)
	return

#def _supra_glottal_state_to_svg_str( args ):
#	supra_glottal_state = args
#	svgStr = ( ' ' * 10000 ).encode()
#	constants = get_constants()
#	cdef np.ndarray[np.float64_t, ndim = 1] tractParams = np.zeros(
#		constants['n_tract_params'],
#		dtype = 'float64',
#		)
#	tractParams = supra_glottal_state.ravel()
#	vtlExportTractSvgToStr(
#		&tractParams[0],
#		svgStr,
#		)
#	return svgStr.decode()

def tract_state_to_transfer_function(
		tract_state,
		n_spectrum_samples: int = 8192,
		save_magnitude_spectrum: bool = True,
		save_phase_spectrum: bool = True,
		):
	magnitude_spectrum = None
	phase_spectrum = None
	cdef int cNumSpectrumSamples = n_spectrum_samples
	cdef int cOpts = NULL
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
		):
	tube_length = None
	tube_area = None
	tube_articulator = None
	incisor_position = None
	tongue_tip_side_elevation = None
	velum_opening = None

	vtl_constants = get_constants()
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
	else:
		vtlCalcTube = vtlTractToTube
		
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
				function_name = vtlCalcTube.__name__,
				return_value = value,
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

def tract_state_to_ema_and_mesh(
		tract_state: np.ndarray,
		ema_file_path: str = None,
		mesh_file_path: str = None,
		):
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
	# Make the directory of the ema file if it does not exist
	os.makedirs( os.path.dirname( ema_file_path ), exist_ok=True )
	# Make the directory of the mesh file if it does not exist
	os.makedirs( os.path.dirname( mesh_file_path ), exist_ok=True )

	cTractParams = tract_state.ravel()
	cEmaFileName = ema_file_path.encode()
	cMeshFileName = mesh_file_path.encode()
	value = vtlGesturalScoreToEmaAndMesh(
		&cTractParams[0],
		cEmaFileName,
		cMeshFileName,
		)
	if value != 0:
		raise VtlApiError(
			get_api_exception(
				function_name = 'vtlGesturalScoreToEmaAndMesh',
				return_value = value,
				)
			)
	return

	

# Function to be called at module exit
atexit.register( _close )

# Function to be called at module import
_initialize(
	os.path.join(
		os.path.dirname(__file__),
		'speaker',
		'JD3.speaker'
		)
	)