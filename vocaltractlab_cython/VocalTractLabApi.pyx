# distutils: language = c++
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/VocalTractLabApi.cpp

# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/AnatomyParams.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/Dsp.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/F0EstimatorYin.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/GeometricGlottis.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/Geometry.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/GesturalScore.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/Glottis.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/IirFilter.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/ImpulseExcitation.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/LfPulse.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/Matrix2x2.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/PoleZeroPlan.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/Sampa.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/SegmentSequence.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/StaticPhone.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/Surface.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/Synthesizer.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/TdsModel.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/TimeFunction.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/TlModel.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/TriangularGlottis.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/Tube.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/TwoMassModel.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/VocalTract.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/VocalTractLabApi.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/VoiceQualityEstimator.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/VowelLf.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/XmlHelper.cpp 
# distutils: sources = vocaltractlab_cython/src/vocaltractlab-backend/XmlNode.cpp 

#
#'vocaltractlab_cython/src/vocaltractlab-backend/AnatomyParams.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/Dsp.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/F0EstimatorYin.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/GeometricGlottis.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/Geometry.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/GesturalScore.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/Glottis.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/IirFilter.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/ImpulseExcitation.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/LfPulse.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/Matrix2x2.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/PoleZeroPlan.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/Sampa.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/SegmentSequence.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/StaticPhone.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/Surface.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/Synthesizer.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/TdsModel.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/TimeFunction.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/TlModel.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/TriangularGlottis.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/Tube.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/TwoMassModel.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/VocalTract.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/VocalTractLabApi.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/VoiceQualityEstimator.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/VowelLf.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/XmlHelper.cpp',
#'vocaltractlab_cython/src/vocaltractlab-backend/XmlNode.cpp',



#path must be relative to setup.py

import os
import atexit
import logging as log

from . cimport cVocalTractLabApi # Function defs could be placed here



def _initialize( str speaker_file_path ):
	speakerFileName = speaker_file_path.encode()
	value = cVocalTractLabApi.vtlInitialize( speakerFileName )
	if value != 0:
		raise ValueError(
			f'VTL API function vtlInitialize returned the Errorcode: {value}  (See API doc for info.)' )
	log.info( 'VTL API initialized.' )
	return

def _close():
	value = cVocalTractLabApi.vtlClose()
	if value != 0:
		raise ValueError(
			f'VTL API function vtlClose returned the Errorcode: {value}  (See API doc for info.)' )
	log.info( 'VTL API closed.' )
	return

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
	cVocalTractLabApi.vtlGetVersion( cVersion )
	version = cVersion.decode()
	log.info( f'Compile date of the library: {version}' )
	return version



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